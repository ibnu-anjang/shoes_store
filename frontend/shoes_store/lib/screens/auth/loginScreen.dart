import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/services/authService.dart';
import 'package:shoes_store/screens/navBar.dart';
import 'package:shoes_store/screens/auth/registerScreen.dart';
import 'package:shoes_store/main.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/provider/userProvider.dart';
import 'package:shoes_store/provider/favoriteProvider.dart';
import 'package:shoes_store/provider/orderProvider.dart';
import 'package:shoes_store/provider/addressProvider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result.containsKey('access_token')) {
        await AuthService.saveAuthData(
          result['access_token'],
          result['username'] ?? _usernameController.text.trim(),
        );

        // Refresh SEMUA provider agar data tampil langsung setelah login
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).loadUser();
          Provider.of<FavoriteProvider>(context, listen: false).loadFavorites();
          Provider.of<OrderProvider>(context, listen: false).loadOrders();
          Provider.of<AddressProvider>(context, listen: false).fetchAddresses();
        }

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
          (route) => false,
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.getFriendlyMessage(result)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal terhubung ke server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login ke akun kamu',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 50),

                  // Username field
                  _buildTextFormField(
                    controller: _usernameController,
                    hint: 'Username atau Email',
                    icon: Icons.person_outline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Username tidak boleh kosong';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  _buildTextFormField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                      return null;
                    },
                  ),
                  const SizedBox(height: 50),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kprimaryColor,
                        disabledBackgroundColor: kprimaryColor.withAlpha(150),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Belum punya akun? "),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: kprimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: kcontentColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          icon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      ),
    );
  }
}
