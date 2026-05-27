const express = require('express');
const router = express.Router();
const User = require('../models/User');

router.get('/:timeControl', async (req, res) => {
  try {
    const tc = ['bullet', 'blitz', 'rapid', 'classical'].includes(req.params.timeControl)
      ? req.params.timeControl
      : 'rapid';
    const limit = parseInt(req.query.limit) || 100;
    const leaderboard = await User.getLeaderboard(tc, limit);
    const ranked = leaderboard.map((user, index) => ({
      rank: index + 1,
      ...user,
    }));
    res.json(ranked);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/:timeControl/top/:count', async (req, res) => {
  try {
    const tc = ['bullet', 'blitz', 'rapid', 'classical'].includes(req.params.timeControl)
      ? req.params.timeControl
      : 'rapid';
    const count = Math.min(parseInt(req.params.count) || 10, 100);
    const leaderboard = await User.getLeaderboard(tc, count);
    const ranked = leaderboard.map((user, index) => ({
      rank: index + 1,
      ...user,
    }));
    res.json(ranked);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/:timeControl/around/:uid', async (req, res) => {
  try {
    const tc = ['bullet', 'blitz', 'rapid', 'classical'].includes(req.params.timeControl)
      ? req.params.timeControl
      : 'rapid';
    const user = await User.getUserById(req.params.uid);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const userRating = user.elo?.[tc] || 1200;
    const leaderboard = await User.getLeaderboard(tc, 500);
    const userIndex = leaderboard.findIndex((u) => u.id === req.params.uid);
    const rank = userIndex !== -1 ? userIndex + 1 : 'Unranked';

    const start = Math.max(0, userIndex - 5);
    const end = Math.min(leaderboard.length, userIndex + 6);
    const around = leaderboard.slice(start, end).map((u, i) => ({
      rank: start + i + 1,
      ...u,
    }));

    res.json({ rank, userRating, around, totalPlayers: leaderboard.length });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
