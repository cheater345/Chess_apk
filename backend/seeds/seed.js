require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const { initFirebase, getDb, admin } = require('../config/firebase');
const { ELO } = require('../config/constants');

const SAMPLE_USERS = [
  { username: 'MagnusCarlsen', displayName: 'Magnus Carlsen', elo: { bullet: 2900, blitz: 2880, rapid: 2850, classical: 2845 }, level: 50, xp: 150000, coins: 50000, gamesPlayed: 15000, wins: 11000, losses: 3000, draws: 1000 },
  { username: 'HikaruNakamura', displayName: 'Hikaru Nakamura', elo: { bullet: 3100, blitz: 2950, rapid: 2800, classical: 2760 }, level: 48, xp: 140000, coins: 45000, gamesPlayed: 20000, wins: 14500, losses: 4500, draws: 1000 },
  { username: 'LevyRozman', displayName: 'GothamChess', elo: { bullet: 2400, blitz: 2450, rapid: 2350, classical: 2300 }, level: 35, xp: 80000, coins: 25000, gamesPlayed: 8000, wins: 5500, losses: 2000, draws: 500 },
  { username: 'ChessWizard42', displayName: 'Chess Wizard', elo: { bullet: 2100, blitz: 2050, rapid: 2000, classical: 1950 }, level: 25, xp: 45000, coins: 15000, gamesPlayed: 3000, wins: 2000, losses: 800, draws: 200 },
  { username: 'QueenGambit', displayName: 'Beth Harmon', elo: { bullet: 1950, blitz: 2000, rapid: 2100, classical: 2150 }, level: 22, xp: 35000, coins: 12000, gamesPlayed: 2500, wins: 1600, losses: 700, draws: 200 },
  { username: 'KnightRider', displayName: 'Knight Rider', elo: { bullet: 1800, blitz: 1750, rapid: 1700, classical: 1650 }, level: 18, xp: 25000, coins: 8000, gamesPlayed: 1500, wins: 900, losses: 500, draws: 100 },
  { username: 'BishopBash', displayName: 'Bishop Bash', elo: { bullet: 1600, blitz: 1550, rapid: 1500, classical: 1450 }, level: 15, xp: 18000, coins: 6000, gamesPlayed: 1000, wins: 600, losses: 350, draws: 50 },
  { username: 'RookRoller', displayName: 'Rook Roller', elo: { bullet: 1450, blitz: 1400, rapid: 1350, classical: 1300 }, level: 12, xp: 12000, coins: 4000, gamesPlayed: 600, wins: 350, losses: 220, draws: 30 },
  { username: 'PawnStar', displayName: 'Pawn Star', elo: { bullet: 1300, blitz: 1250, rapid: 1200, classical: 1150 }, level: 10, xp: 8000, coins: 2500, gamesPlayed: 300, wins: 150, losses: 130, draws: 20 },
  { username: 'ChessNoob', displayName: 'Chess Noob', elo: { bullet: 1050, blitz: 1000, rapid: 950, classical: 900 }, level: 5, xp: 3000, coins: 1000, gamesPlayed: 100, wins: 40, losses: 55, draws: 5 },
  { username: 'TacticalTom', displayName: 'Tactical Tom', elo: { bullet: 1900, blitz: 1850, rapid: 1800, classical: 1750 }, level: 20, xp: 30000, coins: 10000, gamesPlayed: 2000, wins: 1300, losses: 600, draws: 100 },
  { username: 'EndgameEve', displayName: 'Endgame Eve', elo: { bullet: 1700, blitz: 1750, rapid: 1850, classical: 1900 }, level: 20, xp: 32000, coins: 11000, gamesPlayed: 2200, wins: 1400, losses: 700, draws: 100 },
  { username: 'SpeedDemon', displayName: 'Speed Demon', elo: { bullet: 2600, blitz: 2400, rapid: 2200, classical: 2100 }, level: 40, xp: 100000, coins: 30000, gamesPlayed: 12000, wins: 9000, losses: 2500, draws: 500 },
  { username: 'FishTactics', displayName: 'Fish Tactics', elo: { bullet: 1500, blitz: 1450, rapid: 1400, classical: 1350 }, level: 14, xp: 15000, coins: 5000, gamesPlayed: 800, wins: 450, losses: 300, draws: 50 },
  { username: 'ZugzwangZero', displayName: 'Zugzwang Zero', elo: { bullet: 2200, blitz: 2150, rapid: 2100, classical: 2050 }, level: 28, xp: 55000, coins: 18000, gamesPlayed: 4000, wins: 2800, losses: 1000, draws: 200 },
  { username: 'FoolsMatePro', displayName: "Fool's Mate Pro", elo: { bullet: 1100, blitz: 1150, rapid: 1200, classical: 1250 }, level: 8, xp: 5000, coins: 1500, gamesPlayed: 200, wins: 100, losses: 90, draws: 10 },
  { username: 'CastleKing', displayName: 'Castle King', elo: { bullet: 2000, blitz: 1950, rapid: 1900, classical: 1850 }, level: 24, xp: 40000, coins: 14000, gamesPlayed: 3500, wins: 2200, losses: 1100, draws: 200 },
  { username: 'EnPassant', displayName: 'En Passant', elo: { bullet: 1400, blitz: 1350, rapid: 1300, classical: 1250 }, level: 11, xp: 9000, coins: 3000, gamesPlayed: 500, wins: 280, losses: 190, draws: 30 },
  { username: 'PinStripe', displayName: 'Pin Stripe', elo: { bullet: 1750, blitz: 1700, rapid: 1650, classical: 1600 }, level: 17, xp: 22000, coins: 7000, gamesPlayed: 1200, wins: 700, losses: 400, draws: 100 },
  { username: 'SmotheredMate', displayName: 'Smothered Mate', elo: { bullet: 1850, blitz: 1800, rapid: 1750, classical: 1700 }, level: 19, xp: 28000, coins: 9000, gamesPlayed: 1800, wins: 1100, losses: 600, draws: 100 },
  { username: 'ItalianGame', displayName: 'Italian Game', elo: { bullet: 1550, blitz: 1500, rapid: 1450, classical: 1400 }, level: 13, xp: 13000, coins: 4500, gamesPlayed: 700, wins: 400, losses: 250, draws: 50 },
  { username: 'SicilianDragon', displayName: 'Sicilian Dragon', elo: { bullet: 2050, blitz: 2000, rapid: 1950, classical: 1900 }, level: 26, xp: 48000, coins: 16000, gamesPlayed: 5000, wins: 3200, losses: 1500, draws: 300 },
  { username: 'KingsGambit', displayName: "King's Gambit", elo: { bullet: 1650, blitz: 1600, rapid: 1550, classical: 1500 }, level: 16, xp: 20000, coins: 6500, gamesPlayed: 900, wins: 500, losses: 350, draws: 50 },
  { username: 'LondonSystem', displayName: 'London System', elo: { bullet: 1350, blitz: 1400, rapid: 1450, classical: 1500 }, level: 12, xp: 11000, coins: 3500, gamesPlayed: 400, wins: 220, losses: 150, draws: 30 },
  { username: 'CaroKannQueen', displayName: 'Caro-Kann Queen', elo: { bullet: 2250, blitz: 2200, rapid: 2150, classical: 2100 }, level: 30, xp: 60000, coins: 20000, gamesPlayed: 6000, wins: 4000, losses: 1500, draws: 500 },
];

const SAMPLE_GAMES = [
  { white: 'MagnusCarlsen', black: 'HikaruNakamura', result: '1-0', tc: 'blitz', moves: 45 },
  { white: 'HikaruNakamura', black: 'SpeedDemon', result: '0-1', tc: 'bullet', moves: 32 },
  { white: 'LevyRozman', black: 'MagnusCarlsen', result: '0-1', tc: 'rapid', moves: 56 },
  { white: 'QueenGambit', black: 'TacticalTom', result: '1-0', tc: 'classical', moves: 78 },
  { white: 'ChessWizard42', black: 'SicilianDragon', result: '1/2-1/2', tc: 'rapid', moves: 64 },
];

async function seed() {
  console.log('Seeding database...');
  const db = getDb();

  for (const sample of SAMPLE_USERS) {
    const uid = `seed_${sample.username.toLowerCase()}`;
    const userData = {
      uid,
      email: `${sample.username.toLowerCase()}@openchess.arena`,
      username: sample.username,
      displayName: sample.displayName,
      photoURL: `https://api.dicebear.com/7.x/avataaars/svg?seed=${sample.username}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      isGuest: false,
      isOnline: Math.random() > 0.5,
      elo: sample.elo,
      stats: {
        gamesPlayed: sample.gamesPlayed,
        wins: sample.wins,
        losses: sample.losses,
        draws: sample.draws,
        winStreak: Math.floor(Math.random() * 10),
        bestWinStreak: Math.floor(Math.random() * 15) + 5,
        totalMoves: sample.gamesPlayed * 35,
        puzzlesSolved: Math.floor(Math.random() * 200),
        puzzlesAttempted: Math.floor(Math.random() * 250) + 50,
        tournamentWins: Math.floor(Math.random() * 5),
        tournamentsPlayed: Math.floor(Math.random() * 10) + 2,
      },
      coins: sample.coins,
      xp: sample.xp,
      level: sample.level,
      achievements: ['first_win', 'first_game'],
      settings: {
        soundEnabled: true,
        pieceAnimation: true,
        showMoveHints: true,
        boardTheme: 'green',
        pieceTheme: 'default',
        autoQueen: true,
      },
    };

    await db.collection('users').doc(uid).set(userData);
    console.log(`Created user: ${sample.username} (${sample.elo.rapid} elo)`);
  }

  for (const game of SAMPLE_GAMES) {
    const whiteUid = `seed_${game.white.toLowerCase()}`;
    const blackUid = `seed_${game.black.toLowerCase()}`;
    const gameData = {
      gameId: `seed_game_${game.white}_${game.black}_${Date.now()}`,
      players: {
        white: { uid: whiteUid, username: game.white, elo: 1500, clock: 0 },
        black: { uid: blackUid, username: game.black, elo: 1500, clock: 0 },
      },
      timeControl: game.tc,
      initialTime: game.tc === 'bullet' ? 60 : game.tc === 'blitz' ? 300 : game.tc === 'rapid' ? 600 : 1800,
      increment: game.tc === 'bullet' ? 0 : 3,
      status: 'completed',
      result: game.result,
      winner: game.result === '1-0' ? 'white' : game.result === '0-1' ? 'black' : null,
      moves: [],
      moveCount: game.moves,
      startTime: admin.firestore.FieldValue.serverTimestamp(),
      endTime: admin.firestore.FieldValue.serverTimestamp(),
      isRated: true,
    };

    await db.collection('games').doc(gameData.gameId).set(gameData);
    console.log(`Created game: ${game.white} vs ${game.black} (${game.result})`);
  }

  const chatMessages = [
    'Hello everyone! 🎉',
    'Anyone up for a blitz game?',
    'Just reached 1800 rated!',
    'The new update looks amazing!',
    'Anyone solved today\'s puzzle?',
    'Looking for classical games',
    'GG to my last opponent!',
    'Any tips for the Sicilian?',
    'Love the new board themes',
    'Who\'s going to the tournament?',
  ];

  for (let i = 0; i < 20; i++) {
    const randomUser = SAMPLE_USERS[Math.floor(Math.random() * SAMPLE_USERS.length)];
    const msg = {
      uid: `seed_${randomUser.username.toLowerCase()}`,
      username: randomUser.username,
      message: chatMessages[Math.floor(Math.random() * chatMessages.length)],
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('chat_global').add(msg);
  }

  console.log('Created global chat messages');
  console.log('Seeding complete!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
