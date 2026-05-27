require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { initFirebase } = require('./config/firebase');

const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const gameRoutes = require('./routes/game');
const puzzleRoutes = require('./routes/puzzle');
const tournamentRoutes = require('./routes/tournament');
const leaderboardRoutes = require('./routes/leaderboard');
const chatRoutes = require('./routes/chat');
const adminRoutes = require('./routes/admin');

const setupSocketHandlers = require('./socket');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  pingTimeout: 60000,
  pingInterval: 25000,
});

initFirebase();

app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors());
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/games', gameRoutes);
app.use('/api/puzzles', puzzleRoutes);
app.use('/api/tournaments', tournamentRoutes);
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/admin', adminRoutes);

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    playersOnline: io.engine?.clientsCount || 0,
  });
});

app.get('/api/status', (req, res) => {
  const rooms = io.sockets.adapter.rooms;
  const activeGames = [];
  rooms.forEach((clients, room) => {
    if (room.startsWith('game:')) {
      activeGames.push({
        room: room.replace('game:', ''),
        players: clients.size,
      });
    }
  });

  res.json({
    uptime: process.uptime(),
    connectedClients: io.engine?.clientsCount || 0,
    activeRooms: rooms?.size || 0,
    activeGames,
  });
});

const matchmakingService = new (require('./services/MatchmakingService'))(io);

setupSocketHandlers(io, matchmakingService);

setInterval(() => {
  const sizes = matchmakingService.getAllQueueSizes();
  io.emit('queue:sizes', sizes);
}, 5000);

setInterval(() => {
  ['bullet', 'blitz', 'rapid', 'classical'].forEach((tc) => {
    const match = matchmakingService.findMatch(tc);
    if (match) {
      matchmakingService.createGame(match).then((result) => {
        io.to(result.whiteSocket).emit('match:found', {
          gameId: result.gameId,
          color: 'white',
          opponent: {
            username: result.gameData.players.black.username,
            elo: result.gameData.players.black.elo,
          },
          timeControl: result.gameData.timeControl,
        });

        io.to(result.blackSocket).emit('match:found', {
          gameId: result.gameId,
          color: 'black',
          opponent: {
            username: result.gameData.players.white.username,
            elo: result.gameData.players.white.elo,
          },
          timeControl: result.gameData.timeControl,
        });

        io.to(result.whiteSocket).emit('redirect:game', { gameId: result.gameId });
        io.to(result.blackSocket).emit('redirect:game', { gameId: result.gameId });
      });
    }
  });
}, 2000);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`OpenChess Arena server running on port ${PORT}`);
  console.log(`WebSocket server ready for connections`);
});
