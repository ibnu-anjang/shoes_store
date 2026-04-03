import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'provider/cartProvider.dart';
import 'provider/favoriteProvider.dart';
import 'screens/navBar.dart';
import 'screens/auth/login_screen.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check for existing token
  final String? token = await AuthService.getToken();
  
  runApp(MyApp(initialHome: const BottomNavBar(),));
}

class MyApp extends StatelessWidget {
  final Widget initialHome;
  const MyApp({super.key, required this.initialHome});

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
    home: initialHome,
  ),
  );
} 