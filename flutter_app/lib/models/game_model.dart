class GameModel {
  final String gameId;
  final GamePlayer white;
  final GamePlayer black;
  final String timeControl;
  final int initialTime;
  final int increment;
  String status;
  String? result;
  String? winner;
  String? winReason;
  List<MoveModel> moves;
  List<String> moveHistory;
  String fen;
  String currentTurn;
  bool isRated;
  bool isTournament;
  int moveCount;
  final DateTime? startTime;
  DateTime? endTime;
  Map<String, dynamic>? eloChanges;
  List<ChatMessage> chat;
  final String? inviteCode;

  GameModel({
    required this.gameId,
    required this.white,
    required this.black,
    required this.timeControl,
    this.initialTime = 600,
    this.increment = 5,
    this.status = 'active',
    this.result,
    this.winner,
    this.winReason,
    this.moves = const [],
    this.moveHistory = const [],
    this.fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    this.currentTurn = 'w',
    this.isRated = true,
    this.isTournament = false,
    this.moveCount = 0,
    this.startTime,
    this.endTime,
    this.eloChanges,
    this.chat = const [],
    this.inviteCode,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      gameId: json['gameId'] ?? '',
      white: GamePlayer.fromJson(json['players']?['white'] ?? {}),
      black: GamePlayer.fromJson(json['players']?['black'] ?? {}),
      timeControl: json['timeControl'] ?? 'rapid',
      initialTime: json['initialTime'] ?? 600,
      increment: json['increment'] ?? 5,
      status: json['status'] ?? 'active',
      result: json['result'],
      winner: json['winner'],
      winReason: json['winReason'],
      moves: (json['moves'] as List?)?.map((m) => MoveModel.fromJson(m)).toList() ?? [],
      moveHistory: List<String>.from(json['moveHistory'] ?? []),
      fen: json['fen'] ?? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      currentTurn: json['currentTurn'] ?? 'w',
      isRated: json['isRated'] ?? true,
      isTournament: json['isTournament'] ?? false,
      moveCount: json['moveCount'] ?? 0,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime'].toString()) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'].toString()) : null,
      eloChanges: json['eloChanges'],
      chat: (json['chat'] as List?)?.map((c) => ChatMessage.fromJson(c)).toList() ?? [],
      inviteCode: json['inviteCode'],
    );
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  String getPlayerColor(String uid) {
    if (white.uid == uid) return 'white';
    if (black.uid == uid) return 'black';
    return 'spectator';
  }

  bool isPlayer(String uid) => white.uid == uid || black.uid == uid;

  String getOpponentColor(String uid) {
    if (white.uid == uid) return 'black';
    return 'white';
  }

  String getOpponentUsername(String uid) {
    if (white.uid == uid) return black.username;
    return white.username;
  }

  GamePlayer getPlayer(String uid) {
    if (white.uid == uid) return white;
    return black;
  }

  GamePlayer getOpponent(String uid) {
    if (white.uid == uid) return black;
    return white;
  }
}

class GamePlayer {
  final String uid;
  final String username;
  final int elo;
  double clock;
  bool disconnected;

  GamePlayer({
    required this.uid,
    required this.username,
    this.elo = 1200,
    this.clock = 600,
    this.disconnected = false,
  });

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      uid: json['uid'] ?? '',
      username: json['username'] ?? 'Unknown',
      elo: json['elo'] ?? 1200,
      clock: (json['clock'] ?? 600).toDouble(),
      disconnected: json['disconnected'] ?? false,
    );
  }
}

class MoveModel {
  final String from;
  final String to;
  final String? promotion;
  final String notation;
  final String by;
  final int time;
  final String? classification;

  MoveModel({
    required this.from,
    required this.to,
    this.promotion,
    required this.notation,
    required this.by,
    this.time = 0,
    this.classification,
  });

  factory MoveModel.fromJson(Map<String, dynamic> json) {
    return MoveModel(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      promotion: json['promotion'],
      notation: json['notation'] ?? '${json['from']}-${json['to']}',
      by: json['by'] ?? '',
      time: json['time'] ?? 0,
      classification: json['classification'],
    );
  }

  int get moveNumber => 0;
}

class ChatMessage {
  final String uid;
  final String username;
  final String message;
  final int timestamp;

  ChatMessage({
    required this.uid,
    required this.username,
    required this.message,
    this.timestamp = 0,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp']?.millisecondsSinceEpoch ?? json['timestamp'] ?? 0,
    );
  }
}

class TimeControl {
  final String name;
  final int initial;
  final int increment;
  final String icon;

  const TimeControl({
    required this.name,
    required this.initial,
    required this.increment,
    required this.icon,
  });

  static const bullet = TimeControl(name: 'Bullet', initial: 60, increment: 0, icon: 'bolt');
  static const blitz = TimeControl(name: 'Blitz', initial: 300, increment: 3, icon: 'zap');
  static const rapid = TimeControl(name: 'Rapid', initial: 600, increment: 5, icon: 'clock');
  static const classical = TimeControl(name: 'Classical', initial: 1800, increment: 10, icon: 'hourglass');

  static const List<TimeControl> all = [bullet, blitz, rapid, classical];

  String get displayName => '$name ($initial|$increment)';
}
