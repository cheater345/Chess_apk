const { getDb, admin } = require('../config/firebase');
const { ELO, RATING_LEAGUES, DAILY_REWARDS } = require('../config/constants');

const USERS_COLLECTION = 'users';
const PROFILES_COLLECTION = 'profiles';

class User {
  static _serialize(doc) {
    if (!doc) return null;
    const data = { id: doc.id, ...doc.data() };
    for (const key of ['createdAt', 'lastLogin', 'lastActiveAt']) {
      if (data[key] && typeof data[key].toDate === 'function') {
        data[key] = data[key].toDate().toISOString();
      }
    }
    return data;
  }

  static async createUser(uid, data) {
    const db = getDb();
    const userData = {
      uid,
      email: data.email || '',
      username: data.username || `Player_${uid.slice(0, 6)}`,
      displayName: data.displayName || data.username || `Player_${uid.slice(0, 6)}`,
      photoURL: data.photoURL || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      isGuest: data.isGuest || false,
      isOnline: false,
      elo: {
        bullet: ELO.STARTING,
        blitz: ELO.STARTING,
        rapid: ELO.STARTING,
        classical: ELO.STARTING,
      },
      stats: {
        gamesPlayed: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        winStreak: 0,
        bestWinStreak: 0,
        totalMoves: 0,
        puzzlesSolved: 0,
        puzzlesAttempted: 0,
        tournamentWins: 0,
        tournamentsPlayed: 0,
      },
      coins: 100,
      xp: 0,
      level: 1,
      achievements: [],
      dailyReward: {
        lastClaimed: null,
        streak: 0,
        claimedToday: false,
      },
      settings: {
        soundEnabled: true,
        pieceAnimation: true,
        showMoveHints: true,
        boardTheme: 'green',
        pieceTheme: 'default',
        autoQueen: true,
        confirmMoves: false,
        enableChat: true,
        enableNotifications: true,
      },
      subscriptions: [],
      badges: ['newcomer'],
      isBanned: false,
      lastActiveAt: null,
    };

    await db.collection(USERS_COLLECTION).doc(uid).set(userData);
    const saved = await db.collection(USERS_COLLECTION).doc(uid).get();
    return User._serialize(saved);
  }

  static async getUserById(uid) {
    const db = getDb();
    const doc = await db.collection(USERS_COLLECTION).doc(uid).get();
    if (!doc.exists) return null;
    return User._serialize(doc);
  }

  static async getUserByUsername(username) {
    const db = getDb();
    const snapshot = await db
      .collection(USERS_COLLECTION)
      .where('username', '==', username)
      .limit(1)
      .get();
    if (snapshot.empty) return null;
    return User._serialize(snapshot.docs[0]);
  }

  static async updateUser(uid, updates) {
    const db = getDb();
    await db.collection(USERS_COLLECTION).doc(uid).update(updates);
  }

  static async getAllUsers(limit = 50, offset = 0) {
    const db = getDb();
    const snapshot = await db
      .collection(USERS_COLLECTION)
      .orderBy('elo.rapid', 'desc')
      .limit(limit)
      .offset(offset)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  static async getLeaderboard(timeControl = 'rapid', limit = 100) {
    const db = getDb();
    const snapshot = await db
      .collection(USERS_COLLECTION)
      .where('isGuest', '==', false)
      .orderBy(`elo.${timeControl}`, 'desc')
      .limit(limit)
      .get();
    return snapshot.docs.map((doc) => ({
      id: doc.id,
      username: doc.data().username,
      displayName: doc.data().displayName,
      photoURL: doc.data().photoURL,
      elo: doc.data().elo?.[timeControl] || ELO.STARTING,
      level: doc.data().level || 1,
      stats: doc.data().stats,
    }));
  }

  static async calculateElo(ratingA, ratingB, scoreA, kFactor = ELO.K_FACTOR) {
    const expectedA = 1 / (1 + Math.pow(10, (ratingB - ratingA) / 400));
    const expectedB = 1 - expectedA;
    const newRatingA = Math.round(ratingA + kFactor * (scoreA - expectedA));
    const newRatingB = Math.round(ratingB + kFactor * ((1 - scoreA) - expectedB));
    return {
      newRatingA: Math.max(ELO.MIN_RATING, Math.min(ELO.MAX_RATING, newRatingA)),
      newRatingB: Math.max(ELO.MIN_RATING, Math.min(ELO.MAX_RATING, newRatingB)),
      ratingChangeA: Math.round(newRatingA - ratingA),
      ratingChangeB: Math.round(newRatingB - ratingB),
    };
  }

  static getRank(rating) {
    for (let i = RATING_LEAGUES.length - 1; i >= 0; i--) {
      if (rating >= RATING_LEAGUES[i].min) {
        return RATING_LEAGUES[i];
      }
    }
    return RATING_LEAGUES[0];
  }

  static async claimDailyReward(uid) {
    const db = getDb();
    const user = await this.getUserById(uid);
    if (!user) throw new Error('User not found');

    const now = new Date();
    const lastClaimed = user.dailyReward?.lastClaimed?.toDate?.() || null;
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    if (user.dailyReward?.claimedToday) {
      throw new Error('Daily reward already claimed today');
    }

    let streak = user.dailyReward?.streak || 0;

    if (lastClaimed) {
      const lastClaimDay = new Date(lastClaimed.getFullYear(), lastClaimed.getMonth(), lastClaimed.getDate());
      const diffDays = Math.floor((today - lastClaimDay) / (1000 * 60 * 60 * 24));
      streak = diffDays === 1 ? streak + 1 : 0;
    } else {
      streak = 0;
    }

    const rewardIndex = streak % DAILY_REWARDS.length;
    const reward = DAILY_REWARDS[rewardIndex];

    await db.collection(USERS_COLLECTION).doc(uid).update({
      coins: admin.firestore.FieldValue.increment(reward.coins),
      xp: admin.firestore.FieldValue.increment(reward.xp),
      'dailyReward.lastClaimed': admin.firestore.FieldValue.serverTimestamp(),
      'dailyReward.streak': streak,
      'dailyReward.claimedToday': true,
    });

    return { ...reward, streak, day: streak + 1 };
  }
}

module.exports = User;
