import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoes_store/constant.dart';

class AuthService {
  /// URL backend yang dipakai oleh seluruh ApiService.
  /// Sumber kebenaran ada di constant.dart → kBaseUrl
  static String get baseUrl => kBaseUrl;
  static const String _tokenKey = 'access_token';
  static const String _usernameKey = 'username';

  static Future<void> saveAuthData(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      debugPrint('Login response: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      return {'detail': 'Error connecting to server: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'detail': 'Error connecting to server: $e'};
    }
  }

  static String getFriendlyMessage(Map<String, dynamic> result) {
    if (!result.containsKey('detail')) {
      return 'Terjadi kesalahan sistem, silakan coba lagi.';
    }

    final rawDetail = result['detail'];

    // Pydantic v2 validation errors: detail berupa List of errors
    if (rawDetail is List && rawDetail.isNotEmpty) {
      final firstError = rawDetail.first;
      if (firstError is Map && firstError.containsKey('msg')) {
        final msg = firstError['msg'].toString();
        // Hapus prefix "Value error, " dari Pydantic
        return msg.replaceFirst(RegExp(r'^Value error,\s*'), '');
      }
    }

    final detail = rawDetail.toString().toLowerCase();
    if (detail.contains('terdaftar') || detail.contains('already registered') || detail.contains('already exists')) {
      if (detail.contains('username')) return 'Username ini sudah dipakai orang lain!';
      if (detail.contains('email')) return 'Email ini sudah terdaftar. Pakai email lain ya!';
      return 'Data ini sudah terdaftar di sistem kami.';
    }
    if (detail.contains('password salah') || detail.contains('invalid credentials')) {
      return 'Username atau password salah. Cek lagi ya.';
    }
    if (detail.contains('error connecting')) {
      return 'Gagal konek ke server. Pastikan internet aktif atau server sedang berjalan.';
    }

    return rawDetail.toString();
  }
}
