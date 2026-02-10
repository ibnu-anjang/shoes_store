import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/services/auth_service.dart';

class ProductService {
  static const String _cacheKey = 'cached_products';
  static bool isOfflineData = false;

  static Future<List<Product>> getProducts() async {
    try {
      // 1. Attempt to fetch from API with Timeout (Anti-Freeze)
      final response = await http
          .get(Uri.parse('${AuthService.baseUrl}/products'))
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // 2. Silent Caching: Save to memory in background
        _cacheData(response.body);
        
        isOfflineData = false;
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      print("DEBUG: Fetch failed, using cache. Error: $e");
    }

    // 3. Offline Mode: Load from Cache
    final cached = await _loadCache();
    if (cached != null) {
      isOfflineData = true;
      final List<dynamic> data = jsonDecode(cached);
      return data.map((json) => Product.fromJson(json)).toList();
    }

    // 4. Fallback: If no cache and no internet, use static mock data from productModel.dart
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
