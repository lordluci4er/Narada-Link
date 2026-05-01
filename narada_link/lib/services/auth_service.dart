import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthService {
  final _googleSignIn = GoogleSignIn();
  final _auth = FirebaseAuth.instance;

  /// 🔐 Google Login + Backend Login
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print("🚀 Starting Google Sign-In...");

      final user = await _googleSignIn.signIn();

      if (user == null) {
        print("❌ User cancelled Google Sign-In");
        return null;
      }

      print("✅ Google user selected: ${user.email}");

      final auth = await user.authentication;

      print("🔑 Google Auth Tokens received");

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);

      print("🔥 Firebase login successful");

      // 🔥 Firebase ID Token
      final firebaseToken =
          await userCredential.user?.getIdToken();

      print("📦 Firebase Token: $firebaseToken");

      if (firebaseToken == null) {
        print("❌ Firebase token is null");
        return null;
      }

      // 🔥 Backend call
      print("🌐 Calling backend API...");

      final response = await ApiService.login(firebaseToken);

      print("📡 Backend Response: $response");

      if (response != null) {
        final jwt = response['token'];

        print("🔐 JWT Received: $jwt");

        // 💾 Save JWT locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt", jwt);

        print("💾 JWT saved locally");

        return response;
      }

      print("❌ Backend returned null");
      return null;
    } catch (e) {
      print("🔥 Login Error: $e");
      return null;
    }
  }

  /// 🔓 Logout
  Future<void> logout() async {
    print("🚪 Logging out...");

    await _googleSignIn.signOut();
    await _auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt");

    print("✅ Logout complete");
  }

  /// 🔁 Get saved JWT
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt");

    print("🔁 Retrieved JWT: $token");

    return token;
  }
}