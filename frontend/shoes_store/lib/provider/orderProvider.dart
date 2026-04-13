import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/models/orderModel.dart';
import 'package:shoes_store/services/apiService.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  OrderProvider() {
    loadOrders();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await ApiService.getOrders();
      _orders.clear();
      _orders.addAll(list);
    } catch (e) {
      _error = "Gagal memuat pesanan";
      debugPrint("Error loading orders: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Checkout untuk user saat ini.
  Future<String> checkout({
    required List<CartItem> items,
    required String address,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await ApiService.checkoutRemote(items, address, phone);
      await loadOrders();
      return result['id'];
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update status order (dipakai customer untuk konfirmasi terima barang).
  Future<void> updateStatus(String orderId, OrderStatus newStatus) async {
    _error = null;
    String statusStr;
    switch (newStatus) {
      case OrderStatus.menungguVerifikasi:
        statusStr = 'VERIFYING';
      case OrderStatus.diproses:
        statusStr = 'PAID';
      case OrderStatus.dalamPengiriman:
        statusStr = 'SHIPPED';
      case OrderStatus.diterima:
        statusStr = 'DELIVERED';
      case OrderStatus.dibatalkan:
        statusStr = 'CANCELLED';
    }

    try {
      await ApiService.updateOrderStatus(orderId, statusStr);
      await loadOrders();
    } catch (e) {
      _error = "Gagal update status";
      debugPrint("Error updating order status: $e");
      notifyListeners();
      rethrow;
    }
  }

  void markAsReviewed(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].isReviewed = true;
      notifyListeners();
    }
  }

  Future<void> confirmReceived(String orderId) async {
    try {
      await ApiService.confirmOrderReceived(orderId);
      await loadOrders();
    } catch (e) {
      _error = "Gagal konfirmasi terima pesanan";
      debugPrint("Error confirming received: $e");
      notifyListeners();
      rethrow;
    }
  }

  /// Wipe semua data saat logout agar tidak bocor ke akun berikutnya.
  void clearOrders() {
    _orders.clear();
    _error = null;
    notifyListeners();
  }

  static OrderProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<OrderProvider>(context, listen: listen);
  }
}
