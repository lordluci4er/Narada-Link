import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _firebase = FirebaseMessaging.instance;

  static Future<String?> init() async {
    // 🔥 permission
    await _firebase.requestPermission();

    // 🔥 get token
    String? token = await _firebase.getToken();
    print("🔥 FCM TOKEN: $token");

    return token;
  }

  /// 🔔 foreground
  static void listen() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground Notification: ${message.notification?.title}");
    });
  }
}