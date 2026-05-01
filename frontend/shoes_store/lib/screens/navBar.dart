import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/provider/favoriteProvider.dart';
import 'package:shoes_store/provider/orderProvider.dart';
import 'package:shoes_store/provider/userProvider.dart';
import 'package:shoes_store/screens/cart/cartScreen.dart';
import 'package:shoes_store/screens/favorite/favoriteScreen.dart';
import 'package:shoes_store/screens/home/homeScreen.dart';
import 'package:shoes_store/screens/profile/profileScreen.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;
  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  final List<Widget> screens = [
    const HomeScreen(),
    const FavoriteScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  void _onTabTap(int value) {
    setState(() => currentIndex = value);
    if (!mounted) return;
    if (value == 1) {
      FavoriteProvider.of(context).loadFavorites();
    } else if (value == 3) {
      UserProvider.of(context).loadUser();
      OrderProvider.of(context).loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onTabTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kprimaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Favorit"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Keranjang"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
