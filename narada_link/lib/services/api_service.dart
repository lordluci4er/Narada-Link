import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "https://narada-link.onrender.com";

  /// 🔐 LOGIN
  static Future<Map<String, dynamic>?> login(String token) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": token}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 🔥 SET NAME + USERNAME
  static Future<Map<String, dynamic>?> setUsername(
    String name,
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
        body: jsonEncode({
          "name": name,
          "username": username,
        }),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 🆕 SET NAME
  static Future<bool> setName(String name, String jwt) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/users/set-name"),
        headers: {
          "Authorization": "Bearer $jwt",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"name": name}),
      );

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 👤 GET ME
  static Future<Map<String, dynamic>?> getMe(String jwt) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/users/me"),
        headers: {
          "Authorization": "Bearer $jwt",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 🔍 SEARCH USERS
  static Future<List> searchUsers(String query, String jwt) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/users/search?username=$query"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 💬 GET MESSAGES
  static Future<List> getMessages(String userId, String jwt) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/messages/$userId"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 📤 SEND MESSAGE
  static Future<bool> sendMessage(
    String receiverId,
    String text,
    String jwt,
  ) async {
    try {
      final res = await http.post(
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

      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// 🔥 MARK AS DELIVERED
  static Future<void> markDelivered(String jwt) async {
    try {
      await http.put(
        Uri.parse("$baseUrl/api/messages/delivered"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );
    } catch (_) {}
  }

  /// 🔥 MARK AS SEEN
  static Future<void> markAsSeen(String userId, String jwt) async {
    try {
      await http.put(
        Uri.parse("$baseUrl/api/messages/seen/$userId"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );
    } catch (_) {}
  }

  /// 🟢 GET USER ONLINE STATUS (🔥 NEW)
  static Future<Map<String, dynamic>?> getUserStatus(
    String userId,
    String jwt,
  ) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/users/status/$userId"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (_) {
      return null;
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
        body: jsonEncode({"token": fcmToken}),
      );
    } catch (_) {}
  }

  /// 💬 GET RECENT CHATS
  static Future<List> getRecentChats(String jwt) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/messages/recent"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 💬 GET CONVERSATIONS
  static Future<List> getConversations(String jwt) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/messages/conversations"),
        headers: {
          "Authorization": "Bearer $jwt",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 🔥 UPDATE PROFILE
  static Future<Map<String, dynamic>?> updateProfile(
    String name,
    String avatar,
    String jwt,
  ) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/api/users/update"),
        headers: {
          "Authorization": "Bearer $jwt",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "avatar": avatar,
        }),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}