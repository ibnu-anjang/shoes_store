import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/screens/auth/login_screen.dart';
import 'package:shoes_store/screens/cart/cartScreen.dart';
import 'package:shoes_store/screens/favorite/favorite.dart';
import 'package:shoes_store/screens/home/homeScreen.dart';
import 'package:shoes_store/screens/profile/profile.dart';
import 'package:shoes_store/screens/order/orderListScreen.dart';
import '../services/auth_service.dart';
import 'chatbot/chatBotScreen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int currentIndex = 0;
  
  final List<Widget> screens = [
    const HomeScreen(),
    const Favorite(),
    const ChatbotScreen(),
    const CartScreen(),
    const Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Shoes Store",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        actions: [
          // Pesanan Saya
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderListScreen()),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.black),
            tooltip: 'Pesanan Saya',
          ),
          // Logout
          IconButton(
            onPressed: () async {
              await AuthService.clearToken();
              
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (value) => setState(() => currentIndex = value),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kprimaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorite"),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "ChatBot"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
