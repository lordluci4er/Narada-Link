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
          .enableReconnection() // 🔥 auto reconnect
          .setExtraHeaders(
            token != null ? {"Authorization": "Bearer $token"} : {},
          )
          .build(),
    );

    socket!.onConnect((_) {
      print("🟢 Socket Connected");

      socket!.emit("join", userId.toString());
    });

    /// 🔁 reconnect pe bhi join karo
    socket!.onReconnect((_) {
      print("🔁 Socket Reconnected");
      socket!.emit("join", userId.toString());
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

  /// 💬 SEND MESSAGE
  void sendMessage(Map<String, dynamic> data) {
    if (socket?.connected ?? false) {
      socket!.emit("send_message", data);
    } else {
      print("⚠️ Socket not connected");
    }
  }

  /// 📥 RECEIVE MESSAGE (SAFE LISTENER)
  void onMessage(Function(dynamic) callback) {
    socket?.off("receive_message"); // 🔥 prevent duplicate listener

    socket?.on("receive_message", (data) {
      callback(data);
    });
  }

  /// ✍️ TYPING
  void sendTyping(String senderId, String receiverId) {
    socket?.emit("typing", {
      "senderId": senderId,
      "receiverId": receiverId,
    });
  }

  void onTyping(Function(dynamic) callback) {
    socket?.off("typing");

    socket?.on("typing", (data) {
      callback(data);
    });
  }

  /// 🔌 DISCONNECT
  void disconnect() {
    socket?.off("receive_message");
    socket?.off("typing");
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}