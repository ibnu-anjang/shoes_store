import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  void updateProfile({String? name, String? email, String? password, String? imagePath}) {
    if (name != null) _userName = name;
    if (email != null) _email = email;
    if (password != null) _password = password;
    if (imagePath != null) _profileImagePath = imagePath;
    notifyListeners();
  }
}
