class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';
  static const String socketUrl = 'http://localhost:3000';

  static const String apiV1 = '$baseUrl/api';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  static bool useEmulator = true;

  static Map<String, String> headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static String get authRegister => '$apiV1/auth/register';
  static String get authLogin => '$apiV1/auth/login';
  static String get authGuest => '$apiV1/auth/guest';
  static String get checkUsername => '$apiV1/auth/check-username';

  static String profile(String uid) => '$apiV1/profile/$uid';
  static String profileStats(String uid) => '$apiV1/profile/$uid/stats';
  static String dailyReward(String uid) => '$apiV1/profile/$uid/daily-reward';
  static String achievements(String uid) => '$apiV1/profile/$uid/achievements';
  static String settings(String uid) => '$apiV1/profile/$uid/settings';

  static String get gameCreate => '$apiV1/games/create';
  static String gameDetail(String gameId) => '$apiV1/games/$gameId';
  static String gameHistory(String uid) => '$apiV1/games/history/$uid';
  static String get liveGames => '$apiV1/games/live/list';
  static String gameAnalyze(String gameId) => '$apiV1/games/$gameId/analyze';

  static String get puzzlesDaily => '$apiV1/puzzles/daily';
  static String get puzzlesRandom => '$apiV1/puzzles/random';
  static String get puzzlesByRating => '$apiV1/puzzles/by-rating';
  static String puzzleSolve(String id) => '$apiV1/puzzles/$id/solve';

  static String get tournamentsActive => '$apiV1/tournaments/active';
  static String get tournamentCreate => '$apiV1/tournaments/create';
  static String tournamentDetail(String id) => '$apiV1/tournaments/$id';
  static String tournamentRegister(String id) => '$apiV1/tournaments/$id/register';
  static String tournamentUnregister(String id) => '$apiV1/tournaments/$id/unregister';

  static String leaderboard(String tc) => '$apiV1/leaderboard/$tc';
  static String leaderboardAround(String tc, String uid) => '$apiV1/leaderboard/$tc/around/$uid';

  static String get health => '$apiV1/health';
  static String get status => '$apiV1/status';
}
