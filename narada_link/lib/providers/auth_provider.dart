import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoggedIn = false;
  String? token;

  final AuthService _authService = AuthService();

  /// 🔐 Login
  Future<void> login() async {
    try {
      print("🚀 Starting login process...");

      final response = await _authService.signInWithGoogle();

      print("📡 Login response: $response");

      if (response != null && response['token'] != null) {
        token = response['token'];

        print("🔐 JWT stored: $token");

        isLoggedIn = true;
        notifyListeners();

        print("✅ Login successful → HomeScreen");
      } else {
        print("❌ Login failed: Response null or token missing");
      }
    } catch (e) {
      print("🔥 Login Provider Error: $e");
    }
  }

  /// 🔁 Auto Login (app start pe)
  Future<void> checkLogin() async {
    try {
      print("🔁 Checking saved login...");

      final savedToken = await _authService.getToken();

      print("📦 Saved token: $savedToken");

      if (savedToken != null) {
        token = savedToken;
        isLoggedIn = true;
        notifyListeners();

        print("✅ Auto login success");
      } else {
        print("⚠️ No saved token found");
      }
    } catch (e) {
      print("🔥 Auto login error: $e");
    }
  }

  /// 🔓 Logout
  Future<void> logout() async {
    try {
      print("🚪 Logging out...");

      await _authService.logout();

      token = null;
      isLoggedIn = false;
      notifyListeners();

      print("✅ Logout successful");
    } catch (e) {
      print("🔥 Logout error: $e");
    }
  }
}