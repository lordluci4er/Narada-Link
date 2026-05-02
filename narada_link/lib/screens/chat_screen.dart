import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/colors.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String jwt;
  final String userId;
  final String myId;
  final String? name;

  const ChatScreen({
    super.key,
    required this.jwt,
    required this.userId,
    required this.myId,
    this.name,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final socket = SocketService();
  final controller = TextEditingController();
  final scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool loading = false;

  /// 🟢 USER STATUS
  bool isOnline = false;
  String? lastSeen;

  @override
  void initState() {
    super.initState();

    loadMessages();
    loadUserStatus();

    ApiService.markDelivered(widget.jwt);
    ApiService.markAsSeen(widget.userId, widget.jwt);

    socket.connect(userId: widget.myId);

    /// 🔥 NEW MESSAGE (REALTIME)
    socket.onNewMessage((data) {
      final senderId = data['senderId']?.toString() ?? "";

      if (senderId == widget.myId) return;

      if (senderId == widget.userId && mounted) {
        setState(() {
          messages.add({
            "_id": data['messageId'],
            "senderId": senderId,
            "receiverId": widget.myId,
            "text": data['text'],
            "createdAt": data['createdAt'],
            "status": data['status'] ?? "sent",
            "seenAt": null,
          });
        });

        scrollToBottom();
        ApiService.markAsSeen(widget.userId, widget.jwt);
      }
    });

    /// 🔥 DELIVERED
    socket.socket?.on("messageDelivered", (data) {
      final index =
          messages.indexWhere((m) => m['_id'] == data['messageId']);

      if (index != -1 && mounted) {
        setState(() => messages[index]['status'] = "delivered");
      }
    });

    /// 🔥 SEEN
    socket.socket?.on("messageSeen", (data) {
      final index =
          messages.indexWhere((m) => m['_id'] == data['messageId']);

      if (index != -1 && mounted) {
        setState(() {
          messages[index]['status'] = "seen";
          messages[index]['seenAt'] =
              DateTime.now().toIso8601String();
        });
      }
    });

    /// 🟢 USER STATUS SOCKET
    socket.socket?.on("userStatus", (data) {
      if (data['userId'] == widget.userId && mounted) {
        setState(() {
          isOnline = data['isOnline'] ?? false;
          lastSeen = data['lastSeen'];
        });
      }
    });
  }

  /// 🔥 LOAD MESSAGES
  void loadMessages() async {
    setState(() => loading = true);

    try {
      final data =
          await ApiService.getMessages(widget.userId, widget.jwt);

      if (!mounted) return;

      setState(() {
        messages = List<Map<String, dynamic>>.from(data);
        loading = false;
      });

      scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  /// 🟢 LOAD STATUS
  void loadUserStatus() async {
    final data =
        await ApiService.getUserStatus(widget.userId, widget.jwt);

    if (data != null && mounted) {
      setState(() {
        isOnline = data['isOnline'] ?? false;
        lastSeen = data['lastSeen'];
      });
    }
  }

  /// 🔥 SCROLL (REVERSE LIST FIX)
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0, // 🔥 reverse list → bottom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// ✉️ SEND MESSAGE
  void send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    final tempId =
        DateTime.now().millisecondsSinceEpoch.toString();

    final newMsg = {
      "_id": tempId,
      "senderId": widget.myId,
      "receiverId": widget.userId,
      "text": text,
      "createdAt": DateTime.now().toIso8601String(),
      "status": "sent",
      "seenAt": null,
    };

    setState(() => messages.add(newMsg));
    scrollToBottom();

    socket.sendMessage(newMsg);

    await ApiService.sendMessage(
      widget.userId,
      text,
      widget.jwt,
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  String getText(Map<String, dynamic> m) {
    return m['text']?.toString() ?? "";
  }

  /// 👀 SEEN TEXT
  String getSeenText(String seenAt) {
    final diff =
        DateTime.now().difference(DateTime.parse(seenAt));

    if (diff.inSeconds < 30) return "👀 Seen just now";
    if (diff.inMinutes < 5)
      return "👀 Active ${diff.inMinutes}m ago";

    return "💤 Seen earlier today";
  }

  /// 🟢 STATUS TEXT
  String getStatus() {
    if (isOnline) return "🟢 Online";

    if (lastSeen == null) return "";

    final diff =
        DateTime.now().difference(DateTime.parse(lastSeen!));

    if (diff.inMinutes < 1) return "Active just now";
    if (diff.inMinutes < 5)
      return "Active ${diff.inMinutes}m ago";
    if (diff.inMinutes < 60)
      return "Away ${diff.inMinutes}m ago";

    return "Offline";
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        (widget.name ?? "Narada Link User").toString();

    final reversedMessages = messages.reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,

      /// 🔥 APPBAR
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName),
            Text(
              getStatus(),
              style: TextStyle(
                fontSize: 12,
                color: isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              if (loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (messages.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "Start conversation 👋",
                      style:
                          TextStyle(color: AppColors.secondary),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    padding:
                        const EdgeInsets.fromLTRB(10, 10, 10, 80),
                    itemCount: reversedMessages.length,
                    itemBuilder: (context, index) {
                      final m = reversedMessages[index];

                      final isMe =
                          m['senderId'].toString() == widget.myId;

                      final isLastMessage = index == 0;

                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          MessageBubble(
                            text: getText(m),
                            isMe: isMe,
                            status: m['status'] ?? "sent",
                            createdAt: m['createdAt'],
                            seenAt: m['seenAt'],
                          ),

                          /// 🔥 ONLY LAST SEEN TEXT
                          if (isMe &&
                              isLastMessage &&
                              m['status'] == "seen" &&
                              m['seenAt'] != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: 16, bottom: 4),
                              child: Text(
                                getSeenText(m['seenAt']),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

              /// 🔥 INPUT
              Container(
                padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(
                          color: AppColors.primary,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: send,
                      icon: const Icon(
                        Icons.send,
                        color: AppColors.primary,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}