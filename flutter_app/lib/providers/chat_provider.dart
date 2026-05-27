import 'package:flutter/foundation.dart';
import '../models/game_model.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _globalMessages = [];
  List<ChatMessage> _gameMessages = [];
  Map<String, List<ChatMessage>> _privateMessages = {};
  bool _isLoading = false;
  bool _isTyping = false;

  List<ChatMessage> get globalMessages => _globalMessages;
  List<ChatMessage> get gameMessages => _gameMessages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;

  void addGlobalMessage(ChatMessage message) {
    _globalMessages.add(message);
    if (_globalMessages.length > 100) {
      _globalMessages.removeAt(0);
    }
    notifyListeners();
  }

  void addGameMessage(ChatMessage message) {
    _gameMessages.add(message);
    if (_gameMessages.length > 50) {
      _gameMessages.removeAt(0);
    }
    notifyListeners();
  }

  void addPrivateMessage(String chatId, ChatMessage message) {
    _privateMessages.putIfAbsent(chatId, () => []);
    _privateMessages[chatId]!.add(message);
    if (_privateMessages[chatId]!.length > 100) {
      _privateMessages[chatId]!.removeAt(0);
    }
    notifyListeners();
  }

  List<ChatMessage> getPrivateMessages(String chatId) {
    return _privateMessages[chatId] ?? [];
  }

  Future<void> loadGlobalHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('chat/global');
      _globalMessages = (data as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList()
          .reversed
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPrivateHistory(String uid1, String uid2) async {
    try {
      final data = await ApiService.get('chat/private/$uid1/$uid2');
      final sorted = [uid1, uid2]..sort();
      final chatId = '${sorted[0]}_${sorted[1]}';
      _privateMessages[chatId] = (data as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList();
      notifyListeners();
    } catch (e) {}
  }

  void setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  void clearGameMessages() {
    _gameMessages.clear();
    notifyListeners();
  }

  void clearAll() {
    _globalMessages.clear();
    _gameMessages.clear();
    _privateMessages.clear();
    notifyListeners();
  }
}

extension SortedList on List<String> {
  String joinFromSorted(String other) {
    final sorted = [this[0], other]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
