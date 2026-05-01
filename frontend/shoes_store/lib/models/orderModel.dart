import 'package:shoes_store/models/cartItem.dart';

enum OrderStatus {
  unpaid,             // UNPAID — belum upload bukti pembayaran
  menungguVerifikasi, // VERIFYING — sudah upload, menunggu validasi admin
  diproses,           // PAID
  dalamPengiriman,    // SHIPPED
  diterima,           // DELIVERED / COMPLETED
  dibatalkan,         // CANCELLED
}

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double ongkir;
  final double total;
  final int uniqueCode;
  final String alamat;
  final String nomorWA;
  final DateTime tanggal;
  OrderStatus status;
  String? resi;
  final String? paymentMethod;
  final bool hasPaymentProof;

  Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.ongkir,
    required this.total,
    this.uniqueCode = 0,
    required this.alamat,
    required this.nomorWA,
    required this.tanggal,
    this.status = OrderStatus.diproses,
    this.resi,
    this.paymentMethod,
    this.hasPaymentProof = false,
  });

  /// Order dianggap sudah direview jika semua item sudah direview.
  bool get isReviewed => items.isNotEmpty && items.every((i) => i.isReviewed);

  String get statusText {
    switch (status) {
      case OrderStatus.unpaid:
        return 'Menunggu Pembayaran';
      case OrderStatus.menungguVerifikasi:
        return 'Menunggu Validasi';
      case OrderStatus.diproses:
        return 'Pesanan Diproses';
      case OrderStatus.dalamPengiriman:
        return 'Dalam Pengiriman';
      case OrderStatus.diterima:
        return 'Paket Diterima';
      case OrderStatus.dibatalkan:
        return 'Pesanan Dibatalkan';
    }
  }

  String get statusEmoji {
    switch (status) {
      case OrderStatus.unpaid:
        return '💳';
      case OrderStatus.menungguVerifikasi:
        return '⏳';
      case OrderStatus.diproses:
        return '📦';
      case OrderStatus.dalamPengiriman:
        return '🚚';
      case OrderStatus.diterima:
        return '✅';
      case OrderStatus.dibatalkan:
        return '❌';
    }
  }
}
