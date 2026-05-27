const { getDb, admin } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

const TOURNAMENTS_COLLECTION = 'tournaments';
const TOURNAMENT_PLAYERS_COLLECTION = 'tournament_players';

class Tournament {
  static async createTournament(data) {
    const db = getDb();
    const tournamentId = uuidv4().slice(0, 8);
    const tournament = {
      tournamentId,
      name: data.name || `${data.timeControl?.toUpperCase() || 'Rapid'} Tournament`,
      description: data.description || '',
      timeControl: data.timeControl || 'blitz',
      initialTime: data.initialTime || 300,
      increment: data.increment || 3,
      maxPlayers: data.maxPlayers || 16,
      minPlayers: data.minPlayers || 4,
      currentPlayers: 0,
      registeredPlayers: [],
      rounds: data.rounds || Math.log2(data.maxPlayers || 16),
      currentRound: 0,
      status: 'waiting',
      format: data.format || 'knockout',
      ratingMin: data.ratingMin || 0,
      ratingMax: data.ratingMax || 9999,
      isRated: data.isRated !== false,
      prize: data.prize || null,
      createdBy: data.createdBy,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      startedAt: null,
      endedAt: null,
      bracket: [],
      matches: [],
    };

    await db.collection(TOURNAMENTS_COLLECTION).doc(tournamentId).set(tournament);
    return tournament;
  }

  static async getTournament(tournamentId) {
    const db = getDb();
    const doc = await db.collection(TOURNAMENTS_COLLECTION).doc(tournamentId).get();
    if (!doc.exists) return null;
    return { id: doc.id, ...doc.data() };
  }

  static async getActiveTournaments() {
    const db = getDb();
    const snapshot = await db
      .collection(TOURNAMENTS_COLLECTION)
      .where('status', 'in', ['waiting', 'in_progress'])
      .orderBy('createdAt', 'desc')
      .limit(20)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  static async registerPlayer(tournamentId, uid, username, elo) {
    const db = getDb();
    const tournament = await this.getTournament(tournamentId);
    if (!tournament) throw new Error('Tournament not found');
    if (tournament.status !== 'waiting') throw new Error('Tournament already started');
    if (tournament.currentPlayers >= tournament.maxPlayers) throw new Error('Tournament is full');

    const alreadyRegistered = tournament.registeredPlayers.find((p) => p.uid === uid);
    if (alreadyRegistered) throw new Error('Already registered');

    const player = { uid, username, elo, joinedAt: new Date().toISOString() };

    await db.collection(TOURNAMENTS_COLLECTION).doc(tournamentId).update({
      registeredPlayers: admin.firestore.FieldValue.arrayUnion(player),
      currentPlayers: admin.firestore.FieldValue.increment(1),
    });

    return player;
  }

  static async unregisterPlayer(tournamentId, uid) {
    const db = getDb();
    const tournament = await this.getTournament(tournamentId);
    if (!tournament) throw new Error('Tournament not found');

    const player = tournament.registeredPlayers.find((p) => p.uid === uid);
    if (!player) throw new Error('Not registered');

    await db.collection(TOURNAMENTS_COLLECTION).doc(tournamentId).update({
      registeredPlayers: admin.firestore.FieldValue.arrayRemove(player),
      currentPlayers: admin.firestore.FieldValue.increment(-1),
    });
  }
}

module.exports = Tournament;
