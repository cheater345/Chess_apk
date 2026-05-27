const GAME_TIME_CONTROLS = {
  bullet: { name: 'Bullet', initial: 60, increment: 0, icon: 'bolt' },
  blitz: { name: 'Blitz', initial: 300, increment: 3, icon: 'zap' },
  rapid: { name: 'Rapid', initial: 600, increment: 5, icon: 'clock' },
  classical: { name: 'Classical', initial: 1800, increment: 10, icon: 'hourglass' },
};

const ELO = {
  STARTING: 1200,
  K_FACTOR: 32,
  K_FACTOR_NEW: 64,
  NEW_PLAYER_GAMES: 20,
  MIN_RATING: 100,
  MAX_RATING: 4000,
};

const RANKS = [
  { name: 'Bronze', min: 100, max: 1199, color: '#CD7F32' },
  { name: 'Silver', min: 1200, max: 1399, color: '#C0C0C0' },
  { name: 'Gold', min: 1400, max: 1599, color: '#FFD700' },
  { name: 'Platinum', min: 1600, max: 1799, color: '#E5E4E2' },
  { name: 'Diamond', min: 1800, max: 1999, color: '#B9F2FF' },
  { name: 'Master', min: 2000, max: 2199, color: '#FF69B4' },
  { name: 'Grandmaster', min: 2200, max: 4000, color: '#FF0000' },
];

const RATING_LEAGUES = [
  { name: 'Bronze', min: 100, icon: 'shield', color: '#CD7F32' },
  { name: 'Silver', min: 1200, icon: 'sword', color: '#C0C0C0' },
  { name: 'Gold', min: 1400, icon: 'crown', color: '#FFD700' },
  { name: 'Platinum', min: 1600, icon: 'star', color: '#E5E4E2' },
  { name: 'Diamond', min: 1800, icon: 'gem', color: '#B9F2FF' },
  { name: 'Master', min: 2000, icon: 'trophy', color: '#FF69B4' },
  { name: 'Grandmaster', min: 2200, icon: 'globe', color: '#FF0000' },
];

const ACHIEVEMENTS = [
  { id: 'first_win', name: 'First Victory', description: 'Win your first game', icon: 'trophy', xp: 100 },
  { id: 'first_game', name: 'First Move', description: 'Play your first game', icon: 'chess_pawn', xp: 50 },
  { id: 'win_streak_3', name: 'On Fire', description: 'Win 3 games in a row', icon: 'flame', xp: 200 },
  { id: 'win_streak_5', name: 'Unstoppable', description: 'Win 5 games in a row', icon: 'lightning', xp: 500 },
  { id: 'perfect_game', name: 'Perfect Game', description: 'Win with 100% accuracy', icon: 'star', xp: 300 },
  { id: 'scholars_mate', name: 'Scholar', description: 'Win with Scholar\'s Mate', icon: 'graduation_cap', xp: 150 },
  { id: 'fools_mate', name: 'Lucky Day', description: 'Win with Fool\'s Mate', icon: 'clover', xp: 200 },
  { id: 'puzzle_solver_10', name: 'Puzzle Solver', description: 'Solve 10 puzzles', icon: 'puzzle', xp: 250 },
  { id: 'puzzle_solver_50', name: 'Puzzle Master', description: 'Solve 50 puzzles', icon: 'brain', xp: 1000 },
  { id: 'century', name: 'Century', description: 'Play 100 games', icon: '100', xp: 500 },
  { id: 'tournament_winner', name: 'Champion', description: 'Win a tournament', icon: 'crown', xp: 1000 },
  { id: 'rated_2000', name: 'Elite', description: 'Reach 2000 rating', icon: 'diamond', xp: 2000 },
];

const DAILY_REWARDS = [
  { day: 1, coins: 50, xp: 25 },
  { day: 2, coins: 75, xp: 35 },
  { day: 3, coins: 100, xp: 50, bonus: 'Free Puzzle Pass' },
  { day: 4, coins: 125, xp: 60 },
  { day: 5, coins: 150, xp: 75 },
  { day: 6, coins: 200, xp: 100, bonus: 'Gold Board (24h)' },
  { day: 7, coins: 500, xp: 250, bonus: 'Premium 3 Days' },
];

const PIECE_THEMES = [
  { id: 'default', name: 'Default', file: 'default.png' },
  { id: 'neo', name: 'Neo', file: 'neo.png' },
  { id: 'ocean', name: 'Ocean', file: 'ocean.png' },
  { id: 'wood', name: 'Wood', file: 'wood.png' },
  { id: 'marble', name: 'Marble', file: 'marble.png' },
  { id: 'classic', name: 'Classic', file: 'classic.png' },
];

const BOARD_THEMES = [
  { id: 'green', name: 'Green', light: '#769656', dark: '#eeeed2' },
  { id: 'brown', name: 'Brown', light: '#f0d9b5', dark: '#b58863' },
  { id: 'blue', name: 'Blue', light: '#dee3e6', dark: '#8ca2ad' },
  { id: 'purple', name: 'Purple', light: '#e8d5f5', dark: '#9b59b6' },
  { id: 'gray', name: 'Gray', light: '#d1d1d1', dark: '#999999' },
];

module.exports = {
  GAME_TIME_CONTROLS,
  ELO,
  RANKS,
  RATING_LEAGUES,
  ACHIEVEMENTS,
  DAILY_REWARDS,
  PIECE_THEMES,
  BOARD_THEMES,
};
