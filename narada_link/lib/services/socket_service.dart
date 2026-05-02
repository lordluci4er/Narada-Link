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
    // 🔥 prevent multiple connections
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

      socket!.emit("join", userId.toString());
    });

    /// 🔁 reconnect pe join fir se
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

  /// 💬 SEND MESSAGE
  void sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) {
    if (!isConnected) {
      print("⚠️ Socket not connected");
      return;
    }

    socket!.emit("send_message", {
      "senderId": senderId,
      "receiverId": receiverId,
      "text": text,
    });
  }

  /// 📥 RECEIVE MESSAGE
  void onMessage(Function(dynamic) callback) {
    socket?.off("receive_message"); // 🔥 prevent duplicate

    socket?.on("receive_message", (data) {
      callback(data);
    });
  }

  /// ✍️ TYPING SEND
  void sendTyping({
    required String senderId,
    required String receiverId,
  }) {
    if (!isConnected) return;

    socket?.emit("typing", {
      "senderId": senderId,
      "receiverId": receiverId,
    });
  }

  /// ✍️ TYPING LISTEN
  void onTyping(Function(dynamic) callback) {
    socket?.off("typing");

    socket?.on("typing", (data) {
      callback(data);
    });
  }

  /// 🟢 ONLINE USERS (optional future)
  void onOnlineUsers(Function(dynamic) callback) {
    socket?.off("online_users");

    socket?.on("online_users", (data) {
      callback(data);
    });
  }

  /// 🔌 DISCONNECT
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