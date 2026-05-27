const { getDb, admin } = require('../config/firebase');
const { GAME_TIME_CONTROLS } = require('../config/constants');

const GAMES_COLLECTION = 'games';

const GAME_RESULT = {
  WHITE_WIN: '1-0',
  BLACK_WIN: '0-1',
  DRAW: '1/2-1/2',
  ABANDONED: 'abandoned',
};

class Game {
  static async createGame(gameData) {
    const db = getDb();
    const game = {
      gameId: gameData.gameId,
      players: {
        white: {
          uid: gameData.whiteUid,
          username: gameData.whiteUsername,
          elo: gameData.whiteElo || 1200,
          clock: gameData.initialTime || 600,
          disconnected: false,
          moveTimes: [],
        },
        black: {
          uid: gameData.blackUid,
          username: gameData.blackUsername,
          elo: gameData.blackElo || 1200,
          clock: gameData.initialTime || 600,
          disconnected: false,
          moveTimes: [],
        },
      },
      timeControl: gameData.timeControl || 'rapid',
      initialTime: gameData.initialTime || 600,
      increment: gameData.increment || 5,
      status: 'active',
      result: null,
      winner: null,
      winReason: null,
      moves: [],
      moveHistory: [],
      pgn: '',
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      currentTurn: 'w',
      isRated: gameData.isRated !== undefined ? gameData.isRated : true,
      isTournament: gameData.isTournament || false,
      tournamentId: gameData.tournamentId || null,
      isPrivate: gameData.isPrivate || false,
      inviteCode: gameData.inviteCode || null,
      startTime: admin.firestore.FieldValue.serverTimestamp(),
      endTime: null,
      lastMoveTime: admin.firestore.FieldValue.serverTimestamp(),
      moveCount: 0,
      spectators: [],
      chat: [],
      analysis: null,
      movedAt: {},
    };

    await db.collection(GAMES_COLLECTION).doc(game.gameId).set(game);
    return game;
  }

  static async getGame(gameId) {
    const db = getDb();
    const doc = await db.collection(GAMES_COLLECTION).doc(gameId).get();
    if (!doc.exists) return null;
    return { id: doc.id, ...doc.data() };
  }

  static async updateGame(gameId, updates) {
    const db = getDb();
    await db.collection(GAMES_COLLECTION).doc(gameId).update(updates);
  }

  static async getActiveGames(uid) {
    const db = getDb();
    const snapshot = await db
      .collection(GAMES_COLLECTION)
      .where('status', '==', 'active')
      .where('players.white.uid', '==', uid)
      .limit(10)
      .get();

    const snapshot2 = await db
      .collection(GAMES_COLLECTION)
      .where('status', '==', 'active')
      .where('players.black.uid', '==', uid)
      .limit(10)
      .get();

    const games = [];
    snapshot.docs.forEach((doc) => games.push({ id: doc.id, ...doc.data() }));
    snapshot2.docs.forEach((doc) => {
      if (!games.find((g) => g.id === doc.id)) {
        games.push({ id: doc.id, ...doc.data() });
      }
    });

    return games;
  }

  static async getGameHistory(uid, limit = 20, offset = 0) {
    const db = getDb();
    const snapshot = await db
      .collection(GAMES_COLLECTION)
      .where('status', 'in', ['completed', 'abandoned'])
      .where('players.white.uid', '==', uid)
      .orderBy('endTime', 'desc')
      .limit(limit)
      .offset(offset)
      .get();

    const snapshot2 = await db
      .collection(GAMES_COLLECTION)
      .where('status', 'in', ['completed', 'abandoned'])
      .where('players.black.uid', '==', uid)
      .orderBy('endTime', 'desc')
      .limit(limit)
      .offset(offset)
      .get();

    const games = [];
    snapshot.docs.forEach((doc) => games.push({ id: doc.id, ...doc.data() }));
    snapshot2.docs.forEach((doc) => {
      if (!games.find((g) => g.id === doc.id)) {
        games.push({ id: doc.id, ...doc.data() });
      }
    });

    games.sort((a, b) => {
      const aTime = a.endTime?.toDate?.() || new Date(0);
      const bTime = b.endTime?.toDate?.() || new Date(0);
      return bTime - aTime;
    });

    return games.slice(0, limit);
  }

  static async getGamesByDateRange(startDate, endDate, limit = 100) {
    const db = getDb();
    const snapshot = await db
      .collection(GAMES_COLLECTION)
      .where('startTime', '>=', startDate)
      .where('startTime', '<=', endDate)
      .orderBy('startTime', 'desc')
      .limit(limit)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  static async getLiveGames(limit = 50) {
    const db = getDb();
    const snapshot = await db
      .collection(GAMES_COLLECTION)
      .where('status', '==', 'active')
      .orderBy('moveCount', 'desc')
      .limit(limit)
      .get();
    return snapshot.docs.map((doc) => ({
      id: doc.id,
      gameId: doc.data().gameId,
      players: doc.data().players,
      timeControl: doc.data().timeControl,
      moveCount: doc.data().moveCount,
      fen: doc.data().fen,
      isRated: doc.data().isRated,
      isTournament: doc.data().isTournament,
    }));
  }

  static getGameResult(winner, reason = 'checkmate') {
    if (winner === 'white') return { result: GAME_RESULT.WHITE_WIN, winner, reason };
    if (winner === 'black') return { result: GAME_RESULT.BLACK_WIN, winner, reason };
    return { result: GAME_RESULT.DRAW, winner: null, reason: reason || 'agreement' };
  }

  static calculateAccuracy(moves, centipawnLosses) {
    if (!moves || moves.length === 0) return { white: 0, black: 0 };
    const whiteMoves = moves.filter((_, i) => i % 2 === 0).length;
    const blackMoves = moves.filter((_, i) => i % 2 === 1).length;
    const whiteAccuracy = Math.max(0, Math.min(100,
      100 - ((centipawnLosses?.white || 0) / Math.max(whiteMoves, 1))
    ));
    const blackAccuracy = Math.max(0, Math.min(100,
      100 - ((centipawnLosses?.black || 0) / Math.max(blackMoves, 1))
    ));
    return { white: Math.round(whiteAccuracy), black: Math.round(blackAccuracy) };
  }
}

module.exports = { Game, GAME_RESULT, GAMES_COLLECTION };
