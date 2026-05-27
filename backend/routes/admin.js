const express = require('express');
const router = express.Router();
const { getDb, admin } = require('../config/firebase');
const User = require('../models/User');

const adminAuth = (req, res, next) => {
  const adminKey = req.headers['x-admin-key'];
  if (adminKey !== process.env.ADMIN_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
};

router.get('/stats', adminAuth, async (req, res) => {
  try {
    const db = getDb();
    const usersSnapshot = await db.collection('users').count().get();
    const gamesSnapshot = await db.collection('games').count().get();
    const activeGames = await db.collection('games').where('status', '==', 'active').count().get();

    res.json({
      totalUsers: usersSnapshot.data().count || 0,
      totalGames: gamesSnapshot.data().count || 0,
      activeGames: activeGames.data().count || 0,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/users/:uid/ban', adminAuth, async (req, res) => {
  try {
    await User.updateUser(req.params.uid, { isBanned: true });
    const db = getDb();
    await db.collection('admin_audit').add({
      action: 'ban',
      targetUid: req.params.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/users/:uid/unban', adminAuth, async (req, res) => {
  try {
    await User.updateUser(req.params.uid, { isBanned: false });
    const db = getDb();
    await db.collection('admin_audit').add({
      action: 'unban',
      targetUid: req.params.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
