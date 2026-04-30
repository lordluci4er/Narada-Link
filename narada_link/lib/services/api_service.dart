import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ Apna local IP yahan update karna
  static const baseUrl = "http://192.168.1.5:5000";

  /// 🔐 Google Login API
  static Future<Map<String, dynamic>?> login(String token) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/google"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "token": token,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Login failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("API Error: $e");
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
      } else {
        return [];
      }
    } catch (e) {
      print("Search error: $e");
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
      } else {
        return [];
      }
    } catch (e) {
      print("Message fetch error: $e");
      return [];
    }
  }
}