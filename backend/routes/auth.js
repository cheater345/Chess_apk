const express = require('express');
const router = express.Router();
const { getDb, admin } = require('../config/firebase');
const User = require('../models/User');

router.post('/register', async (req, res) => {
  try {
    const { email, password, username } = req.body;
    if (!email || !password || !username) {
      return res.status(400).json({ error: 'Email, password, and username required' });
    }

    const auth = admin.auth();
    const userRecord = await auth.createUser({ email, password, displayName: username });
    const user = await User.createUser(userRecord.uid, { email, username });

    const token = await auth.createCustomToken(userRecord.uid);

    res.status(201).json({
      uid: userRecord.uid,
      token,
      user,
    });
  } catch (error) {
    res.status(400).json({
      error: error.message,
      code: error.code,
    });
  }
});

router.post('/guest', async (req, res) => {
  try {
    const auth = admin.auth();
    const guestId = `guest_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    const userRecord = await auth.createUser({
      uid: guestId,
      displayName: `Guest_${guestId.slice(-6)}`,
    });

    const user = await User.createUser(guestId, {
      username: `Guest_${guestId.slice(-6)}`,
      isGuest: true,
    });

    const token = await auth.createCustomToken(guestId);

    res.status(201).json({ uid: guestId, token, user, isGuest: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ error: 'ID token required' });
    }

    const auth = admin.auth();
    const decodedToken = await auth.verifyIdToken(idToken);
    const uid = decodedToken.uid;

    let user = await User.getUserById(uid);
    if (!user) {
      user = await User.createUser(uid, {
        email: decodedToken.email || '',
        username: decodedToken.displayName || `Player_${uid.slice(0, 6)}`,
      });
    } else {
      await User.updateUser(uid, {
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
        isOnline: true,
      });
    }

    const token = await auth.createCustomToken(uid);

    res.json({ uid, token, user });
  } catch (error) {
    res.status(401).json({ error: 'Invalid token: ' + error.message });
  }
});

router.post('/refresh-token', async (req, res) => {
  try {
    const { uid } = req.body;
    const auth = admin.auth();
    const token = await auth.createCustomToken(uid);
    res.json({ token });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/check-username', async (req, res) => {
  try {
    const { username } = req.body;
    const existing = await User.getUserByUsername(username);
    res.json({ available: !existing });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/me', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }
    const token = authHeader.split(' ')[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const user = await User.getUserById(decodedToken.uid);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (error) {
    res.status(401).json({ error: 'Invalid token: ' + error.message });
  }
});

module.exports = router;
