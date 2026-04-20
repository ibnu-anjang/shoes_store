import 'package:flutter/material.dart';
import 'dart:ui';
import 'provider/cartProvider.dart';
import 'provider/favoriteProvider.dart';
import 'provider/addressProvider.dart';
import 'provider/userProvider.dart';
import 'provider/orderProvider.dart';
import 'provider/reviewProvider.dart';
import 'screens/navBar.dart';
import 'screens/auth/loginScreen.dart';
import 'package:provider/provider.dart';

import 'services/authService.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Globals error handler to prevent sudden force quit (Shopee-like resilience)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("Flutter Error Caught: ${details.exception}");
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("Async Error Caught: $error");
    return true; // prevent unexpected app crash
  };

  // Check for existing token (graceful — tidak crash kalau backend mati)
  Widget initialHome;
  try {
    final String? token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      initialHome = const BottomNavBar();
    } else {
      initialHome = const LoginScreen();
    }
  } catch (e) {
    // Kalau error baca token, langsung ke Login
    initialHome = const LoginScreen();
  }

  runApp(MyApp(initialHome: initialHome));
}

class MyApp extends StatelessWidget {
  final Widget initialHome;
  const MyApp({super.key, required this.initialHome});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ChangeNotifierProvider(create: (_) => OrderProvider()),
      ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ChangeNotifierProvider(create: (_) => AddressProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
    ],
    child: MaterialApp(
      title: 'Shoes Store',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      theme: ThemeData(
        // textTheme: GoogleFonts.mulishTextTheme(),
      ),
      home: initialHome,
    ),
  );
}
