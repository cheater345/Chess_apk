import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api.dart';

class SocketProvider extends ChangeNotifier {
  io.Socket? _socket;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  io.Socket? get socket => _socket;
  bool get isConnected => _isConnected;

  void connect(String uid, String username) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(ApiConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'forceNew': true,
      'reconnection': true,
      'reconnectionAttempts': _maxReconnectAttempts,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
    });

    _socket!.on('connect', (_) {
      _isConnected = true;
      _reconnectAttempts = 0;
      _socket!.emit('user:online', {'uid': uid, 'username': username});
      notifyListeners();
    });

    _socket!.on('disconnect', (_) {
      _isConnected = false;
      notifyListeners();
    });

    _socket!.on('reconnect_attempt', (_) {
      _reconnectAttempts++;
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        _socket!.disconnect();
      }
    });

    _socket!.on('connect_error', (data) {
      _isConnected = false;
      notifyListeners();
    });

    _socket!.on('reconnect', (_) {
      _isConnected = true;
      _socket!.emit('user:online', {'uid': uid, 'username': username});
      notifyListeners();
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.clearListeners();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, (data) => handler(data));
  }

  void off(String event) {
    _socket?.off(event);
  }

  void joinRoom(String room) {
    _socket?.emit('join:room', room);
  }

  void leaveRoom(String room) {
    _socket?.emit('leave:room', room);
  }

  void emitWithAck(String event, dynamic data) {
    _socket?.emitWithAck(event, data);
  }
}
