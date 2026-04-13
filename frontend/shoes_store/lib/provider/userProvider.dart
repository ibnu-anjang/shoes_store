import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/services/apiService.dart';

class UserProvider extends ChangeNotifier {
  String _userId = "user_shoes_unique_123"; // ID Permanen untuk demo
  String _userName = "Shoes Store User";
  String _email = "shoesstore@example.com";
  String _password = "password123"; // Default for demo
  String? _profileImagePath;

  String get userId => _userId;
  String get userName => _userName;
  String get email => _email;
  String get password => _password;
  String? get profileImagePath => _profileImagePath;

  static UserProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<UserProvider>(context, listen: listen);
  }

  UserProvider() {
    loadUser();
  }

  Future<void> loadUser() async {
    final profile = await ApiService.getUserProfile();
    if (profile != null) {
      _userId = profile['id'].toString();
      _userName = profile['username'] ?? _userName;
      _email = profile['email'] ?? _email;
      _profileImagePath = profile['profile_image'] != null 
          ? ApiService.normalizeImage(profile['profile_image'].toString())
          : null;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? name, String? email, String? password, String? imagePath}) async {
    try {
      final updatedData = await ApiService.updateUserProfile(
        name: name ?? _userName,
        email: email ?? _email,
        password: password,
        imagePath: imagePath,
      );
      
      final user = updatedData['user'];
      if (user != null) {
        _userId = user['id'].toString();
        _userName = user['username'] ?? _userName;
        _email = user['email'] ?? _email;
        if (user['profile_image'] != null) {
          _profileImagePath = ApiService.normalizeImage(user['profile_image'].toString());
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal update profile: $e");
      rethrow;
    }
  }

  /// Wipe semua data saat logout agar tidak bocor ke akun berikutnya
  void clearUser() {
    _userId = "";
    _userName = "Shoes Store User";
    _email = "";
    _profileImagePath = null;
    notifyListeners();
  }
}

