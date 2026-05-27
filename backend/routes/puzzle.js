const express = require('express');
const router = express.Router();
const { getDb, admin } = require('../config/firebase');

const PUZZLES = [
  { id: 1, fen: 'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', moves: ['e5', 'Nxe5', 'Nxe5', 'Qh5'], rating: 1200, theme: 'fork' },
  { id: 2, fen: 'rnbqkbnr/pppp1ppp/8/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 1 2', moves: ['d6', 'Bb5+', 'Bd7', 'Bxd7+'], rating: 1300, theme: 'pin' },
  { id: 3, fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 4 4', moves: ['Bb5', 'a6', 'Bxc6', 'dxc6'], rating: 1400, theme: 'exchange' },
  { id: 4, fen: 'r1bqkb1r/pppp1ppp/2n5/4p3/2B1n3/5N2/PPPP1PPP/RNBQ1K1R b kq - 3 4', moves: ['Nxf2', 'Kxf2', 'Qh4+'], rating: 1500, theme: 'fork' },
  { id: 5, fen: 'rnbqkb1r/pppppppp/5n2/4P3/8/2N5/PPPP1PPP/R1BQKBNR b KQkq - 0 2', moves: ['Nxe5', 'Qh5', 'Ng6', 'Qe5+'], rating: 1600, theme: 'discovery' },
  { id: 6, fen: 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 4 4', moves: ['Nxe5', 'Nxe5', 'd4', 'Bxd4'], rating: 1700, theme: 'center' },
  { id: 7, fen: 'r1bqk2r/pppp1Npp/1bn5/4p3/2B1P3/8/PPPP1PPP/RNBQK2R b KQkq - 0 5', moves: ['Bxd7+', 'Kxd7', 'Qh5'], rating: 1800, theme: 'attraction' },
  { id: 8, fen: 'r1bq1rk1/pppp1ppp/2n2n2/2b1p3/2B1P3/2NP1N2/PPP2PPP/R1BQK2R w KQ - 0 5', moves: ['Bxf7+', 'Rxf7', 'Ng5', 'Re8'], rating: 1900, theme: 'sacrifice' },
  { id: 9, fen: 'r1bq1rk1/pppp1ppp/2n2n2/2b1P3/2B5/2NP1N2/PPP2PPP/R1BQK2R b KQ - 0 5', moves: ['Nxe5', 'Nxe5', 'd6', 'Qh5'], rating: 2000, theme: 'intermediate' },
  { id: 10, fen: 'r1bq1rk1/ppp2ppp/2np4/2b1p3/2B1P1n1/2NP1N2/PPP2PPP/R1BQK2R w KQ - 0 6', moves: ['hxg4', 'Bxg4', 'Kh1', 'Qh4'], rating: 2100, theme: 'attack' },
];

router.get('/daily', async (req, res) => {
  try {
    const today = new Date().toDateString();
    const puzzleIndex = today.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0) % PUZZLES.length;
    res.json(PUZZLES[puzzleIndex]);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/random', async (req, res) => {
  try {
    const rating = parseInt(req.query.rating) || 1200;
    const filtered = PUZZLES.filter((p) => Math.abs(p.rating - rating) < 300);
    const pool = filtered.length > 0 ? filtered : PUZZLES;
    const puzzle = pool[Math.floor(Math.random() * pool.length)];
    res.json(puzzle);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/by-rating', async (req, res) => {
  try {
    const min = parseInt(req.query.min) || 0;
    const max = parseInt(req.query.max) || 9999;
    const filtered = PUZZLES.filter((p) => p.rating >= min && p.rating <= max);

    const count = parseInt(req.query.count) || 5;
    const selected = [];
    const shuffled = [...filtered].sort(() => Math.random() - 0.5);
    for (let i = 0; i < Math.min(count, shuffled.length); i++) {
      selected.push(shuffled[i]);
    }

    res.json(selected);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/list', async (req, res) => {
  try {
    res.json(PUZZLES);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/:puzzleId/solve', async (req, res) => {
  try {
    const { uid, solved, timeSpent } = req.body;
    const db = getDb();

    await db.collection('users').doc(uid).update({
      'stats.puzzlesAttempted': admin.firestore.FieldValue.increment(1),
      'stats.puzzlesSolved': admin.firestore.FieldValue.increment(solved ? 1 : 0),
      xp: admin.firestore.FieldValue.increment(solved ? 25 : 5),
      coins: admin.firestore.FieldValue.increment(solved ? 10 : 1),
    });

    await db.collection('puzzle_solves').add({
      uid,
      puzzleId: req.params.puzzleId,
      solved,
      timeSpent,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ solved, xp: solved ? 25 : 5, coins: solved ? 10 : 1 });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
