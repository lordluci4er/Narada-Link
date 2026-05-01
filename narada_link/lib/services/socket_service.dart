import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  final String baseUrl = "https://narada-link.onrender.com";

  /// 🔌 CONNECT SOCKET
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
      print("🟢 Socket Connected");

      // 🔥 register user
      socket!.emit("join", userId);
    });

    socket!.onDisconnect((_) {
      print("🔴 Socket Disconnected");
    });

    socket!.onConnectError((err) {
      print("❌ Connect Error: $err");
    });

    socket!.onError((err) {
      print("❌ Socket Error: $err");
    });
  }

  /// 💬 SEND MESSAGE (MATCH BACKEND)
  void sendMessage(Map<String, dynamic> data) {
    if (socket != null && socket!.connected) {
      socket!.emit("send_message", data); // 🔥 FIXED
    } else {
      print("⚠️ Socket not connected");
    }
  }

  /// 📥 RECEIVE MESSAGE
  void onMessage(Function(dynamic) callback) {
    socket?.on("receive_message", (data) {
      callback(data);
    });
  }

  /// ✍️ TYPING (optional future use)
  void sendTyping(String receiverId) {
    socket?.emit("typing", {
      "receiverId": receiverId,
    });
  }

  void onTyping(Function(dynamic) callback) {
    socket?.on("typing", (data) {
      callback(data);
    });
  }

  /// 🔌 DISCONNECT
  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}