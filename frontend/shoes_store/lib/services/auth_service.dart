import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.111.48:8000';
  static const String _tokenKey = 'access_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
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
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
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
    if (result.containsKey('detail')) {
      final detail = result['detail'].toString().toLowerCase();
      if (detail.contains('already registered') || detail.contains('already exists')) {
        if (detail.contains('username')) return 'Waduh, Username ini sudah dipake orang lain, Cuy!';
        if (detail.contains('email')) return 'Email ini sudah terdaftar. Pake email lain ya!';
        return 'Data ini sudah terdaftar di sistem kami.';
      }
      if (detail.contains('invalid credentials') || detail.contains('password salah')) {
        return 'Username atau password salah, Cuy! Cek lagi ya.';
      }
      if (detail.contains('error connecting')) {
        return 'Gagal konek ke server. Pastikan internetmu aktif atau server lagi jalan.';
      }
      return result['detail'];
    }
    return 'Terjadi kesalahan sistem, silakan coba lagi.';
  }
}
