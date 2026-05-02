import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  final String baseUrl = "https://narada-link.onrender.com";

  bool isConnected = false;

  /// 🔌 CONNECT SOCKET
  void connect({
    required String userId,
    String? token,
  }) {
    /// 🔥 prevent multiple connections
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setExtraHeaders(
            token != null ? {"Authorization": "Bearer $token"} : {},
          )
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      isConnected = true;
      print("🟢 Socket Connected");

      /// 🔥 join room
      socket!.emit("join", userId.toString());
    });

    /// 🔁 reconnect pe fir join
    socket!.onReconnect((_) {
      print("🔁 Reconnected");
      socket!.emit("join", userId.toString());
    });

    socket!.onDisconnect((_) {
      isConnected = false;
      print("🔴 Disconnected");
    });

    socket!.onConnectError((err) {
      print("❌ Connect Error: $err");
    });

    socket!.onError((err) {
      print("❌ Socket Error: $err");
    });
  }

  /// 💬 SEND MESSAGE (🔥 MAP VERSION)
  void sendMessage(Map<String, dynamic> data) {
    if (!(socket?.connected ?? false)) {
      print("⚠️ Socket not connected");
      return;
    }

    socket!.emit("send_message", data);
  }

  /// 📥 RECEIVE MESSAGE
  void onMessage(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("receive_message"); // 🔥 avoid duplicate listener

    socket!.on("receive_message", (data) {
      callback(data);
    });
  }

  /// ✍️ SEND TYPING
  void sendTyping({
    required String senderId,
    required String receiverId,
  }) {
    if (!(socket?.connected ?? false)) return;

    socket!.emit("typing", {
      "senderId": senderId,
      "receiverId": receiverId,
    });
  }

  /// ✍️ LISTEN TYPING
  void onTyping(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("typing");

    socket!.on("typing", (data) {
      callback(data);
    });
  }

  /// 🟢 ONLINE USERS (future ready)
  void onOnlineUsers(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("online_users");

    socket!.on("online_users", (data) {
      callback(data);
    });
  }

  /// 🔌 DISCONNECT (CLEANUP)
  void disconnect() {
    if (socket == null) return;

    socket!.off("receive_message");
    socket!.off("typing");
    socket!.off("online_users");

    socket!.disconnect();
    socket!.dispose();

    socket = null;
    isConnected = false;

    print("🧹 Socket Cleaned");
  }
}