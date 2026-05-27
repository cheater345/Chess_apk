const { Game, GAME_RESULT } = require('../models/Game');
const { getDb, admin } = require('../config/firebase');
const User = require('../models/User');
const EloService = require('../services/EloService');
const ChessEngine = require('../services/ChessEngine');

const activeGames = new Map();
const activeTimers = new Map();

class GameHandler {
  constructor(io, socket, connectedUsers) {
    this.io = io;
    this.socket = socket;
    this.connectedUsers = connectedUsers;
  }

  static setup(io, socket, connectedUsers) {
    const handler = new GameHandler(io, socket, connectedUsers);

    socket.on('game:join', (data) => handler.joinGame(data));
    socket.on('game:move', (data) => handler.makeMove(data));
    socket.on('game:resign', (data) => handler.resign(data));
    socket.on('game:draw', (data) => handler.drawOffer(data));
    socket.on('game:draw:response', (data) => handler.drawResponse(data));
    socket.on('game:rematch', (data) => handler.rematch(data));
    socket.on('game:abort', (data) => handler.abortGame(data));
    socket.on('game:sync', (data) => handler.syncGame(data));
    socket.on('game:clock', (data) => handler.syncClock(data));
  }

  async joinGame(data) {
    const { gameId, uid } = data;
    this.socket.join(`game:${gameId}`);

    const game = await Game.getGame(gameId);
    if (!game) {
      this.socket.emit('error', { message: 'Game not found' });
      return;
    }

    if (!activeGames.has(gameId)) {
      activeGames.set(gameId, {
        ...game,
        clocks: {
          white: game.initialTime,
          black: game.initialTime,
        },
        lastTick: Date.now(),
      });
    }

    this.socket.emit('game:state', activeGames.get(gameId));
    this.socket.to(`game:${gameId}`).emit('player:joined', { uid, username: game.players.white.uid === uid ? game.players.white.username : game.players.black.username });
  }

  async makeMove(data) {
    const { gameId, uid, from, to, promotion, moveTime } = data;
    const game = activeGames.get(gameId);
    if (!game) {
      this.socket.emit('error', { message: 'Game not found' });
      return;
    }

    const isWhite = game.players.white.uid === uid;
    const color = isWhite ? 'w' : 'b';
    if (game.currentTurn !== color) {
      this.socket.emit('error', { message: 'Not your turn' });
      return;
    }

    const moveNotation = `${from}-${to}${promotion ? `=${promotion.toUpperCase()}` : ''}`;
    game.moves.push({ from, to, promotion, notation: moveNotation, by: uid, time: moveTime || 0 });
    game.moveCount++;
    game.currentTurn = color === 'w' ? 'b' : 'w';
    game.lastMoveTime = new Date().toISOString();

    if (isWhite) {
      game.players.white.clock = Math.max(0, game.players.white.clock - (moveTime || 0) / 1000);
      game.players.white.clock += game.increment;
    } else {
      game.players.black.clock = Math.max(0, game.players.black.clock - (moveTime || 0) / 1000);
      game.players.black.clock += game.increment;
    }

    const moveNotationSimple = moveNotation.replace(/[^a-h1-8]/g, '');
    const lastMoves = game.moveHistory.slice(-4);
    const moveDetails = {
      from, to, promotion,
      piece: 'p',
      captured: null,
      moveNumber: Math.ceil(game.moveCount / 2),
    };

    if (game.moveHistory.length > 0) {
      const lastMove = game.moveHistory[game.moveHistory.length - 1].toLowerCase();
      const targetSquare = to.toLowerCase();
      const lastTarget = lastMove.replace(/[^a-h1-8]/g, '').slice(-2);
      if (targetSquare === lastTarget) {
        moveDetails.captured = 'p';
      }
    }

    game.moveHistory.push(moveNotation);

    this.io.to(`game:${gameId}`).emit('game:move', {
      move: moveNotation,
      moveDetails,
      fen: game.fen,
      currentTurn: game.currentTurn,
      clock: {
        white: game.players.white.clock,
        black: game.players.black.clock,
        increment: game.increment,
      },
      moveCount: game.moveCount,
    });

    activeGames.set(gameId, game);
  }

  async resign(data) {
    const { gameId, uid } = data;
    const game = activeGames.get(gameId);
    if (!game) return;

    const isWhite = game.players.white.uid === uid;
    const winner = isWhite ? 'black' : 'white';
    const result = Game.getGameResult(winner, 'resignation');

    await this.endGame(gameId, result, winner, 'resignation');
  }

  async drawOffer(data) {
    const { gameId, uid } = data;
    this.socket.to(`game:${gameId}`).emit('game:draw:offer', { uid });
  }

  async drawResponse(data) {
    const { gameId, uid, accepted } = data;
    if (accepted) {
      const result = Game.getGameResult(null, 'agreement');
      await this.endGame(gameId, result, null, 'agreement');
    } else {
      this.socket.to(`game:${gameId}`).emit('game:draw:declined', { uid });
    }
  }

  async abortGame(data) {
    const { gameId, uid } = data;
    const game = activeGames.get(gameId);
    if (!game) return;

    if (game.moveCount <= 2) {
      const result = { result: 'abandoned', winner: null, reason: 'aborted' };
      await this.endGame(gameId, result, null, 'aborted');
    }
  }

  async rematch(data) {
    const { gameId, uid } = data;
    this.socket.to(`game:${gameId}`).emit('game:rematch:request', { uid });
  }

  async syncGame(data) {
    const { gameId } = data;
    const game = activeGames.get(gameId);
    if (game) {
      this.socket.emit('game:state', game);
    }
  }

  async syncClock(data) {
    const { gameId } = data;
    const game = activeGames.get(gameId);
    if (game) {
      this.socket.emit('game:clock', {
        white: game.players.white.clock,
        black: game.players.black.clock,
      });
    }
  }

  async endGame(gameId, result, winner, reason) {
    const game = activeGames.get(gameId);
    if (!game) return;

    const gameData = {
      status: 'completed',
      result: result.result,
      winner,
      winReason: reason,
      endTime: new Date().toISOString(),
      pgn: game.moveHistory.join(' '),
    };

    const db = getDb();
    await db.collection('games').doc(gameId).update(gameData);

    if (game.isRated && winner) {
      const tc = game.timeControl;
      const whiteUser = await User.getUserById(game.players.white.uid);
      const blackUser = await User.getUserById(game.players.black.uid);

      if (whiteUser && blackUser) {
        const whiteElo = whiteUser.elo[tc] || 1200;
        const blackElo = blackUser.elo[tc] || 1200;
        const score = winner === 'white' ? 1 : 0;
        const eloResult = EloService.calculate(whiteElo, blackElo, score);

        await User.updateUser(game.players.white.uid, {
          [`elo.${tc}`]: eloResult.newRatingA,
          'stats.gamesPlayed': admin.firestore.FieldValue.increment(1),
          'stats.wins': admin.firestore.FieldValue.increment(winner === 'white' ? 1 : 0),
          'stats.losses': admin.firestore.FieldValue.increment(winner === 'white' ? 0 : 1),
          'lastActiveAt': new Date().toISOString(),
        });

        await User.updateUser(game.players.black.uid, {
          [`elo.${tc}`]: eloResult.newRatingB,
          'stats.gamesPlayed': admin.firestore.FieldValue.increment(1),
          'stats.wins': admin.firestore.FieldValue.increment(winner === 'black' ? 1 : 0),
          'stats.losses': admin.firestore.FieldValue.increment(winner === 'black' ? 0 : 1),
          'lastActiveAt': new Date().toISOString(),
        });

        gameData.eloChanges = {
          white: { old: whiteElo, new: eloResult.newRatingA, change: eloResult.changeA },
          black: { old: blackElo, new: eloResult.newRatingB, change: eloResult.changeB },
        };
      }
    }

    this.io.to(`game:${gameId}`).emit('game:over', {
      result: gameData.result,
      winner,
      reason,
      eloChanges: gameData.eloChanges || null,
      pgn: gameData.pgn,
      moves: game.moves,
    });

    activeGames.delete(gameId);

    setTimeout(() => {
      this.io.to(`game:${gameId}`).emit('game:cleanup');
    }, 10000);
  }

  static handleDisconnect(socket, user, io, connectedUsers) {
    activeGames.forEach((game, gameId) => {
      if (game.players.white.uid === user.uid || game.players.black.uid === user.uid) {
        const color = game.players.white.uid === user.uid ? 'white' : 'black';
        game.players[color].disconnected = true;
        activeGames.set(gameId, game);
        io.to(`game:${gameId}`).emit('player:disconnected', { uid: user.uid, color });

        setTimeout(async () => {
          const currentGame = activeGames.get(gameId);
          if (currentGame && currentGame.players[color].disconnected) {
            const winner = color === 'white' ? 'black' : 'white';
            const result = Game.getGameResult(winner, 'timeout');
            const handler = new GameHandler(io, null, connectedUsers);
            await handler.endGame(gameId, result, winner, 'timeout');
          }
        }, 60000);
      }
    });
  }

  static addSpectator(socket, gameId) {
    const game = activeGames.get(gameId);
    if (game) {
      socket.emit('game:state', game);
    }
  }
}

module.exports = GameHandler;
