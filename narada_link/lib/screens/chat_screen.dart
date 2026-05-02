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

    loadMessages();

    /// 🔥 STATUS UPDATE
    ApiService.markDelivered(widget.jwt);
    ApiService.markAsSeen(widget.userId, widget.jwt);

    socket.connect(userId: widget.myId);

    /// 🔥 NEW MESSAGE
    socket.onNewMessage((data) {
      final senderId = data['senderId']?.toString() ?? "";

      if (senderId == widget.myId) return;

      if (senderId == widget.userId) {
        if (!mounted) return;

        final msg = {
          "_id": data['messageId'],
          "senderId": senderId,
          "receiverId": widget.myId,
          "text": data['text'],
          "createdAt": data['createdAt'] ??
              DateTime.now().toIso8601String(),
          "status": data['status'] ?? "sent",
          "seenAt": null,
        };

        setState(() => messages.add(msg));

        scrollToBottom();

        ApiService.markAsSeen(widget.userId, widget.jwt);
      }
    });

    /// 🔥 DELIVERED
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

    /// 🔥 SEEN
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

  /// 🔥 LOAD
  void loadMessages() async {
    setState(() => loading = true);

    try {
      final data = await ApiService.getMessages(
        widget.userId,
        widget.jwt,
      );

      if (!mounted) return;

      setState(() {
        messages = List<Map<String, dynamic>>.from(data);
        loading = false;
      });

      scrollToBottom();
    } catch (e) {
      print("🔥 Load messages error: $e");

      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  /// 🔥 SCROLL
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

  /// 🔥 SEND
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
    socket.socket?.off("newMessage");
    socket.socket?.off("messageDelivered");
    socket.socket?.off("messageSeen");

    socket.disconnect();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  String getText(Map<String, dynamic> m) {
    final val = m['text'];
    if (val == null) return "";
    return val.toString();
  }

  /// 🔥 SMART SEEN TEXT
  String getSeenText(String seenAt) {
    final diff = DateTime.now().difference(DateTime.parse(seenAt));

    if (diff.inSeconds < 30) return "👀 Seen just now";
    if (diff.inMinutes < 5) return "👀 Active ${diff.inMinutes}m ago";
    return "💤 Seen earlier today";
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        (widget.name ?? "Narada Link User").toString();

    /// 🔥 LAST SEEN MESSAGE (ONLY MY LAST MSG)
    final lastSeenMsg = messages.isNotEmpty
        ? messages.lastWhere(
            (m) =>
                m['senderId'] == widget.myId &&
                m['status'] == "seen",
            orElse: () => {},
          )
        : {};

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
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];

                    final isMe =
                        m['senderId'].toString() ==
                            widget.myId;

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

            /// 🔥 SINGLE SEEN TEXT (ONLY LAST MESSAGE)
            if (lastSeenMsg.isNotEmpty &&
                lastSeenMsg['seenAt'] != null)
              Padding(
                padding: const EdgeInsets.only(
                    right: 16, bottom: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    getSeenText(lastSeenMsg['seenAt']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            /// INPUT
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
    );
  }
}