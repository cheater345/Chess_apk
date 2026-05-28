const { Game, GAME_RESULT } = require('../models/Game');
const { getDb, admin } = require('../config/firebase');
const User = require('../models/User');
const EloService = require('../services/EloService');
const ChessEngine = require('../services/ChessEngine');
const Chess = require('chess.js');
const { v4: uuidv4 } = require('uuid');

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
    socket.on('game:create-ai', (data) => handler.createAIGame(data));
  }

  async joinGame(data) {
    const { gameId, uid } = data;
    this.socket.join(`game:${gameId}`);

    let game = activeGames.get(gameId);
    if (!game) {
      const dbGame = await Game.getGame(gameId);
      if (!dbGame) {
        this.socket.emit('error', { message: 'Game not found' });
        return;
      }
      game = {
        ...dbGame,
        clocks: { white: dbGame.initialTime, black: dbGame.initialTime },
        lastTick: Date.now(),
      };
      activeGames.set(gameId, game);
    }

    const state = activeGames.get(gameId);
    if (!state.clocks) {
      state.clocks = { white: state.players.white.clock, black: state.players.black.clock };
    }
    this.socket.emit('game:state', state);
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

    const chess = new Chess.Chess(game.fen);
    let san;
    try {
      san = promotion
        ? chess.move({ from, to, promotion: promotion.toLowerCase() })
        : chess.move({ from, to });
    } catch (e) {
      this.socket.emit('error', { message: 'Illegal move' });
      return;
    }

    if (!san) {
      this.socket.emit('error', { message: 'Illegal move' });
      return;
    }

    game.moves.push({ from, to, promotion, notation: san.san, by: uid, time: moveTime || 0 });
    game.moveCount++;
    game.currentTurn = color === 'w' ? 'b' : 'w';
    game.lastMoveTime = new Date().toISOString();
    game.fen = chess.fen();
    game.moveHistory.push(san.san);

    if (isWhite) {
      game.players.white.clock = Math.max(0, game.players.white.clock - (moveTime || 0) / 1000);
      game.players.white.clock += game.increment;
    } else {
      game.players.black.clock = Math.max(0, game.players.black.clock - (moveTime || 0) / 1000);
      game.players.black.clock += game.increment;
    }

    const isCheckmate = chess.isCheckmate();
    const isCheck = chess.isCheck();
    const isStalemate = chess.isStalemate();
    const isDraw = chess.isDraw();

    const moveDetails = {
      from, to, promotion,
      piece: san.piece,
      captured: san.captured || null,
      moveNumber: Math.ceil(game.moveCount / 2),
    };

    this.io.to(`game:${gameId}`).emit('game:move', {
      move: san.san,
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

    if (isCheckmate || isStalemate || isDraw) {
      const winner = isCheckmate ? (color === 'w' ? 'white' : 'black') : null;
      const reason = isCheckmate ? 'checkmate' : isStalemate ? 'stalemate' : 'draw';
      const result = Game.getGameResult(winner, reason);
      await this.endGame(gameId, result, winner, reason);
      return;
    }

    activeGames.set(gameId, game);

    if (game.isBot) {
      setTimeout(() => this._triggerAIBotMove(this.io, gameId), 500);
    }
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

  async createAIGame(data) {
    const { uid, username, difficulty, playerColor } = data;
    const gameId = uuidv4();
    const botColor = playerColor === 'white' ? 'b' : 'w';
    const botName = ['Bot_Easy','Bot_Easy','Bot_Medium','Bot_Hard','Bot_Expert','Bot_GM'][difficulty || 3] || 'Bot_Medium';
    const botElo = [800, 1100, 1500, 1900, 2200, 2600][difficulty || 3] || 1500;

    const isHumanWhite = playerColor === 'white';
    const players = {
      white: isHumanWhite
        ? { uid, username, elo: 1200, clock: 600, disconnected: false, moveTimes: [] }
        : { uid: `bot_${gameId}`, username: botName, elo: botElo, clock: 600, disconnected: false, moveTimes: [] },
      black: !isHumanWhite
        ? { uid, username, elo: 1200, clock: 600, disconnected: false, moveTimes: [] }
        : { uid: `bot_${gameId}`, username: botName, elo: botElo, clock: 600, disconnected: false, moveTimes: [] },
    };

    const game = {
      gameId,
      id: gameId,
      players,
      timeControl: 'rapid',
      initialTime: 600,
      increment: 5,
      status: 'active',
      result: null,
      winner: null,
      winReason: null,
      moves: [],
      moveHistory: [],
      pgn: '',
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      currentTurn: 'w',
      isRated: false,
      isTournament: false,
      tournamentId: null,
      isPrivate: false,
      inviteCode: null,
      isBot: true,
      botLevel: difficulty || 3,
      botColor,
      startTime: new Date().toISOString(),
      endTime: null,
      lastMoveTime: new Date().toISOString(),
      moveCount: 0,
      spectators: [],
      chat: [],
      analysis: null,
      movedAt: {},
      clocks: { white: 600, black: 600 },
      lastTick: Date.now(),
    };

    activeGames.set(gameId, game);
    this.socket.emit('game:created', { gameId, playerColor });
  }

  async _triggerAIBotMove(io, gameId) {
    const game = activeGames.get(gameId);
    if (!game || !game.isBot) { console.log(`[AI] no game or not bot ${gameId}`); return; }

    const chess = new Chess.Chess(game.fen);
    if (chess.isGameOver()) { console.log(`[AI] game over ${gameId}`); return; }

    const botColor = game.botColor;
    if (game.currentTurn !== botColor) { console.log(`[AI] not bot turn ${game.currentTurn} vs ${botColor}`); return; }

    console.log(`[AI] computing move for ${gameId} fen=${game.fen} color=${botColor} level=${game.botLevel}`);
    const best = ChessEngine.getBestMove(game.fen, botColor, game.botLevel);
    console.log(`[AI] best move: ${JSON.stringify(best)}`);
    if (!best) { console.log(`[AI] no best move`); return; }

    const from = best.from;
    const to = best.to;
    const promotion = best.promotion || null;

    game.moves.push({
      from, to, promotion,
      notation: best.san,
      by: `bot_${gameId}`,
      time: 500,
    });
    game.moveCount++;
    game.currentTurn = botColor === 'w' ? 'b' : 'w';
    game.moveHistory.push(best.san);

    const fen = chess.fen();
    const isCheckmate = chess.isCheckmate();
    const isCheck = chess.isCheck();
    const isStalemate = chess.isStalemate();
    const isDraw = chess.isDraw();

    io.to(`game:${gameId}`).emit('game:move', {
      move: best.san,
      moveDetails: { from, to, promotion, piece: best.piece, captured: best.captured, moveNumber: Math.ceil(game.moveCount / 2) },
      fen,
      currentTurn: game.currentTurn,
      clock: { white: game.players.white.clock, black: game.players.black.clock, increment: game.increment },
      moveCount: game.moveCount,
    });

    if (isCheckmate || isStalemate || isDraw) {
      const winner = isCheckmate ? (botColor === 'w' ? 'black' : 'white') : null;
      const reason = isCheckmate ? 'checkmate' : isStalemate ? 'stalemate' : 'draw';
      const result = Game.getGameResult(winner, reason);
      await this.endGame(gameId, result, winner, reason);
      return;
    }

    activeGames.set(gameId, game);
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

    if (!game.isBot) {
      const db = getDb();
      await db.collection('games').doc(gameId).update(gameData);
    }

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
