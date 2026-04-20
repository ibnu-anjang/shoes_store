import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/orderModel.dart';
import 'package:shoes_store/provider/cartProvider.dart';
import 'package:shoes_store/provider/favoriteProvider.dart';
import 'package:shoes_store/provider/orderProvider.dart';
import 'package:shoes_store/provider/addressProvider.dart';
import 'package:shoes_store/provider/reviewProvider.dart';
import 'package:shoes_store/provider/userProvider.dart';
import 'package:shoes_store/screens/profile/address/addressListScreen.dart';
import 'package:shoes_store/screens/profile/editProfileScreen.dart';
import 'package:shoes_store/screens/order/orderListScreen.dart';
import 'package:shoes_store/screens/auth/loginScreen.dart';
import 'package:shoes_store/screens/favorite/favoriteScreen.dart';
import 'package:shoes_store/screens/chatbot/chatBotScreen.dart';
import 'package:shoes_store/services/authService.dart';
import 'package:shoes_store/services/productService.dart';
import 'package:shoes_store/widgets/fullScreenViewer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _refresh() async {
    await Future.wait([
      UserProvider.of(context).loadUser(),
      OrderProvider.of(context).loadOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = OrderProvider.of(context, listen: true);
    final userProvider = UserProvider.of(context, listen: true);

    return Scaffold(
      backgroundColor: kcontentColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: kprimaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // HEADER SECTION
              _buildHeader(context, userProvider),
              const SizedBox(height: 20),

              // ORDER STATUS DASHBOARD
              _buildOrderDashboard(context, orderProvider),
              const SizedBox(height: 20),

              // MENU SECTION
              _buildMenuSection(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProvider user) {
    final hasImage = user.profileImagePath != null && user.profileImagePath!.isNotEmpty;
    ImageProvider? profileImage;
    if (hasImage) {
      if (user.profileImagePath!.startsWith('http')) {
        profileImage = NetworkImage(user.profileImagePath!);
      } else {
        profileImage = FileImage(File(user.profileImagePath!));
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (hasImage) {
                FullScreenViewer.show(context, user.profileImagePath!);
              }
            },
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: profileImage,
              child: !hasImage ? const Icon(Icons.person, size: 45, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: kprimaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text("Premium Member", style: TextStyle(color: kprimaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const EditProfileScreen())), 
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDashboard(BuildContext context, OrderProvider provider) {
    // Tab index: 0=Semua, 1=Menunggu Bayar, 2=Validasi, 3=Diproses, 4=Dikirim, 5=Selesai
    final unpaidCount      = provider.orders.where((o) => o.status == OrderStatus.unpaid).length;
    final validasiCount    = provider.orders.where((o) => o.status == OrderStatus.menungguVerifikasi).length;
    final processingCount  = provider.orders.where((o) => o.status == OrderStatus.diproses).length;
    final shippingCount    = provider.orders.where((o) => o.status == OrderStatus.dalamPengiriman).length;
    final reviewCount      = provider.orders.where((o) => o.status == OrderStatus.diterima && !o.isReviewed).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pesanan Saya", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const OrderListScreen(initialIndex: 0))),
                child: const Row(
                  children: [
                    Text("Riwayat", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _orderDashboardItem(context, Icons.payment_outlined,      "Belum Bayar", unpaidCount,     1),
              _orderDashboardItem(context, Icons.hourglass_top_outlined, "Validasi",   validasiCount,   2),
              _orderDashboardItem(context, Icons.inventory_2_outlined,  "Dikemas",     processingCount, 3),
              _orderDashboardItem(context, Icons.local_shipping_outlined,"Dikirim",    shippingCount,   4),
              _orderDashboardItem(context, Icons.star_outline,          "Ulasan",      reviewCount,     5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderDashboardItem(BuildContext context, IconData icon, String label, int count, int targetIndex) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => OrderListScreen(initialIndex: targetIndex))),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: Colors.black87, size: 28),
              if (count > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _menuTile(context, Icons.location_on_outlined, "Alamat Saya", "Kelola alamat pengiriman", () {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddressListScreen()));
          }),
          _menuTile(context, Icons.favorite_outline, "Favorit Saya", "Daftar sepatu yang disukai", () {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => const FavoriteScreen()));
          }),
          _menuTile(context, Icons.headset_mic_outlined, "Bantuan", "Pusat bantuan & Chatbot", () {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AssistantChatScreen()));
          }),
          _menuTile(context, Icons.verified_user_outlined, "Keamanan Akun", "Username, Email & Password", () {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => const EditProfileScreen()));
          }),
          const Divider(indent: 20, endIndent: 20, height: 20),
          _menuTile(context, Icons.logout, "Keluar", "Keluar dari akun anda", () => _handleLogout(context), isLogout: true),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: kcontentColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: isLogout ? Colors.red : kprimaryColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLogout ? Colors.red : Colors.black)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  void _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // tutup dialog dulu

              // 1. Hapus token dari storage
              await AuthService.clearToken();

              // 2. Wipe semua provider state agar data akun lama tidak bocor
              if (context.mounted) {
                context.read<CartProvider>().clearCart();
                context.read<OrderProvider>().clearOrders();
                context.read<FavoriteProvider>().clearFavorites();
                context.read<AddressProvider>().clearAddresses();
                context.read<ReviewProvider>().clearReviews();
                context.read<UserProvider>().clearUser();
              }

              // 3. Invalidate product cache agar stok fresh saat login berikutnya
              await ProductService.invalidateCache();

              // 4. Navigasi ke Login, hapus semua route sebelumnya
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}