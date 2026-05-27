import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static String? _token;

  static Future<Map<String, String>> _headers() async {
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
    }
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  static String _buildUrl(String endpoint) {
    return '${ApiConfig.apiV1}/$endpoint';
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http
        .get(Uri.parse(_buildUrl(endpoint)), headers: await _headers())
        .timeout(ApiConfig.connectTimeout);

    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse(_buildUrl(endpoint)),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.connectTimeout);

    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http
        .put(
          Uri.parse(_buildUrl(endpoint)),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.connectTimeout);

    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final response = await http
        .delete(Uri.parse(_buildUrl(endpoint)), headers: await _headers())
        .timeout(ApiConfig.connectTimeout);

    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (response.statusCode == 401) {
      _token = null;
    }

    throw ApiException(
      body['error'] ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }

  static void setToken(String? token) {
    _token = token;
  }
}
