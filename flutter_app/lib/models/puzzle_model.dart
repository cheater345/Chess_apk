class PuzzleModel {
  final int id;
  final String fen;
  final List<String> moves;
  final int rating;
  final String theme;

  PuzzleModel({
    required this.id,
    required this.fen,
    required this.moves,
    this.rating = 1200,
    this.theme = 'mixed',
  });

  factory PuzzleModel.fromJson(Map<String, dynamic> json) {
    return PuzzleModel(
      id: json['id'] ?? 0,
      fen: json['fen'] ?? '',
      moves: List<String>.from(json['moves'] ?? []),
      rating: json['rating'] ?? 1200,
      theme: json['theme'] ?? 'mixed',
    );
  }

  bool get isWhiteToMove => fen.split(' ')[1] == 'w';

  int get moveCount => moves.length;
}

class PuzzleResult {
  final int puzzleId;
  final bool solved;
  final int timeSpent;
  final int xpEarned;
  final int coinsEarned;

  PuzzleResult({
    required this.puzzleId,
    required this.solved,
    required this.timeSpent,
    this.xpEarned = 0,
    this.coinsEarned = 0,
  });

  factory PuzzleResult.fromJson(Map<String, dynamic> json) {
    return PuzzleResult(
      puzzleId: json['puzzleId'] ?? 0,
      solved: json['solved'] ?? false,
      timeSpent: json['timeSpent'] ?? 0,
      xpEarned: json['xp'] ?? 0,
      coinsEarned: json['coins'] ?? 0,
    );
  }
}
