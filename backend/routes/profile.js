const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { DAILY_REWARDS, ACHIEVEMENTS } = require('../config/constants');
const { getDb, admin } = require('../config/firebase');

router.get('/:uid', async (req, res) => {
  try {
    const user = await User.getUserById(req.params.uid);
    if (!user) return res.status(404).json({ error: 'User not found' });
    const { email, isBanned, ...safeUser } = user;
    res.json(safeUser);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.put('/:uid', async (req, res) => {
  try {
    const allowedFields = ['displayName', 'photoURL', 'bio'];
    const updates = {};
    Object.keys(req.body).forEach((key) => {
      if (allowedFields.includes(key)) updates[key] = req.body[key];
    });

    if (req.body.settings) {
      updates.settings = req.body.settings;
    }

    await User.updateUser(req.params.uid, updates);
    const user = await User.getUserById(req.params.uid);
    res.json(user);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/:uid/stats', async (req, res) => {
  try {
    const user = await User.getUserById(req.params.uid);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const stats = {
      ...user.stats,
      elo: user.elo,
      rank: User.getRank(user.elo.rapid),
      level: user.level,
      xp: user.xp,
      coins: user.coins,
      winRate: user.stats.gamesPlayed > 0
        ? Math.round((user.stats.wins / user.stats.gamesPlayed) * 100)
        : 0,
      achievements: user.achievements?.length || 0,
      totalAchievements: ACHIEVEMENTS.length,
    };

    res.json(stats);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/:uid/daily-reward', async (req, res) => {
  try {
    const reward = await User.claimDailyReward(req.params.uid);
    res.json(reward);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/:uid/achievements', async (req, res) => {
  try {
    const user = await User.getUserById(req.params.uid);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const allAchievements = ACHIEVEMENTS.map((a) => ({
      ...a,
      unlocked: user.achievements?.includes(a.id) || false,
      unlockedAt: user.achievements?.includes(a.id) ? user.achievements.find((ua) => ua.id === a.id)?.unlockedAt : null,
    }));

    res.json(allAchievements);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/:uid/activity', async (req, res) => {
  try {
    const db = getDb();
    const snapshot1 = await db
      .collection('games')
      .where('players.white.uid', '==', req.params.uid)
      .where('status', '==', 'completed')
      .orderBy('endTime', 'desc')
      .limit(10)
      .get();

    const snapshot2 = await db
      .collection('games')
      .where('players.black.uid', '==', req.params.uid)
      .where('status', '==', 'completed')
      .orderBy('endTime', 'desc')
      .limit(10)
      .get();

    const gamesMap = new Map();
    snapshot1.docs.forEach((doc) => {
      const d = doc.data();
      gamesMap.set(doc.id, {
        id: doc.id,
        result: d.result,
        opponent: d.players.black,
        timeControl: d.timeControl,
        endTime: d.endTime,
        moveCount: d.moveCount,
      });
    });
    snapshot2.docs.forEach((doc) => {
      const d = doc.data();
      if (!gamesMap.has(doc.id)) {
        gamesMap.set(doc.id, {
          id: doc.id,
          result: d.result,
          opponent: d.players.white,
          timeControl: d.timeControl,
          endTime: d.endTime,
          moveCount: d.moveCount,
        });
      }
    });

    const games = Array.from(gamesMap.values())
      .sort((a, b) => (b.endTime?.toDate?.() || new Date()) - (a.endTime?.toDate?.() || new Date()))
      .slice(0, 10);

    res.json(games);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/:uid/settings', async (req, res) => {
  try {
    const user = await User.getUserById(req.params.uid);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user.settings || {});
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.put('/:uid/settings', async (req, res) => {
  try {
    await User.updateUser(req.params.uid, { settings: req.body });
    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
