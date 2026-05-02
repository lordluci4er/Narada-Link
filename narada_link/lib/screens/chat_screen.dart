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

  @override
  void initState() {
    super.initState();

    /// 🔥 LOAD MESSAGES
    loadMessages();

    /// 🔥 STATUS UPDATE
    ApiService.markDelivered(widget.jwt);
    ApiService.markAsSeen(widget.userId, widget.jwt);

    /// 🔥 CONNECT SOCKET
    socket.connect(userId: widget.myId);

    /// 🔥 NEW MESSAGE LISTENER
    socket.onNewMessage((data) {
      final senderId = data['senderId']?.toString() ?? "";

      /// ❌ skip own message
      if (senderId == widget.myId) return;

      /// ✅ only current chat
      if (senderId == widget.userId) {
        if (!mounted) return;

        setState(() {
          messages.add({
            "_id": data['messageId'],
            "senderId": senderId,
            "receiverId": widget.myId,
            "text": data['text'],
            "createdAt": data['createdAt'] ??
                DateTime.now().toIso8601String(),
            "status": data['status'] ?? "sent",
            "seenAt": null,
          });
        });

        scrollToBottom();

        /// 🔥 instant seen update
        ApiService.markAsSeen(widget.userId, widget.jwt);
      }
    });

    /// 🔥 MESSAGE DELIVERED
    socket.socket?.on("messageDelivered", (data) {
      final index = messages.indexWhere(
        (m) => m['_id'] == data['messageId'],
      );

      if (index != -1 && mounted) {
        setState(() {
          messages[index]['status'] = "delivered";
        });
      }
    });

    /// 🔥 MESSAGE SEEN
    socket.socket?.on("messageSeen", (data) {
      final index = messages.indexWhere(
        (m) => m['_id'] == data['messageId'],
      );

      if (index != -1 && mounted) {
        setState(() {
          messages[index]['status'] = "seen";
          messages[index]['seenAt'] =
              DateTime.now().toIso8601String();
        });
      }
    });
  }

  /// 🔥 LOAD MESSAGES
  void loadMessages() async {
    setState(() => loading = true);

    try {
      final data = await ApiService.getMessages(
        widget.userId,
        widget.jwt,
      );

      final formatted = List<Map<String, dynamic>>.from(data);

      if (!mounted) return;

      setState(() {
        messages = formatted;
        loading = false;
      });

      scrollToBottom();
    } catch (e) {
      print("🔥 Load messages error: $e");

      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  /// 🔥 AUTO SCROLL
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 🔥 SEND MESSAGE
  void send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    final tempId =
        DateTime.now().millisecondsSinceEpoch.toString();

    final newMsg = {
      "_id": tempId, // temporary
      "senderId": widget.myId,
      "receiverId": widget.userId,
      "text": text,
      "createdAt": DateTime.now().toIso8601String(),
      "status": "sent",
      "seenAt": null,
    };

    setState(() => messages.add(newMsg));

    scrollToBottom();

    /// 🔥 SOCKET SEND
    socket.sendMessage(newMsg);

    /// 🔥 API SAVE
    await ApiService.sendMessage(
      widget.userId,
      text,
      widget.jwt,
    );
  }

  @override
  void dispose() {
    socket.socket?.off("newMessage");
    socket.socket?.off("messageDelivered");
    socket.socket?.off("messageSeen");

    socket.disconnect();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  /// 🔥 SAFE TEXT
  String getText(Map<String, dynamic> m) {
    final val = m['text'];
    if (val == null) return "";
    if (val is String) return val;
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        (widget.name ?? "Narada Link User").toString();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(displayName),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            /// 🔄 LOADING
            if (loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )

            /// 💤 EMPTY STATE
            else if (messages.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    "Start conversation 👋",
                    style: TextStyle(color: AppColors.secondary),
                  ),
                ),
              )

            /// 💬 CHAT LIST
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];

                    final isMe =
                        m['senderId'].toString() ==
                            widget.myId.toString();

                    return MessageBubble(
                      text: getText(m),
                      isMe: isMe,
                      status: m['status'] ?? "sent",
                      createdAt: m['createdAt'],
                      seenAt: m['seenAt'],
                    );
                  },
                ),
              ),

            /// ✍️ INPUT
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
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
                        hintStyle:
                            TextStyle(color: AppColors.secondary),
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
    );
  }
}