import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  final String baseUrl = "http://192.168.1.5:5000";

  /// 🔌 Connect with userId + JWT (recommended)
  void connect({
    required String userId,
    String? token,
  }) {
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setExtraHeaders(
            token != null ? {"Authorization": "Bearer $token"} : {},
          )
          .build(),
    );

    socket!.onConnect((_) {
      print("🟢 Connected to socket");

      // join personal room
      socket!.emit("join", userId);
    });

    socket!.onDisconnect((_) {
      print("🔴 Disconnected from socket");
    });

    socket!.onConnectError((err) {
      print("❌ Connection Error: $err");
    });
  }

  /// 💬 Send message
  void sendMessage(Map<String, dynamic> data) {
    if (socket != null && socket!.connected) {
      socket!.emit("send_message", data);
    } else {
      print("⚠️ Socket not connected");
    }
  }

  /// 📥 Listen messages
  void onMessage(Function(dynamic) callback) {
    socket?.on("receive_message", callback);
  }

  /// 🧠 Listen typing (future use)
  void onTyping(Function(dynamic) callback) {
    socket?.on("typing", callback);
  }

  /// ✍️ Emit typing
  void sendTyping(String receiverId) {
    socket?.emit("typing", {"receiverId": receiverId});
  }

  /// 🔌 Disconnect
  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}