const express = require('express');
const router = express.Router();
const { getDb } = require('../config/firebase');

router.get('/global', async (req, res) => {
  try {
    const db = getDb();
    const limit = parseInt(req.query.limit) || 50;
    const snapshot = await db
      .collection('chat_global')
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .get();

    const messages = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .reverse();

    res.json(messages);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/private/:uid1/:uid2', async (req, res) => {
  try {
    const db = getDb();
    const chatId = [req.params.uid1, req.params.uid2].sort().join('_');
    const limit = parseInt(req.query.limit) || 50;
    const snapshot = await db
      .collection('private_chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .get();

    const messages = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .reverse();

    res.json(messages);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
