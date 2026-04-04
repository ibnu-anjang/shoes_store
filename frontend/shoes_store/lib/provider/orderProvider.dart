import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/models/orderModel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoes_store/constant.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  List<Order> get orders => _orders;
  String _currentUsername = "Shoes Store User";

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
  }) async {
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    final order = Order(
      id: orderId,
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

    // Alur Skakmat: Kirim data pesanan ke backend kita yang baru
    try {
      final orderData = {
        "id": orderId,
        "total": total,
        "status": status.toString().split('.').last,
        "items": items.map((e) => {
          "product_id": e.product.id,
          "quantity": e.quantity,
          "selected_size": int.tryParse(e.selectedSize) ?? 0,
          "selected_color": e.selectedColor,
          "price": e.product.price
        }).toList()
      };

      final response = await http.post(
        Uri.parse("$kBaseUrl/orders?username=$_currentUsername"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        _orders.insert(0, order);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Gagal simpan pesanan: $e");
      // Fallback lokal jika demo offline
      _orders.insert(0, order);
      notifyListeners();
    }
  }

  // Load riwayat pesanan (DIPANGGIL SAAT AWAL)
  Future<void> fetchOrders(String username) async {
    _currentUsername = username;
    try {
      final response = await http.get(Uri.parse("$kBaseUrl/orders?username=$username"));
      if (response.statusCode == 200) {
        // Logic untuk parse dari backend ke model Order lokal bisa ditambahkan programmer nantinya
        // Tapi setidaknya data sudah bisa ditarik balik kalau Anda butuh demo
        debugPrint("Data pesanan berhasil ditarik!");
      }
    } catch (e) {
      debugPrint("Gagal load riwayat: $e");
    }
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

  void markAsReviewed(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].isReviewed = true;
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
