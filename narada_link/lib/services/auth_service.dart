import 'dart:convert';
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
      final user = await _googleSignIn.signIn();
      if (user == null) return null;

      final auth = await user.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);

      // 🔥 Firebase ID Token
      final firebaseToken =
          await userCredential.user?.getIdToken();

      if (firebaseToken == null) return null;

      // 🔥 Backend call
      final response = await ApiService.login(firebaseToken);

      if (response != null) {
        final jwt = response['token'];

        // 💾 Save JWT locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt", jwt);

        return response;
      }

      return null;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  /// 🔓 Logout
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt");
  }

  /// 🔁 Get saved JWT
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt");
  }
}