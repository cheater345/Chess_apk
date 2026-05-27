import 'package:flutter/foundation.dart';
import '../models/puzzle_model.dart';
import '../services/api_service.dart';

class PuzzleProvider extends ChangeNotifier {
  PuzzleModel? _currentPuzzle;
  PuzzleModel? _dailyPuzzle;
  List<PuzzleModel> _puzzles = [];
  bool _isLoading = false;
  int _currentMoveIndex = 0;
  bool _isSolved = false;
  int _score = 0;
  int _streak = 0;

  PuzzleModel? get currentPuzzle => _currentPuzzle;
  PuzzleModel? get dailyPuzzle => _dailyPuzzle;
  List<PuzzleModel> get puzzles => _puzzles;
  bool get isLoading => _isLoading;
  int get currentMoveIndex => _currentMoveIndex;
  bool get isSolved => _isSolved;
  int get score => _score;
  int get streak => _streak;

  Future<void> loadDailyPuzzle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('puzzles/daily');
      _dailyPuzzle = PuzzleModel.fromJson(data);
      _currentPuzzle = _dailyPuzzle;
      _currentMoveIndex = 0;
      _isSolved = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRandomPuzzle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('puzzles/random');
      _currentPuzzle = PuzzleModel.fromJson(data);
      _currentMoveIndex = 0;
      _isSolved = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPuzzlesByRating(int min, int max, {int count = 5}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('puzzles/by-rating?min=$min&max=$max&count=$count');
      _puzzles = (data as List).map((p) => PuzzleModel.fromJson(p)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool checkMove(String move) {
    if (_currentPuzzle == null || _isSolved) return false;

    final expectedMoves = _currentPuzzle!.moves;
    if (_currentMoveIndex >= expectedMoves.length) return false;

    final expected = expectedMoves[_currentMoveIndex];
    if (move.toLowerCase() == expected.toLowerCase()) {
      _currentMoveIndex++;
      if (_currentMoveIndex >= expectedMoves.length) {
        _isSolved = true;
        _score += 10 + _streak * 2;
        _streak++;
      }
      notifyListeners();
      return true;
    } else {
      _streak = 0;
      notifyListeners();
      return false;
    }
  }

  void skipPuzzle() {
    if (_currentPuzzle == null) return;
    _streak = 0;
    _currentMoveIndex = _currentPuzzle!.moves.length;
    _isSolved = false;
    notifyListeners();
  }

  void resetPuzzle() {
    _currentMoveIndex = 0;
    _isSolved = false;
    notifyListeners();
  }

  String get expectedMove {
    if (_currentPuzzle == null) return '';
    if (_currentMoveIndex >= _currentPuzzle!.moves.length) return '';
    return _currentPuzzle!.moves[_currentMoveIndex];
  }

  int get progress {
    if (_currentPuzzle == null) return 0;
    if (_currentPuzzle!.moves.isEmpty) return 0;
    return (_currentMoveIndex / _currentPuzzle!.moves.length * 100).round();
  }
}
