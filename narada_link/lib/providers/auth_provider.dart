import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoggedIn = false;
  String? token;

  final AuthService _authService = AuthService();

  /// 🔐 Login
  Future<void> login() async {
    final response = await _authService.signInWithGoogle();

    if (response != null) {
      token = response['token']; // JWT
      isLoggedIn = true;
      notifyListeners();
    }
  }

  /// 🔁 Auto Login (app start pe)
  Future<void> checkLogin() async {
    final savedToken = await _authService.getToken();

    if (savedToken != null) {
      token = savedToken;
      isLoggedIn = true;
      notifyListeners();
    }
  }

  /// 🔓 Logout
  Future<void> logout() async {
    await _authService.logout();

    token = null;
    isLoggedIn = false;
    notifyListeners();
  }
}