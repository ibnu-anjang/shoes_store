import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/services/apiService.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<Product> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FavoriteProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await ApiService.getFavorites();
      _favorites.clear();
      _favorites.addAll(list);
    } catch (e) {
      _error = "Gagal memuat favorit";
      debugPrint("Error loading favorites: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle favorit dengan optimistic update + rollback jika API gagal.
  void toggleFavorite(Product product) async {
    final wasInFavorites = _favorites.any((e) => e.id == product.id);

    // Optimistic update
    if (wasInFavorites) {
      _favorites.removeWhere((e) => e.id == product.id);
    } else {
      _favorites.add(product);
    }
    notifyListeners();

    try {
      await ApiService.toggleFavorite(product.id);
    } catch (e) {
      // Rollback jika gagal
      if (wasInFavorites) {
        _favorites.add(product);
      } else {
        _favorites.removeWhere((f) => f.id == product.id);
      }
      debugPrint("Gagal toggle favorit, rollback: $e");
      notifyListeners();
    }
  }

  bool isExist(Product product) {
    return _favorites.any((e) => e.id == product.id);
  }

  /// Wipe semua data saat logout agar tidak bocor ke akun berikutnya.
  void clearFavorites() {
    _favorites.clear();
    _error = null;
    notifyListeners();
  }

  static FavoriteProvider of(BuildContext context, {bool listen = false}) {
    return Provider.of<FavoriteProvider>(context, listen: listen);
  }
}
