const express = require('express');
const router = express.Router();
const Tournament = require('../models/Tournament');

router.post('/create', async (req, res) => {
  try {
    const tournament = await Tournament.createTournament(req.body);
    res.status(201).json(tournament);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/active', async (req, res) => {
  try {
    const tournaments = await Tournament.getActiveTournaments();
    res.json(tournaments);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/:tournamentId', async (req, res) => {
  try {
    const tournament = await Tournament.getTournament(req.params.tournamentId);
    if (!tournament) return res.status(404).json({ error: 'Tournament not found' });
    res.json(tournament);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/:tournamentId/register', async (req, res) => {
  try {
    const { uid, username, elo } = req.body;
    const result = await Tournament.registerPlayer(req.params.tournamentId, uid, username, elo);
    res.json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/:tournamentId/unregister', async (req, res) => {
  try {
    const { uid } = req.body;
    await Tournament.unregisterPlayer(req.params.tournamentId, uid);
    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
