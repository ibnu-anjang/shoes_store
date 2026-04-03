import 'package:flutter/material.dart';
import 'package:shoes_store/screens/auth/login_screen.dart';
import 'package:shoes_store/screens/cart/cartScreen.dart';
import 'package:shoes_store/screens/favorite/favorite.dart';
import 'package:shoes_store/screens/home/homeScreen.dart';
import 'package:shoes_store/screens/profile/profile.dart';
import '../services/auth_service.dart';
import 'chatbot/chatBotScreen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int currentIndex = 0;
  
  // ABSOLUTELY NO EXTERNAL WIDGETS HERE
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
        title: const Text("Shoes Store - Debug Mode"),
        actions: [
          IconButton(
            onPressed: () async {
              // Clear token for logout
              await AuthService.clearToken();
              
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (value) => setState(() => currentIndex = value),
        type: BottomNavigationBarType.fixed,
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
