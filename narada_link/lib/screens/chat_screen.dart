import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../utils/colors.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final socket = SocketService();
  final controller = TextEditingController();
  final scrollController = ScrollController();

  List messages = [];

  final String myId = "user1";
  final String receiverId = "user2";

  @override
  void initState() {
    super.initState();

    socket.connect(userId: myId);

    socket.onMessage((data) {
      setState(() {
        messages.add(data);
      });

      scrollToBottom();
    });
  }

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

  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final msg = {
      "senderId": myId,
      "receiverId": receiverId,
      "message": text
    };

    socket.sendMessage(msg);

    setState(() {
      messages.add(msg); // optimistic UI
    });

    controller.clear();
    scrollToBottom();
  }

  @override
  void dispose() {
    socket.disconnect(); // 🔥 important
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
            /// 🔥 Messages List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final isMe = m['senderId'] == myId;

                  return MessageBubble(
                    text: m['message'],
                    isMe: isMe,
                  );
                },
              ),
            ),

            /// 🔥 Input Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.background,
              ),
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