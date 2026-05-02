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
          .setQuery({'userId': userId})
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

      /// fallback join
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

  /// 📩 NEW MESSAGE
  void onNewMessage(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("newMessage");

    socket!.on("newMessage", (data) {
      callback(data);
    });
  }

  /// 🔄 AUTO REFRESH
  void onNewMessageRefresh(Function() callback) {
    if (socket == null) return;

    socket!.on("newMessage", (_) {
      callback();
    });
  }

  /// 👀 ✅ MESSAGE SEEN (🔥 FINAL FIX)
  void onMessageSeen(Function(String messageId) callback) {
    if (socket == null) return;

    socket!.off("messageSeen");

    socket!.on("messageSeen", (data) {
      final messageId = data['messageId']?.toString();
      if (messageId != null) {
        callback(messageId);
      }
    });
  }

  /// 🔵 OPTIONAL BULK SEEN (future use)
  void onMessagesSeen(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("messagesSeen");

    socket!.on("messagesSeen", (data) {
      callback(data);
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

  /// 🟢 ONLINE STATUS
  void onUserStatus(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("userStatus");

    socket!.on("userStatus", (data) {
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

  /// 🔌 DISCONNECT
  void disconnect() {
    if (socket == null) return;

    socket!.off("newMessage");
    socket!.off("messageSeen");
    socket!.off("messagesSeen");
    socket!.off("typing");
    socket!.off("userStatus");
    socket!.off("userUpdated");

    socket!.disconnect();
    socket!.dispose();

    socket = null;
    isConnected = false;

    print("🧹 Socket Cleaned");
  }
}