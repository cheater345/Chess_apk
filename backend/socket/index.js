const GameHandler = require('./gameHandler');
const ChatHandler = require('./chatHandler');
const MatchHandler = require('./matchHandler');

function setupSocketHandlers(io, matchmakingService) {
  const connectedUsers = new Map();

  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    let currentUser = null;

    socket.on('user:online', (data) => {
      currentUser = {
        uid: data.uid,
        username: data.username,
        socketId: socket.id,
      };
      connectedUsers.set(data.uid, currentUser);
      socket.join(`user:${data.uid}`);
      io.emit('user:status', { uid: data.uid, online: true });
    });

    MatchHandler(io, socket, matchmakingService, connectedUsers);
    GameHandler.setup(io, socket, connectedUsers);
    ChatHandler.setup(io, socket, connectedUsers);

    socket.on('join:room', (room) => {
      socket.join(room);
    });

    socket.on('leave:room', (room) => {
      socket.leave(room);
    });

    socket.on('spectate:game', (gameId) => {
      socket.join(`game:${gameId}:spectators`);
      GameHandler.addSpectator(socket, gameId);
    });

    socket.on('leave:spectate', (gameId) => {
      socket.leave(`game:${gameId}:spectators`);
    });

    socket.on('typing', (data) => {
      socket.to(`chat:${data.room}`).emit('user:typing', {
        username: data.username,
        uid: data.uid,
      });
    });

    socket.on('ping:server', (cb) => {
      if (typeof cb === 'function') cb({ pong: true, time: Date.now() });
    });

    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.id}`);
      if (currentUser) {
        connectedUsers.delete(currentUser.uid);
        io.emit('user:status', { uid: currentUser.uid, online: false });

        Object.keys(matchmakingService.queues || {}).forEach((tc) => {
          matchmakingService.removeFromQueue(currentUser.uid, tc);
        });

        GameHandler.handleDisconnect(socket, currentUser, io, connectedUsers);
      }
    });
  });
}

module.exports = setupSocketHandlers;
