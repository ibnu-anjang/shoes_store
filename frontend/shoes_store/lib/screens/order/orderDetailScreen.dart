import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/orderModel.dart';
import 'package:shoes_store/provider/orderProvider.dart';
import 'package:shoes_store/screens/detail/detailScreen.dart';
import 'package:shoes_store/screens/review/reviewScreen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final provider = OrderProvider.of(context);
    // Re-fetch order from provider to get latest status
    final currentOrder = provider.orders.firstWhere(
      (o) => o.id == order.id,
      orElse: () => order,
    );

    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Status Timeline
            _buildStatusTimeline(currentOrder),
            const SizedBox(height: 15),

            // INTRUKSI PEMBAYARAN (Baru)
            if (currentOrder.status == OrderStatus.menungguVerifikasi && currentOrder.paymentMethod != 'COD') ...[
              _buildPaymentInstructions(currentOrder),
              const SizedBox(height: 15),
            ],

            // Resi (jika ada)
            if (currentOrder.resi != null) _buildResiCard(currentOrder),

            // Items
            _buildItemsCard(context, currentOrder),
            const SizedBox(height: 15),

            // Alamat
            _buildAlamatCard(currentOrder),
            const SizedBox(height: 15),

            // Ringkasan Harga
            _buildPriceCard(currentOrder),
            const SizedBox(height: 15),

            // Konfirmasi Verifikasi (SIMULASI ADMIN)
            if (currentOrder.status == OrderStatus.menungguVerifikasi)
              _buildSimulateVerifyButton(context, currentOrder, provider),

            // Konfirmasi Terima (jika status = dalam pengiriman)
            if (currentOrder.status == OrderStatus.dalamPengiriman)
              _buildConfirmButton(context, currentOrder, provider),

            // Tombol Review (jika status = diterima)
            if (currentOrder.status == OrderStatus.diterima)
              _buildReviewButton(context, currentOrder),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: order.status == OrderStatus.menungguVerifikasi ? Border.all(color: Colors.orange.shade300, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Pesanan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (order.status == OrderStatus.menungguVerifikasi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                  child: Text('Menunggu Pembayaran', style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimelineStep(
            icon: Icons.payment,
            title: 'Pesanan Dibuat',
            subtitle: order.status == OrderStatus.menungguVerifikasi 
              ? 'Silakan selesaikan pembayaranmu' 
              : 'Pembayaran telah dikonfirmasi',
            isActive: true,
            isCompleted: order.status != OrderStatus.menungguVerifikasi,
          ),
          _buildTimelineConnector(
              order.status != OrderStatus.menungguVerifikasi),
          _buildTimelineStep(
            icon: Icons.receipt_long,
            title: 'Pesanan Diproses',
            subtitle: 'Penjual sedang memproses pesananmu',
            isActive: order.status != OrderStatus.menungguVerifikasi,
            isCompleted: order.status == OrderStatus.dalamPengiriman || order.status == OrderStatus.diterima,
          ),
          _buildTimelineConnector(
              order.status == OrderStatus.dalamPengiriman || order.status == OrderStatus.diterima),
          _buildTimelineStep(
            icon: Icons.local_shipping,
            title: 'Dalam Pengiriman',
            subtitle: order.resi != null
                ? 'No. Resi: ${order.resi}'
                : 'Menunggu pengiriman',
            isActive: order.status == OrderStatus.dalamPengiriman ||
                order.status == OrderStatus.diterima,
            isCompleted: order.status == OrderStatus.diterima,
          ),
          _buildTimelineConnector(
              order.status == OrderStatus.diterima),
          _buildTimelineStep(
            icon: Icons.check_circle,
            title: 'Paket Diterima',
            subtitle: 'Pesanan telah diterima',
            isActive: order.status == OrderStatus.diterima,
            isCompleted: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                order.paymentMethod == 'QRIS' ? 'Scan QRIS Pembayaran' : 'Detail Rekening Transfer',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (order.paymentMethod == 'QRIS')
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Image.asset(
                'assets/images/qris_payment.png',
                width: 200,
                height: 200,
                errorBuilder: (ctx, err, st) => const Icon(Icons.qr_code_2, size: 100, color: Colors.grey),
              ),
            )
          else ...[
            _instructionRow('Bank', 'BCA (Modern Shoes Store)'),
            _instructionRow('No. Rekening', '7712 8890 1234'),
            _instructionRow('Atas Nama', 'PT Shoes Store Modern'),
            _instructionRow('Total Bayar', '\$${order.total.toStringAsFixed(1)}'),
          ],
          const SizedBox(height: 15),
          const Text(
            '*Pesanan akan diproses otomatis setelah Anda melakukan pembayaran dan dikonfirmasi oleh sistem.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.blue, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _instructionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900)),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    bool isLast = false,
  }) {
    final color = isActive ? kprimaryColor : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? kprimaryColor.withOpacity(0.1) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isActive ? Colors.black : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 19),
      width: 2,
      height: 30,
      color: isActive ? kprimaryColor : Colors.grey.shade300,
    );
  }

  Widget _buildResiCard(Order order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nomor Resi',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
              ),
              Text(
                order.resi!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produk Dipesan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(product: item.product),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          item.product.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: kcontentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: item.selectedColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 1),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Size ${item.selectedSize}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'x${item.quantity}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSimulateVerifyButton(
      BuildContext context, Order order, OrderProvider provider) {
    return Container(
      width: double.infinity,
      height: 55,
      margin: const EdgeInsets.only(bottom: 15),
      child: ElevatedButton.icon(
        onPressed: () {
          provider.updateStatus(order.id, OrderStatus.diproses);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran Diversifikasi! (Simulasi Admin)'),
              backgroundColor: Colors.blue,
            ),
          );
        },
        icon: const Icon(Icons.verified_user, color: Colors.white),
        label: const Text(
          'Simulasi: Verifikasi Pembayaran',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kprimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildAlamatCard(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alamat Pengiriman',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  color: kprimaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.alamat,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  color: kprimaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                order.nomorWA,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', '\$${order.subtotal.toStringAsFixed(1)}'),
          const SizedBox(height: 8),
          _priceRow('Ongkos Kirim', '\$${order.ongkir.toStringAsFixed(1)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '\$${order.total.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: kprimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildConfirmButton(
      BuildContext context, Order order, OrderProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Konfirmasi Penerimaan'),
              content: const Text(
                  'Apakah kamu sudah menerima paket ini?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Belum'),
                ),
                ElevatedButton(
                  onPressed: () {
                    provider.confirmReceived(order.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paket dikonfirmasi diterima! 🎉'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kprimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ya, Sudah Terima',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        label: const Text(
          'Konfirmasi Paket Diterima',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewButton(BuildContext context, Order order) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewScreen(order: order),
            ),
          );
        },
        icon: const Icon(Icons.star_outline, color: Colors.white),
        label: const Text(
          'Beri Rating & Review',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kprimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
