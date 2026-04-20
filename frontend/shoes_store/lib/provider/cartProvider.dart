import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/services/apiService.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _cart = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const double flatOngkir = 0.0;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // Remote Sync: Ambil data keranjang dari server
  Future<void> fetchCart(List<Product> allProducts) async {
    _setLoading(true);
    _error = null;
    try {
      final remoteCart = await ApiService.getCart();
      if (remoteCart.containsKey('items')) {
        List items = remoteCart['items'];
        _cart = items.map((item) {
          final skuId = item['sku_id'];
          Product? product;
          ProductSku? sku;
          for (var p in allProducts) {
            final foundSku = p.skus.firstWhere(
              (s) => s.id == skuId,
              orElse: () => ProductSku(id: -1, variantName: '', price: 0, stockAvailable: 0),
            );
            if (foundSku.id != -1) {
              product = p;
              sku = foundSku;
              break;
            }
          }
          if (product != null && sku != null) {
            return CartItem(
              id: item['id'],
              product: product,
              sku: sku,
              color: item['color_hex'] != null ? hexToColor(item['color_hex']) : null,
              quantity: item['quantity'],
              isSelected: item['is_selected_for_checkout'] ?? true,
            );
          }
          return null;
        }).whereType<CartItem>().toList();
      }
    } catch (e) {
      _error = "Gagal memuat keranjang";
      debugPrint("Error fetching cart: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addToCartRemote(ProductSku sku, int qty, List<Product> allProducts, {Color? color}) async {
    try {
      final colorHex = color != null ? colorToHex(color) : null;
      await ApiService.addToCart(sku.id, qty, colorHex: colorHex);
      await fetchCart(allProducts);
    } catch (e) {
      rethrow;
    }
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

  Future<void> removeAt(int index, List<Product> allProducts) async {
    final item = _cart[index];
    if (item.id != null) {
      await ApiService.removeCartItem(item.id!);
    }
    await fetchCart(allProducts);
  }

  /// Tambah 1 quantity. Gunakan endpoint add (+1) agar server validasi stok.
  Future<void> incrementQtn(int index, List<Product> allProducts) async {
    try {
      await ApiService.addToCart(_cart[index].sku.id, 1);
      await fetchCart(allProducts);
    } catch (e) {
      debugPrint("Gagal increment qty: $e");
      rethrow;
    }
  }

  /// Kurangi 1 quantity. Pakai endpoint set-quantity agar tidak terhalang stock check.
  Future<void> decrementQtn(int index, List<Product> allProducts) async {
    if (_cart[index].quantity <= 1) return;
    final item = _cart[index];
    if (item.id == null) return;
    try {
      await ApiService.updateCartItemQuantity(item.id!, item.quantity - 1);
      await fetchCart(allProducts);
    } catch (e) {
      debugPrint("Gagal decrement qty: $e");
    }
  }

  double subtotalPrice() {
    double total = 0.0;
    for (CartItem item in _cart) {
      if (item.isSelected) total += item.totalPrice;
    }
    return total;
  }

  double totalPrice() {
    final subtotal = subtotalPrice();
    if (subtotal == 0) return 0.0;
    return subtotal + flatOngkir;
  }

  int get selectedCount => _cart.where((item) => item.isSelected).length;

  void clearCart() {
    _cart.clear();
    _error = null;
    notifyListeners();
  }

  static CartProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<CartProvider>(context, listen: listen);
  }
}
