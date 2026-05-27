import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _soundEnabled = true;
  bool _pieceAnimation = true;
  bool _showMoveHints = true;
  bool _confirmMoves = false;
  bool _autoQueen = true;
  bool _enableChat = true;
  bool _enableNotifications = true;
  String _boardTheme = 'green';
  String _pieceTheme = 'default';
  bool _isDarkMode = true;

  bool get soundEnabled => _soundEnabled;
  bool get pieceAnimation => _pieceAnimation;
  bool get showMoveHints => _showMoveHints;
  bool get confirmMoves => _confirmMoves;
  bool get autoQueen => _autoQueen;
  bool get enableChat => _enableChat;
  bool get enableNotifications => _enableNotifications;
  String get boardTheme => _boardTheme;
  String get pieceTheme => _pieceTheme;
  bool get isDarkMode => _isDarkMode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _pieceAnimation = prefs.getBool('piece_animation') ?? true;
    _showMoveHints = prefs.getBool('show_move_hints') ?? true;
    _confirmMoves = prefs.getBool('confirm_moves') ?? false;
    _autoQueen = prefs.getBool('auto_queen') ?? true;
    _enableChat = prefs.getBool('enable_chat') ?? true;
    _enableNotifications = prefs.getBool('enable_notifications') ?? true;
    _boardTheme = prefs.getString('board_theme') ?? 'green';
    _pieceTheme = prefs.getString('piece_theme') ?? 'default';
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    notifyListeners();
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _saveSetting('sound_enabled', _soundEnabled);
    notifyListeners();
  }

  Future<void> togglePieceAnimation() async {
    _pieceAnimation = !_pieceAnimation;
    await _saveSetting('piece_animation', _pieceAnimation);
    notifyListeners();
  }

  Future<void> toggleMoveHints() async {
    _showMoveHints = !_showMoveHints;
    await _saveSetting('show_move_hints', _showMoveHints);
    notifyListeners();
  }

  Future<void> toggleConfirmMoves() async {
    _confirmMoves = !_confirmMoves;
    await _saveSetting('confirm_moves', _confirmMoves);
    notifyListeners();
  }

  Future<void> toggleAutoQueen() async {
    _autoQueen = !_autoQueen;
    await _saveSetting('auto_queen', _autoQueen);
    notifyListeners();
  }

  Future<void> toggleChat() async {
    _enableChat = !_enableChat;
    await _saveSetting('enable_chat', _enableChat);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _enableNotifications = !_enableNotifications;
    await _saveSetting('enable_notifications', _enableNotifications);
    notifyListeners();
  }

  Future<void> setBoardTheme(String theme) async {
    _boardTheme = theme;
    await _saveSetting('board_theme', theme);
    notifyListeners();
  }

  Future<void> setPieceTheme(String theme) async {
    _pieceTheme = theme;
    await _saveSetting('piece_theme', theme);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _saveSetting('is_dark_mode', _isDarkMode);
    notifyListeners();
  }
}
