import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/models/productModel.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cart = [];
  List<CartItem> get cart => _cart;

  /// Ongkir flat rate
  static const double flatOngkir = 10.0;

  void addToCart(Product product, String size, Color color, int qty) {
    // Cek apakah produk dengan size & color yang sama sudah ada
    final existingIndex = _cart.indexWhere(
      (item) =>
          item.product.title == product.title &&
          item.selectedSize == size &&
          item.selectedColor == color,
    );

    if (existingIndex != -1) {
      _cart[existingIndex].quantity += qty;
    } else {
      _cart.add(CartItem(
        product: product,
        selectedSize: size,
        selectedColor: color,
        quantity: qty,
      ));
    }
    notifyListeners();
  }

  void toggleSelection(int index) {
    _cart[index].isSelected = !_cart[index].isSelected;
    notifyListeners();
  }

  void selectAll(bool selected) {
    for (var item in _cart) {
      item.isSelected = selected;
    }
    notifyListeners();
  }

  void removeAt(int index) {
    _cart.removeAt(index);
    notifyListeners();
  }

  void removeSelected() {
    _cart.removeWhere((item) => item.isSelected);
    notifyListeners();
  }

  void incrementQtn(int index) {
    _cart[index].quantity++;
    notifyListeners();
  }

  void decrementQtn(int index) {
    if (_cart[index].quantity <= 1) return;
    _cart[index].quantity--;
    notifyListeners();
  }

  double subtotalPrice() {
    double total = 0.0;
    for (CartItem item in _cart) {
      if (item.isSelected) {
        total += item.totalPrice;
      }
    }
    return total;
  }

  double totalPrice() {
    double subtotal = subtotalPrice();
    if (subtotal == 0) return 0.0;
    return subtotal + flatOngkir;
  }

  int get selectedCount {
    return _cart.where((item) => item.isSelected).length;
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void updateItem(int index, String newSize, Color newColor) {
    if (index < 0 || index >= _cart.length) return;

    final product = _cart[index].product;
    final quantity = _cart[index].quantity;
    final isSelected = _cart[index].isSelected;

    // 1. Hapus item lama
    _cart.removeAt(index);

    // 2. Gunakan addToCart untuk menambahkan spesifikasi baru (otomatis handle merge)
    // Note: We'll manually handle selection restore after add
    addToCart(product, newSize, newColor, quantity);
    
    // Find the item again and restore selection if needed
    final newIdx = _cart.indexWhere(
      (item) => item.product.title == product.title && 
                 item.selectedSize == newSize && 
                 item.selectedColor == newColor
    );
    if (newIdx != -1) {
      _cart[newIdx].isSelected = isSelected;
    }

    notifyListeners();
  }

  static CartProvider of(
    BuildContext context, {
    bool listen = true,
  }) {
    return Provider.of<CartProvider>(
      context,
      listen: listen,
    );
  }
}
