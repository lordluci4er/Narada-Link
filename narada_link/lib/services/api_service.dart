import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "https://narada-link.onrender.com";

  /// 🔐 Google Login API
  static Future<Map<String, dynamic>?> login(String token) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/google"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"token": token}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 🆕 Set Username
  static Future<Map<String, dynamic>?> setUsername(
    String username,
    String jwt,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/users/set-username"),
        headers: {
          "Authorization": "Bearer $jwt",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"username": username}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 👤 Get Current User
  static Future<Map<String, dynamic>?> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/users/me"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 🔍 Search Users
  static Future<List> searchUsers(String query, String jwt) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/users/search?username=$query"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// 💬 Get Messages
  static Future<List> getMessages(String userId, String jwt) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/messages/$userId"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// 📤 Send Message
  static Future<bool> sendMessage(
    String receiverId,
    String text,
    String jwt,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/messages"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwt",
        },
        body: jsonEncode({
          "receiverId": receiverId,
          "text": text,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// 🔔 SAVE FCM TOKEN
  static Future<void> saveFcmToken(
    String fcmToken,
    String jwt,
  ) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/api/users/fcm-token"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwt",
        },
        body: jsonEncode({
          "token": fcmToken,
        }),
      );
    } catch (e) {
      // silent fail
    }
  }

  /// 💬 GET RECENT CHATS (🔥 NEW)
  static Future<List> getRecentChats(String jwt) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/messages/recent"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}