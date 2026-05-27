const express = require('express');
const router = express.Router();
const { Game } = require('../models/Game');
const { getDb } = require('../config/firebase');

router.get('/:gameId', async (req, res) => {
  try {
    const game = await Game.getGame(req.params.gameId);
    if (!game) return res.status(404).json({ error: 'Game not found' });
    res.json(game);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/create', async (req, res) => {
  try {
    const game = await Game.createGame(req.body);
    res.status(201).json(game);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/history/:uid', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;
    const games = await Game.getGameHistory(req.params.uid, limit, offset);
    res.json(games);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/live/list', async (req, res) => {
  try {
    const games = await Game.getLiveGames();
    res.json(games);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/:gameId/analyze', async (req, res) => {
  try {
    const { moves } = req.body;
    const chessEngine = require('../services/ChessEngine');
    const game = await Game.getGame(req.params.gameId);
    if (!game) return res.status(404).json({ error: 'Game not found' });

    const classifications = [];
    let fen = game.fen || 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

    for (let i = 0; i < (moves || []).length; i++) {
      const move = moves[i];
      const piece = move.piece || 'p';
      const captured = move.captured || null;
      const classification = chessEngine.classifyMove(fen, move.notation, piece, captured, false, false, false);
      classifications.push({ moveIndex: i, classification, notation: move.notation });
    }

    const analysis = {
      accuracy: Game.calculateAccuracy(moves, { white: 0, black: 0 }),
      totalMoves: moves?.length || 0,
      classifications,
    };

    res.json(analysis);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
