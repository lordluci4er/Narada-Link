import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/colors.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String jwt;
  final String userId;
  final String myId;

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

  List<Map<String, dynamic>> messages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();

    socket.connect(userId: widget.myId);

    /// 🔥 REALTIME MESSAGE LISTENER (NO API CALL)
    socket.onMessage((data) {
      final senderId = data['senderId'].toString();
      final receiverId = data['receiverId'].toString();

      /// ✅ Only update if message belongs to this chat
      if ((senderId == widget.userId &&
              receiverId == widget.myId) ||
          (senderId == widget.myId &&
              receiverId == widget.userId)) {
        setState(() {
          messages.add({
            "senderId": senderId,
            "receiverId": receiverId,
            "text": data['text'],
            "createdAt": DateTime.now().toIso8601String(),
          });
        });

        scrollToBottom();
      }
    });

    loadMessages();
  }

  /// 🔥 LOAD INITIAL MESSAGES (ONLY ONCE)
  void loadMessages() async {
    try {
      final data = await ApiService.getMessages(
        widget.userId,
        widget.jwt,
      );

      final formatted = List<Map<String, dynamic>>.from(data);

      setState(() {
        messages = formatted;
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

  /// 🔥 SEND MESSAGE (INSTANT UI + SOCKET)
  void send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    /// 🔥 INSTANT UI UPDATE (NO WAIT)
    setState(() {
      messages.add({
        "senderId": widget.myId,
        "receiverId": widget.userId,
        "text": text,
        "createdAt": DateTime.now().toIso8601String(),
      });
    });

    scrollToBottom();

    /// 🔥 SOCKET SEND (REALTIME)
    socket.sendMessage(
      senderId: widget.myId,
      receiverId: widget.userId,
      text: text,
    );

    /// 🔥 SAVE TO DB (BACKGROUND)
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

  /// 🔥 SAFE TEXT
  String getText(Map<String, dynamic> m) {
    final val = m['text'];
    if (val == null) return "";
    if (val is String) return val;
    return val.toString();
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

                    final text = getText(m);

                    return MessageBubble(
                      text: text,
                      isMe: isMe,
                    );
                  },
                ),
              ),

            /// ✍️ INPUT
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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