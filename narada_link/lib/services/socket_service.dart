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
    /// ❌ prevent duplicate connection
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

      /// 🔥 JOIN ROOM
      socket!.emit("join", userId.toString());
    });

    socket!.onReconnect((_) {
      print("🔁 Reconnected");

      /// 🔥 REJOIN
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

  /// 👀 SEND SEEN (KEEP)
  void sendSeen({
    required String senderId,
  }) {
    if (!(socket?.connected ?? false)) return;

    socket!.emit("messageSeen", {
      "userId": senderId,
    });
  }

  /// 📩 NEW MESSAGE (KEEP)
  void onNewMessage(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("newMessage");
    socket!.on("newMessage", (data) {
      callback(data);
    });
  }

  /// 🔵 BULK SEEN (KEEP)
  void onMessagesSeen(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("messagesSeen");

    socket!.on("messagesSeen", (data) {
      callback(data);
    });
  }

  /// 🟢 ONLINE STATUS (KEEP)
  void onUserStatus(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("userStatus");

    socket!.on("userStatus", (data) {
      callback(data);
    });
  }

  /// 🔥 USER UPDATED (UNCHANGED)
  void onUserUpdated(Function(dynamic) callback) {
    if (socket == null) return;

    socket!.off("userUpdated");

    socket!.on("userUpdated", (data) {
      callback(data);
    });
  }

  /// 🔌 DISCONNECT (CLEAN)
  void disconnect() {
    if (socket == null) return;

    socket!.off("newMessage");
    socket!.off("messagesSeen");
    socket!.off("userStatus");
    socket!.off("userUpdated");

    socket!.disconnect();
    socket!.dispose();

    socket = null;
    isConnected = false;

    print("🧹 Socket Cleaned");
  }
}