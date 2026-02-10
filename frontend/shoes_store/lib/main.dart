import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shoes_store/provider/cartProvider.dart';
import 'package:shoes_store/provider/favoriteProvider.dart';
import 'package:shoes_store/screens/navBar.dart';
import 'package:shoes_store/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => FavoriteProvider(),
      ),
    ],
  child: MaterialApp(
    navigatorKey: navigatorKey,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      // textTheme: GoogleFonts.mulishTextTheme(),
    ),
    home: const LoginScreen(),
  ),
  );
} 