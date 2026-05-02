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

      /// 🔥 JOIN ROOM
      socket!.emit("join", userId.toString());
    });

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
  void sendMessage(Map<String, dynamic> data) {
    if (!(socket?.connected ?? false)) {
      print("⚠️ Socket not connected");
      return;
    }

    socket!.emit("send_message", data);
  }

  /// 📥 OLD EVENT (optional)
  void onMessage(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("receive_message");

    socket!.on("receive_message", (data) {
      callback(data);
    });
  }

  /// 🔥 NEW MESSAGE (MAIN EVENT)
  void onNewMessage(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("newMessage");

    socket!.on("newMessage", (data) {
      callback(data);
    });
  }

  /// 🔥 AUTO REFRESH (FIXED VERSION)
  void onNewMessageRefresh(Function() callback) {
    if (socket == null) return;

    socket!.off("newMessage"); // 🔥 correct cleanup

    socket!.on("newMessage", (_) {
      callback(); // 👉 e.g. loadChats() or loadMessages()
    });
  }

  /// ✍️ TYPING
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

  void onTyping(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("typing");

    socket!.on("typing", (data) {
      callback(data);
    });
  }

  /// 🟢 ONLINE USERS
  void onOnlineUsers(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("online_users");

    socket!.on("online_users", (data) {
      callback(data);
    });
  }

  /// 🔥 USER UPDATED
  void onUserUpdated(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("userUpdated");

    socket!.on("userUpdated", (data) {
      callback(data);
    });
  }

  /// 🔌 DISCONNECT (FULL CLEANUP)
  void disconnect() {
    if (socket == null) return;

    socket!.off("receive_message");
    socket!.off("newMessage"); // 🔥 important
    socket!.off("typing");
    socket!.off("online_users");
    socket!.off("userUpdated");

    socket!.disconnect();
    socket!.dispose();

    socket = null;
    isConnected = false;

    print("🧹 Socket Cleaned");
  }
}