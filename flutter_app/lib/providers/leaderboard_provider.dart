import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  List<LeaderboardEntry> _entries = [];
  String _selectedTimeControl = 'rapid';
  bool _isLoading = false;
  int? _userRank;
  int _totalPlayers = 0;

  List<LeaderboardEntry> get entries => _entries;
  String get selectedTimeControl => _selectedTimeControl;
  bool get isLoading => _isLoading;
  int? get userRank => _userRank;
  int get totalPlayers => _totalPlayers;

  void setTimeControl(String tc) {
    _selectedTimeControl = tc;
    loadLeaderboard();
  }

  Future<void> loadLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('leaderboard/$_selectedTimeControl');
      _entries = (data as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboardAround(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('leaderboard/$_selectedTimeControl/around/$uid');
      _entries = (data['around'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
      _userRank = data['rank'];
      _totalPlayers = data['totalPlayers'] ?? 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
