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

  bool isOnline = false;
  String? lastSeen;

  /// 🔥 REPLY STATE
  Map<String, dynamic>? replyingTo;

  @override
  void initState() {
    super.initState();

    loadMessages();
    loadUserStatus();

    /// ❌ REMOVED ApiService.markDelivered

    socket.connect(userId: widget.myId);
    socket.sendSeen(senderId: widget.userId);

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
            "replyTo": data['replyTo'],
            "replyText": data['replyText'],
            "replySenderId": data['replySenderId'],
          });
        });

        scrollToBottom();

        socket.sendSeen(senderId: widget.userId);
      }
    });

    socket.onMessagesSeen((data) {
      final ids = List<String>.from(data['messageIds'] ?? []);
      final seenAt = data['seenAt'];

      for (var msg in messages) {
        if (ids.contains(msg['_id'])) {
          msg['status'] = "seen";
          msg['seenAt'] = seenAt;
        }
      }

      if (mounted) setState(() {});
    });

    socket.socket?.on("messageDelivered", (data) {
      final index =
          messages.indexWhere((m) => m['_id'] == data['messageId']);

      if (index != -1 && mounted) {
        setState(() => messages[index]['status'] = "delivered");
      }
    });

    socket.onUserStatus((data) {
      if (data['userId'] == widget.userId && mounted) {
        setState(() {
          isOnline = data['isOnline'] ?? false;
          lastSeen = data['lastSeen'];
        });
      }
    });
  }

  void setReply(Map<String, dynamic> msg) {
    setState(() {
      replyingTo = msg;
    });
  }

  void clearReply() {
    setState(() {
      replyingTo = null;
    });
  }

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

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

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
      "replyTo": replyingTo?['_id'],
      "replyText": replyingTo?['text'],
      "replySenderId": replyingTo?['senderId'],
    };

    setState(() {
      messages.add(newMsg);
    });

    scrollToBottom();

    await ApiService.sendMessage(
      widget.userId,
      text,
      widget.jwt,
    );

    clearReply();
  }

  @override
  void dispose() {
    socket.disconnect();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        (widget.name ?? "Narada Link User").toString();

    final reversedMessages = messages.reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(displayName),
        backgroundColor: AppColors.background,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              reverse: true,
              itemCount: reversedMessages.length,
              itemBuilder: (context, index) {
                final m = reversedMessages[index];

                final isMe =
                    m['senderId'].toString() == widget.myId;

                return MessageBubble(
                  message: m,
                  isMe: isMe,
                  onReply: setReply,
                );
              },
            ),
          ),

          if (replyingTo != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(
                    color: Colors.blueAccent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Replying to",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          replyingTo!['text'] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white70),
                    onPressed: clearReply,
                  )
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                        color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: send,
                  icon: const Icon(Icons.send),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}