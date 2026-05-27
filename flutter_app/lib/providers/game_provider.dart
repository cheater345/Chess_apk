import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_model.dart';
import '../services/api_service.dart';
import '../config/api.dart';

class GameProvider extends ChangeNotifier {
  GameModel? _currentGame;
  List<GameModel> _gameHistory = [];
  List<GameModel> _liveGames = [];
  bool _isInQueue = false;
  String? _queueTimeControl;
  int _queuePosition = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _clockTimer;
  Map<String, double> _clocks = {};

  GameModel? get currentGame => _currentGame;
  List<GameModel> get gameHistory => _gameHistory;
  List<GameModel> get liveGames => _liveGames;
  bool get isInQueue => _isInQueue;
  String? get queueTimeControl => _queueTimeControl;
  int get queuePosition => _queuePosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, double> get clocks => _clocks;

  void setGame(GameModel game) {
    _currentGame = game;
    _clocks = {
      'white': game.white.clock,
      'black': game.black.clock,
    };
    notifyListeners();
  }

  void joinQueue(String timeControl) {
    _isInQueue = true;
    _queueTimeControl = timeControl;
    _queuePosition = 0;
    notifyListeners();
  }

  void leaveQueue() {
    _isInQueue = false;
    _queueTimeControl = null;
    _queuePosition = 0;
    notifyListeners();
  }

  void updateQueuePosition(int position) {
    _queuePosition = position;
    notifyListeners();
  }

  void addMove(Map<String, dynamic> moveData) {
    if (_currentGame == null) return;

    _currentGame!.moves.add(MoveModel.fromJson(moveData));
    _currentGame!.moveCount++;
    _currentGame!.currentTurn = _currentGame!.currentTurn == 'w' ? 'b' : 'w';

    if (moveData['clock'] != null) {
      _clocks['white'] = moveData['clock']['white'].toDouble();
      _clocks['black'] = moveData['clock']['black'].toDouble();
    }

    notifyListeners();
  }

  void updateClocks(Map<String, dynamic> clockData) {
    _clocks['white'] = (clockData['white'] ?? 0).toDouble();
    _clocks['black'] = (clockData['black'] ?? 0).toDouble();
    notifyListeners();
  }

  void startClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentGame != null && _currentGame!.isActive) {
        final color = _currentGame!.currentTurn == 'w' ? 'white' : 'black';
        if (_clocks[color] != null && _clocks[color]! > 0) {
          _clocks[color] = _clocks[color]! - 1;
          notifyListeners();
        }
      }
    });
  }

  void stopClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  void endGame(Map<String, dynamic> result) {
    if (_currentGame == null) return;
    _currentGame!.status = 'completed';
    _currentGame!.result = result['result'];
    _currentGame!.winner = result['winner'];
    _currentGame!.winReason = result['reason'];
    _currentGame!.eloChanges = result['eloChanges'];
    stopClockTimer();
    notifyListeners();
  }

  Future<void> loadGameHistory(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('games/history/$uid');
      _gameHistory = (data as List).map((g) => GameModel.fromJson(g)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLiveGames() async {
    try {
      final data = await ApiService.get('games/live/list');
      _liveGames = (data as List).map((g) => GameModel.fromJson(g)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void resetGame() {
    _currentGame = null;
    _clocks = {};
    stopClockTimer();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}
