import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoggedIn = false;
  bool needsUsername = false; // 🔥 NEW
  String? token;
  Map<String, dynamic>? user; // 🔥 NEW

  final AuthService _authService = AuthService();

  /// 🔐 Login
  Future<void> login() async {
    try {
      print("🚀 Starting login process...");

      final response = await _authService.signInWithGoogle();

      print("📡 Login response: $response");

      if (response != null && response['token'] != null) {
        token = response['token'];
        user = response['user'];

        print("🔐 JWT stored: $token");
        print("👤 User data: $user");

        // 🔥 Username check
        if (user?['username'] == null || user?['username'] == "") {
          needsUsername = true;
          isLoggedIn = false;

          print("⚠️ Username not set → go to UsernameScreen");
        } else {
          needsUsername = false;
          isLoggedIn = true;

          print("✅ Login complete → HomeScreen");
        }

        notifyListeners();
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

        // ⚠️ IMPORTANT:
        // yaha ideally backend se user fetch karna chahiye
        // abhi assume kar rahe hain login complete hai

        isLoggedIn = true;
        needsUsername = false;

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
      user = null;
      isLoggedIn = false;
      needsUsername = false;

      notifyListeners();

      print("✅ Logout successful");
    } catch (e) {
      print("🔥 Logout error: $e");
    }
  }
}