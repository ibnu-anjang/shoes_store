import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/services/auth_service.dart';

class ProductService {
  static const String _cacheKey = 'cached_products';
  static bool isOfflineData = false;

  static Future<List<Product>> getProducts() async {
    try {
      final response = await http
          .get(Uri.parse('${AuthService.baseUrl}/products'))
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          _cacheData(response.body);
          isOfflineData = false;
          debugPrint("DEBUG: Products loaded from API (${data.length})");
          return data.map((json) => Product.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint("DEBUG: API Fetch failed ($e), trying cache...");
    }

    final cached = await _loadCache();
    if (cached != null) {
      final List<dynamic> data = jsonDecode(cached);
      if (data.isNotEmpty) {
        isOfflineData = true;
        debugPrint("DEBUG: Products loaded from Cache (${data.length})");
        return data.map((json) => Product.fromJson(json)).toList();
      }
    }

    debugPrint("DEBUG: No API/Cache found or data empty, using static Fallback data");
    return products;
  }

  static Future<void> _cacheData(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonString);
  }

  static Future<String?> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKey);
  }
}
