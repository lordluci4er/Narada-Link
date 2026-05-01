import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoggedIn = false;
  bool needsUsername = false;

  String? token; // 🔥 JWT
  Map<String, dynamic>? user;

  final AuthService _authService = AuthService();

  /// 🔐 LOGIN
  Future<void> login() async {
    try {
      print("🚀 Starting login process...");

      final response = await _authService.signInWithGoogle();

      print("📡 Login response: $response");

      if (response == null || response['token'] == null) {
        print("❌ Login failed: No token");
        return;
      }

      token = response['token'];
      user = response['user'];

      print("🔐 JWT stored: $token");
      print("👤 User data: $user");

      /// 🔔 SAVE FCM TOKEN
      await _initAndSaveFcmToken();

      /// 🔥 Username check
      if (user?['username'] == null || user?['username'] == "") {
        needsUsername = true;
        isLoggedIn = false;

        print("⚠️ Username not set → UsernameScreen");
      } else {
        needsUsername = false;
        isLoggedIn = true;

        print("✅ Login complete → MainScreen");
      }

      notifyListeners();

    } catch (e) {
      print("🔥 Login Provider Error: $e");
    }
  }

  /// 🔁 AUTO LOGIN
  Future<void> checkLogin() async {
    try {
      print("🔁 Checking saved login...");

      final savedToken = await _authService.getToken();

      print("📦 Saved token: $savedToken");

      if (savedToken == null) {
        print("⚠️ No saved token found");
        return;
      }

      token = savedToken;

      /// 🔔 Update FCM token on app open
      await _initAndSaveFcmToken();

      isLoggedIn = true;
      needsUsername = false;

      notifyListeners();

      print("✅ Auto login success");

    } catch (e) {
      print("🔥 Auto login error: $e");
    }
  }

  /// 🔔 COMMON FCM INIT + SAVE (DRY CODE 🔥)
  Future<void> _initAndSaveFcmToken() async {
    try {
      final fcmToken = await NotificationService.init();

      if (fcmToken != null && token != null) {
        await ApiService.saveFcmToken(fcmToken, token!);
        print("✅ FCM token saved/updated");
      }
    } catch (e) {
      print("⚠️ FCM setup error: $e");
    }
  }

  /// 🔓 LOGOUT
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