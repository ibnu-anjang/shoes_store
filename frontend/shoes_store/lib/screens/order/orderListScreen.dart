import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import '../../widgets/smartImage.dart';
import 'package:shoes_store/models/orderModel.dart';
import 'package:shoes_store/provider/orderProvider.dart';
import 'package:shoes_store/screens/detail/detailScreen.dart';
import 'package:shoes_store/screens/order/orderDetailScreen.dart';
import 'package:shoes_store/screens/cart/checkoutScreen.dart';
import 'package:shoes_store/screens/review/reviewHelper.dart';

class OrderListScreen extends StatefulWidget {
  final int initialIndex;
  const OrderListScreen({super.key, this.initialIndex = 0});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = OrderProvider.of(context);
    final orders = provider.orders;

    return DefaultTabController(
      length: 5,
      initialIndex: widget.initialIndex,
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
            tabAlignment: TabAlignment.start,
            labelColor: kprimaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kprimaryColor,
            indicatorWeight: 3,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
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
            _buildRefreshable(context, provider, _buildOrderList(context, orders)),
            _buildRefreshable(context, provider,
              _buildOrderList(context, orders.where((o) => o.status == OrderStatus.menungguVerifikasi).toList())),
            _buildRefreshable(context, provider,
              _buildOrderList(context, orders.where((o) => o.status == OrderStatus.diproses).toList())),
            _buildRefreshable(context, provider,
              _buildOrderList(context, orders.where((o) => o.status == OrderStatus.dalamPengiriman).toList())),
            _buildRefreshable(context, provider,
              _buildOrderList(context, orders.where((o) => o.status == OrderStatus.diterima).toList())),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshable(BuildContext context, OrderProvider provider, Widget child) {
    return RefreshIndicator(
      onRefresh: () => provider.loadOrders(),
      color: kprimaryColor,
      child: child,
    );
  }

  Widget _buildOrderList(
    BuildContext context,
    List<Order> filteredOrders,
  ) {
    if (filteredOrders.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 20),
                Text(
                  'Belum ada pesanan',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tarik ke bawah untuk refresh',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(context, order);
      },
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Order order,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  _buildStatusChip(order),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Items preview
              ...order.items
                  .take(1)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailScreen(product: item.product),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SmartImage(
                                url: item.product.image,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Size ${item.selectedSize} • x${item.quantity}',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatRupiah(item.totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

              if (order.items.length > 1)
                Center(
                  child: Text(
                    'Lihat ${order.items.length - 1} produk lainnya',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(order.tanggal),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Total: ',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Text(
                        formatRupiah(order.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kprimaryColor,
                        ),
                      ),
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
                      // BUTTON BERI REVIEW (hanya jika ada item belum direview)
                      if (!order.isReviewed)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => openReviewPicker(context, order),
                            icon: const Icon(Icons.star_border, size: 16, color: Colors.white),
                            label: const Text(
                              'Beri Review',
                              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kprimaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      // SUDAH DIREVIEW LABEL
                      if (order.isReviewed)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade600, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  'Sudah Direview',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      // BELI LAGI BUTTON — langsung ke checkout
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  items: order.items,
                                  isBuyNow: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                          label: const Text(
                            'Beli Lagi',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kprimaryColor,
                            side: const BorderSide(color: kprimaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (order.status == OrderStatus.menungguVerifikasi)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_top, color: Colors.orange.shade700, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Menunggu Validasi Pembayaran',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              if (order.status == OrderStatus.diproses)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Colors.blue.shade700, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Menunggu Toko Mengirim Barang',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                        ),
                      ],
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
      case OrderStatus.dibatalkan:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${order.statusEmoji} ${order.statusText}',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
