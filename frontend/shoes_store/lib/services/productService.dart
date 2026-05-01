import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/services/authService.dart';

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

  /// Hapus cache produk agar saat login berikutnya data benar-benar fresh dari API
  static Future<void> invalidateCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    debugPrint("DEBUG: Product cache invalidated");
  }

  static Future<Map<String, dynamic>> searchProducts({
    String? q,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('${AuthService.baseUrl}/products/search').replace(queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (category != null && category != 'All') 'category': category,
      'page': page.toString(),
      'limit': limit.toString(),
    });
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'items': (data['items'] as List).map((j) => Product.fromJson(j)).toList(),
          'total': data['total'] as int,
          'page': data['page'] as int,
          'pages': data['pages'] as int,
        };
      }
    } catch (e) {
      debugPrint("DEBUG: searchProducts error: $e");
    }
    return {'items': <Product>[], 'total': 0, 'page': 1, 'pages': 1};
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('${AuthService.baseUrl}/categories'))
          .timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      }
    } catch (e) {
      debugPrint("DEBUG: getCategories error: $e");
    }
    return [];
  }
}
