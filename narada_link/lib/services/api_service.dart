import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "https://narada-link.onrender.com";

  /// 🔐 Google Login API
  static Future<Map<String, dynamic>?> login(String token) async {
    try {
      print("🌐 Sending login request to backend...");

      final response = await http
          .post(
            Uri.parse("$baseUrl/api/auth/google"),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({"token": token}),
          )
          .timeout(const Duration(seconds: 20));

      print("📡 Status Code: ${response.statusCode}");
      print("📡 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      print("❌ Login failed: ${response.body}");
      return null;
    } catch (e) {
      print("🔥 API Error (Login): $e");

      // 🔁 Retry (Render cold start fix)
      try {
        print("🔁 Retrying login...");
        final retry = await http.post(
          Uri.parse("$baseUrl/api/auth/google"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({"token": token}),
        );

        print("📡 Retry Status: ${retry.statusCode}");
        print("📡 Retry Body: ${retry.body}");

        if (retry.statusCode == 200) {
          return jsonDecode(retry.body);
        }
      } catch (e) {
        print("❌ Retry failed: $e");
      }

      return null;
    }
  }

  /// 🆕 Set Username
  static Future<Map<String, dynamic>?> setUsername(
    String username,
    String jwt,
  ) async {
    try {
      print("👤 Setting username: $username");

      final res = await http.post(
        Uri.parse("$baseUrl/api/users/set-username"),
        headers: {
          "Authorization": "Bearer $jwt",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"username": username}),
      );

      print("📡 Username Status: ${res.statusCode}");
      print("📡 Username Body: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      print("❌ Username failed: ${res.body}");
      return null;
    } catch (e) {
      print("🔥 Username error: $e");
      return null;
    }
  }

  /// 🔍 Search Users
  static Future<List> searchUsers(String query, String jwt) async {
    try {
      print("🔍 Searching users: $query");

      final response = await http.get(
        Uri.parse("$baseUrl/api/users/search?username=$query"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );

      print("📡 Search Status: ${response.statusCode}");
      print("📡 Search Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      print("❌ Search failed: ${response.body}");
      return [];
    } catch (e) {
      print("🔥 Search error: $e");
      return [];
    }
  }

  /// 💬 Get Messages
  static Future<List> getMessages(String userId, String jwt) async {
    try {
      print("💬 Fetching messages for: $userId");

      final response = await http.get(
        Uri.parse("$baseUrl/api/messages/$userId"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );

      print("📡 Message Status: ${response.statusCode}");
      print("📡 Message Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      print("❌ Messages failed: ${response.body}");
      return [];
    } catch (e) {
      print("🔥 Message fetch error: $e");
      return [];
    }
  }
}