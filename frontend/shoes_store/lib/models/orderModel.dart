import 'package:shoes_store/models/cartItem.dart';

enum OrderStatus {
  menungguVerifikasi,
  diproses,
  dalamPengiriman,
  diterima,
}

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double ongkir;
  final double total;
  final String alamat;
  final String nomorWA;
  final DateTime tanggal;
  OrderStatus status;
  String? resi;
  final String? paymentMethod;

  Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.ongkir,
    required this.total,
    required this.alamat,
    required this.nomorWA,
    required this.tanggal,
    this.status = OrderStatus.diproses,
    this.resi,
    this.paymentMethod,
  });

  String get statusText {
    switch (status) {
      case OrderStatus.menungguVerifikasi:
        return 'Menunggu Pembayaran';
      case OrderStatus.diproses:
        return 'Pesanan Diproses';
      case OrderStatus.dalamPengiriman:
        return 'Dalam Pengiriman';
      case OrderStatus.diterima:
        return 'Paket Diterima';
    }
  }

  String get statusEmoji {
    switch (status) {
      case OrderStatus.menungguVerifikasi:
        return '⏳';
      case OrderStatus.diproses:
        return '📦';
      case OrderStatus.dalamPengiriman:
        return '🚚';
      case OrderStatus.diterima:
        return '✅';
    }
  }
}
