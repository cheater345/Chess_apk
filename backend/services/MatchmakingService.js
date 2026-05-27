const { getDb } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

const QUEUES = {
  bullet: { maxRatingDiff: 200, poolSize: 0, players: [] },
  blitz: { maxRatingDiff: 150, poolSize: 0, players: [] },
  rapid: { maxRatingDiff: 100, poolSize: 0, players: [] },
  classical: { maxRatingDiff: 100, poolSize: 0, players: [] },
};

class MatchmakingService {
  constructor(io) {
    this.io = io;
    this.queues = {
      bullet: [],
      blitz: [],
      rapid: [],
      classical: [],
    };
  }

  addToQueue(socketId, playerData) {
    const { uid, username, elo, timeControl, isRated } = playerData;
    const queue = this.queues[timeControl];
    if (!queue) return null;

    const existingIndex = queue.findIndex((p) => p.uid === uid);
    if (existingIndex !== -1) {
      queue[existingIndex].socketId = socketId;
      return queue[existingIndex];
    }

    const player = {
      socketId,
      uid,
      username,
      elo: elo[timeControl] || 1200,
      timeControl,
      isRated: isRated !== false,
      joinedAt: Date.now(),
      ratingDeviation: Math.max(50, 200 - (elo[timeControl] || 1200) / 20),
    };

    queue.push(player);
    return player;
  }

  removeFromQueue(uid, timeControl) {
    if (timeControl) {
      this.queues[timeControl] = this.queues[timeControl].filter((p) => p.uid !== uid);
    } else {
      Object.keys(this.queues).forEach((tc) => {
        this.queues[tc] = this.queues[tc].filter((p) => p.uid !== uid);
      });
    }
  }

  findMatch(timeControl) {
    const queue = this.queues[timeControl];
    if (queue.length < 2) return null;

    queue.sort((a, b) => a.joinedAt - b.joinedAt);

    for (let i = 0; i < queue.length; i++) {
      for (let j = i + 1; j < queue.length; j++) {
        const p1 = queue[i];
        const p2 = queue[j];
        const adjustedRD = Math.min(p1.ratingDeviation, p2.ratingDeviation);
        const maxDiff = Math.max(100, 300 - adjustedRD * 2);
        const ratingDiff = Math.abs(p1.elo - p2.elo);

        if (ratingDiff <= maxDiff) {
          this.removeFromQueue(p1.uid, timeControl);
          this.removeFromQueue(p2.uid, timeControl);
          return { player1: p1, player2: p2 };
        }
      }
    }

    return null;
  }

  getQueueSize(timeControl) {
    return this.queues[timeControl]?.length || 0;
  }

  getAllQueueSizes() {
    const sizes = {};
    Object.keys(this.queues).forEach((tc) => {
      sizes[tc] = this.queues[tc].length;
    });
    return sizes;
  }

  getPlayerQueue(uid) {
    for (const [tc, queue] of Object.entries(this.queues)) {
      const player = queue.find((p) => p.uid === uid);
      if (player) return { timeControl: tc, ...player };
    }
    return null;
  }

  async createGame(match) {
    const { player1, player2 } = match;
    const gameId = uuidv4().slice(0, 12);

    const timeConfigs = {
      bullet: { initial: 60, increment: 0 },
      blitz: { initial: 300, increment: 3 },
      rapid: { initial: 600, increment: 5 },
      classical: { initial: 1800, increment: 10 },
    };

    const config = timeConfigs[player1.timeControl] || timeConfigs.rapid;
    const colors = Math.random() < 0.5
      ? { white: player1, black: player2 }
      : { white: player2, black: player1 };

    const db = getDb();
    const gameData = {
      gameId,
      players: {
        white: {
          uid: colors.white.uid,
          username: colors.white.username,
          elo: colors.white.elo,
          clock: config.initial,
          disconnected: false,
        },
        black: {
          uid: colors.black.uid,
          username: colors.black.username,
          elo: colors.black.elo,
          clock: config.initial,
          disconnected: false,
        },
      },
      timeControl: player1.timeControl,
      initialTime: config.initial,
      increment: config.increment,
      status: 'active',
      result: null,
      winner: null,
      moves: [],
      moveHistory: [],
      pgn: '',
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      currentTurn: 'w',
      isRated: player1.isRated,
      startTime: new Date().toISOString(),
      lastMoveTime: new Date().toISOString(),
      moveCount: 0,
      isTournament: false,
    };

    await db.collection('games').doc(gameId).set(gameData);

    return {
      gameId,
      gameData,
      whiteSocket: colors.white.socketId,
      blackSocket: colors.black.socketId,
    };
  }
}

module.exports = MatchmakingService;
