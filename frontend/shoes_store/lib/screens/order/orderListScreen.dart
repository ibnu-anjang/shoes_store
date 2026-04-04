import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/orderModel.dart';
import 'package:shoes_store/provider/cartProvider.dart';
import 'package:shoes_store/provider/orderProvider.dart';
import 'package:shoes_store/provider/reviewProvider.dart';
import 'package:shoes_store/provider/userProvider.dart';
import 'package:shoes_store/screens/detail/detailScreen.dart';
import 'package:shoes_store/screens/order/orderDetailScreen.dart';
import 'package:shoes_store/screens/review/reviewScreen.dart';

class OrderListScreen extends StatelessWidget {
  final int initialIndex;
  const OrderListScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final provider = OrderProvider.of(context);
    final orders = provider.orders;

    return DefaultTabController(
      length: 5,
      initialIndex: initialIndex,
      child: Scaffold(
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
            'Pesanan Saya',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            labelColor: kprimaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kprimaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "Semua"),
              Tab(text: "Menunggu"),
              Tab(text: "Diproses"),
              Tab(text: "Dikirim"),
              Tab(text: "Selesai"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(context, orders, provider),
            _buildOrderList(context, orders.where((o) => o.status == OrderStatus.menungguVerifikasi).toList(), provider),
            _buildOrderList(context, orders.where((o) => o.status == OrderStatus.diproses).toList(), provider),
            _buildOrderList(context, orders.where((o) => o.status == OrderStatus.dalamPengiriman).toList(), provider),
            _buildOrderList(context, orders.where((o) => o.status == OrderStatus.diterima).toList(), provider),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Order> filteredOrders, OrderProvider provider) {
    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              'Belum ada pesanan',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(context, order, provider);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, OrderProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                  _buildStatusChip(order),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Items preview
              ...order.items.take(1).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DetailScreen(product: item.product)),
                        );
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(item.product.image, width: 50, height: 50, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('Size ${item.selectedSize} • x${item.quantity}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('\$${item.totalPrice.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  )),

              if (order.items.length > 1)
                Center(
                  child: Text(
                    'Lihat ${order.items.length - 1} produk lainnya',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDate(order.tanggal), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  Row(
                    children: [
                      const Text('Total: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text('\$${order.total.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kprimaryColor)),
                    ],
                  ),
                ],
              ),

              // ACTIONS SECTION (For Selesai/Received)
              if (order.status == OrderStatus.diterima)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    children: [
                      // BELI LAGI BUTTON
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final cartProvider =
                                Provider.of<CartProvider>(context, listen: false);
                            for (var item in order.items) {
                              cartProvider.addToCart(
                                item.product,
                                item.selectedSize,
                                item.selectedColor,
                                item.quantity,
                              );
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Produk berhasil ditambah ke keranjang!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Beli Lagi', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kprimaryColor,
                            side: const BorderSide(color: kprimaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // REVIEW BUTTON (DYNAMIC)
                      Expanded(
                        child: Consumer2<ReviewProvider, UserProvider>(
                          builder: (context, reviewProvider, userProvider, child) {
                            final reviews = reviewProvider.getProductReviews(order.items.first.product.title);
                            // Find the specific review by this user
                            final existingReview = reviews.cast<ReviewItem?>().firstWhere(
                              (r) => r?.userId == userProvider.userId,
                              orElse: () => null,
                            );

                            return ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewScreen(
                                      order: order,
                                      existingReview: existingReview,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kprimaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                existingReview != null ? 'Edit Review' : 'Beri Review',
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // TOMBOL SIMULASI (ADMIN)
              if (order.status == OrderStatus.menungguVerifikasi || order.status == OrderStatus.diproses)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (order.status == OrderStatus.menungguVerifikasi) {
                          provider.updateStatus(order.id, OrderStatus.diproses);
                        } else {
                          provider.updateStatus(order.id, OrderStatus.dalamPengiriman);
                        }
                      },
                      icon: Icon(
                        order.status == OrderStatus.menungguVerifikasi ? Icons.verified_user : Icons.local_shipping,
                        size: 16,
                      ),
                      label: Text(
                        order.status == OrderStatus.menungguVerifikasi 
                          ? 'Simulasi: Verifikasi Pembayaran' 
                          : 'Simulasi: Kirim Paket',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kprimaryColor,
                        side: const BorderSide(color: kprimaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Order order) {
    Color bgColor;
    Color textColor;

    switch (order.status) {
      case OrderStatus.menungguVerifikasi:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        break;
      case OrderStatus.diproses:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case OrderStatus.dalamPengiriman:
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        break;
      case OrderStatus.diterima:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(
        '${order.statusEmoji} ${order.statusText}',
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
