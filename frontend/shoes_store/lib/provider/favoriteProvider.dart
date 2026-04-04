import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/productModel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoriteProvider extends ChangeNotifier {
  final List<Product> _favorites = [];
  List<Product> get favorites => _favorites;
  String _currentUsername = "Shoes Store User"; // Ambil dari UserProvider aslinya nanti

  // Load favorit dari database saat start
  Future<void> fetchFavorites(String username) async {
    _currentUsername = username;
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:8000/favorites?username=$username"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _favorites.clear();
        _favorites.addAll(data.map((e) => Product.fromJson(e)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Gagal load favorit: $e");
    }
  }

  void toggleFavorite(Product product) async {
    // Alur Skakmat: Langsung tembak API Backend menggunakan ID yang baru kita buat
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/favorites?username=$_currentUsername"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"product_id": product.id}),
      );

      if (response.statusCode == 200) {
        if (_favorites.any((e) => e.id == product.id)) {
          _favorites.removeWhere((e) => e.id == product.id);
        } else {
          _favorites.add(product);
        }
        notifyListeners();
      }
    } catch (e) {
       // Fallback lokal jika backend sedang tidak terjangkau
       if (_favorites.any((e) => e.id == product.id)) {
         _favorites.removeWhere((e) => e.id == product.id);
       } else {
         _favorites.add(product);
       }
       notifyListeners();
    }
  }

  bool isExist(Product product) {
    return _favorites.any((e) => e.id == product.id);
  }

  static FavoriteProvider of(
    BuildContext context, {
    bool listen = true,
  }) {
    return Provider.of<FavoriteProvider>(
      context,
      listen: listen
    );
  }
}