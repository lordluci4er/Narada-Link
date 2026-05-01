import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/colors.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String jwt;
  final String userId; // 🔥 receiver
  final String myId;   // 🔥 current user

  const ChatScreen({
    super.key,
    required this.jwt,
    required this.userId,
    required this.myId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final socket = SocketService();
  final controller = TextEditingController();
  final scrollController = ScrollController();

  List messages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();

    loadMessages();

    // 🔥 SOCKET CONNECT
    socket.connect(userId: widget.myId);

    // 🔥 RECEIVE REALTIME MESSAGE
    socket.onMessage((data) {
      // ❗ duplicate avoid (optional basic check)
      if (data['senderId'] == widget.userId) {
        setState(() {
          messages.add(data);
        });

        scrollToBottom();
      }
    });
  }

  /// 🔥 LOAD OLD MESSAGES
  void loadMessages() async {
    try {
      final data = await ApiService.getMessages(
        widget.userId,
        widget.jwt,
      );

      setState(() {
        messages = data;
        loading = false;
      });

      scrollToBottom();
    } catch (e) {
      print("🔥 Load messages error: $e");
      setState(() {
        loading = false;
      });
    }
  }

  /// 🔥 AUTO SCROLL
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 🔥 SEND MESSAGE (REALTIME + DB)
  void send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final msg = {
      "senderId": widget.myId,
      "receiverId": widget.userId,
      "text": text,
    };

    // 🔥 realtime send
    socket.sendMessage(msg);

    // 🔥 optimistic UI
    setState(() {
      messages.add(msg);
    });

    controller.clear();
    scrollToBottom();

    // 🔥 save in DB
    final success = await ApiService.sendMessage(
      widget.userId,
      text,
      widget.jwt,
    );

    if (!success) {
      print("❌ Send failed");
    }
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
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Chat"),
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
            else

              /// 💬 MESSAGE LIST
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];

                    final isMe = m['senderId'] == widget.myId;

                    return MessageBubble(
                      text: m['text'] ?? "",
                      isMe: isMe,
                    );
                  },
                ),
              ),

            /// ✍️ INPUT BOX
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: AppColors.primary),
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