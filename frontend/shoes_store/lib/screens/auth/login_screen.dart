import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/services/auth_service.dart';
import 'package:shoes_store/screens/navBar.dart';
import 'package:shoes_store/screens/auth/register_screen.dart';
import 'package:shoes_store/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    try {
      print('DEBUG: onPress Login started');
      
      // Close keyboard before everything
      FocusScope.of(context).unfocus();
      
      if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      setState(() => _isLoading = true);
      print('DEBUG: Loading spinner active. Calling AuthService.login...');

      final result = await AuthService.login(
        _usernameController.text,
        _passwordController.text,
      );
      print('DEBUG: AuthService.login returned result');

      if (result.containsKey('access_token')) {
        print('DEBUG: Login Success.');
        
        // Save token for persistent login
        await AuthService.saveToken(result['access_token']);
        
        if (mounted) setState(() => _isLoading = false);
        
        // Navigation Global Fix: Use the state-less navigator to avoid context deadlocks
        print('DEBUG: Triggering Global Navigator...');
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
          (route) => false,
        );
      } else {
        if (mounted) setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.getFriendlyMessage(result)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('DEBUG_ERROR: $e');
      if (mounted) setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100),
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
                'Login to your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 50),
              _buildTextField(_usernameController, 'Username', Icons.person),
              const SizedBox(height: 20),
              _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kprimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: kprimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // ============================================================
              // TODO: HAPUS BAGIAN INI SAAT DEPLOY KE PRODUCTION
              // Fitur "Masuk Tanpa Login" hanya untuk testing frontend
              // tanpa backend. Hapus dari baris ini sampai komentar 
              // "AKHIR BAGIAN DEMO" di bawah.
              // ============================================================
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      'atau',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),
              // Tombol Mode Offline
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Simpan token dummy supaya LoginCheck di checkout lolos
                    await AuthService.saveToken('offline-demo-token');
                    if (!mounted) return;
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const BottomNavBar()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.wifi_off, color: kprimaryColor),
                  label: const Text(
                    'Masuk Tanpa Login (Demo)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kprimaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kprimaryColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              // ============================================================
              // AKHIR BAGIAN DEMO — Hapus sampai sini saat deploy
              // ============================================================
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: kcontentColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          icon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
