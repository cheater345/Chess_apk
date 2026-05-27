class UserModel {
  final String uid;
  final String? email;
  final String username;
  final String displayName;
  final String photoURL;
  final bool isGuest;
  final bool isOnline;
  final bool isBanned;
  final int coins;
  final int xp;
  final int level;
  final Map<String, dynamic> elo;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> settings;
  final List<String> achievements;
  final List<String> badges;
  final Map<String, dynamic>? dailyReward;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final String? bio;

  UserModel({
    required this.uid,
    this.email,
    required this.username,
    this.displayName = '',
    this.photoURL = '',
    this.isGuest = false,
    this.isOnline = false,
    this.isBanned = false,
    this.coins = 0,
    this.xp = 0,
    this.level = 1,
    this.elo = const {},
    this.stats = const {},
    this.settings = const {},
    this.achievements = const [],
    this.badges = const [],
    this.dailyReward,
    this.createdAt,
    this.lastLogin,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'],
      username: json['username'] ?? 'Unknown',
      displayName: json['displayName'] ?? json['username'] ?? 'Unknown',
      photoURL: json['photoURL'] ?? '',
      isGuest: json['isGuest'] ?? false,
      isOnline: json['isOnline'] ?? false,
      isBanned: json['isBanned'] ?? false,
      coins: json['coins'] ?? 0,
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      elo: json['elo'] ?? {},
      stats: json['stats'] ?? {},
      settings: json['settings'] ?? {},
      achievements: List<String>.from(json['achievements'] ?? []),
      badges: List<String>.from(json['badges'] ?? []),
      dailyReward: json['dailyReward'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : null,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin'].toString()) : null,
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'username': username,
    'displayName': displayName,
    'photoURL': photoURL,
    'isGuest': isGuest,
    'isOnline': isOnline,
    'isBanned': isBanned,
    'coins': coins,
    'xp': xp,
    'level': level,
    'elo': elo,
    'stats': stats,
    'settings': settings,
    'achievements': achievements,
    'badges': badges,
    'dailyReward': dailyReward,
    'bio': bio,
  };

  int getRating(String timeControl) {
    return elo[timeControl] ?? 1200;
  }

  String get rank {
    final rating = getRating('rapid');
    if (rating >= 2200) return 'Grandmaster';
    if (rating >= 2000) return 'Master';
    if (rating >= 1800) return 'Diamond';
    if (rating >= 1600) return 'Platinum';
    if (rating >= 1400) return 'Gold';
    if (rating >= 1200) return 'Silver';
    return 'Bronze';
  }

  int get winRate {
    final played = (stats['gamesPlayed'] ?? 0) as int;
    if (played == 0) return 0;
    final wins = (stats['wins'] ?? 0) as int;
    return (wins / played * 100).round();
  }

  String get initials {
    if (displayName.isNotEmpty) {
      return displayName.split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    }
    return username[0].toUpperCase();
  }
}

class LeaderboardEntry {
  final int rank;
  final String id;
  final String username;
  final String displayName;
  final String photoURL;
  final int elo;
  final int level;

  LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.username,
    required this.displayName,
    this.photoURL = '',
    required this.elo,
    this.level = 1,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? json['username'] ?? '',
      photoURL: json['photoURL'] ?? '',
      elo: json['elo'] ?? 1200,
      level: json['level'] ?? 1,
    );
  }
}
