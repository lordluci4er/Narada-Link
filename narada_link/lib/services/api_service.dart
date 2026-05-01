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
            body: jsonEncode({
              "token": token,
            }),
          )
          .timeout(const Duration(seconds: 20));

      print("📡 Status Code: ${response.statusCode}");
      print("📡 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Login failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("🔥 API Error (Login): $e");

      // 🔁 Retry once (Render cold start fix)
      try {
        print("🔁 Retrying login request...");
        final retryResponse = await http.post(
          Uri.parse("$baseUrl/api/auth/google"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "token": token,
          }),
        );

        print("📡 Retry Status: ${retryResponse.statusCode}");
        print("📡 Retry Body: ${retryResponse.body}");

        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        }
      } catch (e) {
        print("❌ Retry failed: $e");
      }

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
      } else {
        print("❌ Search failed: ${response.body}");
        return [];
      }
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
      } else {
        print("❌ Messages failed: ${response.body}");
        return [];
      }
    } catch (e) {
      print("🔥 Message fetch error: $e");
      return [];
    }
  }
}