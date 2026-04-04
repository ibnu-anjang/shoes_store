import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/models/orderModel.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  List<Order> get orders => _orders;

  /// Buat pesanan baru dari cart items
  void addOrder({
    required List<CartItem> items,
    required double subtotal,
    required double ongkir,
    required double total,
    required String alamat,
    required String nomorWA,
    String? paymentMethod,
    OrderStatus status = OrderStatus.diproses,
  }) {
    final order = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      items: items.map((e) => CartItem(
        product: e.product,
        selectedSize: e.selectedSize,
        selectedColor: e.selectedColor,
        quantity: e.quantity,
      )).toList(),
      subtotal: subtotal,
      ongkir: ongkir,
      total: total,
      alamat: alamat,
      nomorWA: nomorWA,
      tanggal: DateTime.now(),
      status: status,
      paymentMethod: paymentMethod,
    );
    _orders.insert(0, order); // Pesanan terbaru di atas
    notifyListeners();
  }

  /// Simulasi update status oleh penjual/kurir
  void updateStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = newStatus;
      if (newStatus == OrderStatus.dalamPengiriman) {
        _orders[index].resi = 'JNE-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      }
      notifyListeners();
    }
  }

  /// User konfirmasi paket diterima
  void confirmReceived(String orderId) {
    updateStatus(orderId, OrderStatus.diterima);
  }

  static OrderProvider of(
    BuildContext context, {
    bool listen = true,
  }) {
    return Provider.of<OrderProvider>(
      context,
      listen: listen,
    );
  }
}
