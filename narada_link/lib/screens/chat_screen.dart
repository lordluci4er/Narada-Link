import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/colors.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String jwt;
  final String userId;
  final String myId;
  final String? userName;

  const ChatScreen({
    super.key,
    required this.jwt,
    required this.userId,
    required this.myId,
    this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final socket = SocketService();
  final controller = TextEditingController();
  final scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool loading = false; // 🔥 improved UX

  @override
  void initState() {
    super.initState();

    socket.connect(userId: widget.myId);

    /// 🔥 REALTIME LISTENER (FIXED)
    socket.onMessage((data) {
      final senderId = data['senderId'].toString();
      final receiverId = data['receiverId'].toString();

      /// ❌ skip own message (already added locally)
      if (senderId == widget.myId.toString()) return;

      /// ✅ only this chat messages
      if (senderId == widget.userId &&
          receiverId == widget.myId) {
        setState(() {
          messages.add({
            "senderId": senderId,
            "receiverId": receiverId,
            "text": data['text'],
            "createdAt": data['createdAt'] ??
                DateTime.now().toIso8601String(),
          });
        });

        scrollToBottom();
      }
    });

    loadMessages();
  }

  /// 🔥 LOAD MESSAGES
  void loadMessages() async {
    setState(() {
      loading = true;
    });

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

  /// 🔥 SEND MESSAGE
  void send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    final newMsg = {
      "senderId": widget.myId,
      "receiverId": widget.userId,
      "text": text,
      "createdAt": DateTime.now().toIso8601String(),
    };

    /// 🔥 INSTANT UI
    setState(() {
      messages.add(newMsg);
    });

    scrollToBottom();

    /// 🔥 SOCKET SEND
    socket.sendMessage(newMsg);

    /// 🔥 SAVE TO DB
    await ApiService.sendMessage(
      widget.userId,
      text,
      widget.jwt,
    );
  }

  @override
  void dispose() {
    /// 🔥 IMPORTANT: remove listener
    socket.socket?.off("receive_message");

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
        (widget.userName ?? "Narada Link User").toString();

    return Scaffold(
      backgroundColor: AppColors.background,

      /// 🔥 APP BAR
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
                          color: AppColors.primary),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(
                            color: AppColors.secondary),
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