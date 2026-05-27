import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  bool _isGuest = false;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isGuest => _isGuest;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<bool> register(String email, String password, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post('auth/register', {
        'email': email,
        'password': password,
        'username': username,
      });

      _user = UserModel.fromJson(data['user']);
      _token = data['token'];
      _isGuest = false;
      await _saveSession();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post('auth/login', {
        'email': email,
        'password': password,
      });

      _user = UserModel.fromJson(data['user']);
      _token = data['token'];
      _isGuest = false;
      await _saveSession();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginAsGuest() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post('auth/guest', {});
      _user = UserModel.fromJson(data['user']);
      _token = data['token'];
      _isGuest = true;
      await _saveSession();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkUsername(String username) async {
    try {
      final data = await ApiService.post('auth/check-username', {'username': username});
      return data['available'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString('auth_token', _token!);
    if (_user != null) await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    await prefs.setBool('is_guest', _isGuest);
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _isGuest = prefs.getBool('is_guest') ?? false;

    if (_token != null) {
      try {
        final data = await ApiService.get('auth/me');
        _user = UserModel.fromJson(data);
        notifyListeners();
        return true;
      } catch (e) {
        await logout();
        return false;
      }
    }
    return false;
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    _isGuest = false;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('is_guest');
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final data = await ApiService.put('profile/${_user!.uid}', updates);
      _user = UserModel.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final data = await ApiService.get('profile/${_user!.uid}');
      _user = UserModel.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
