import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'chat_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final String jwt;
  final String myId;

  const HomeScreen({
    super.key,
    required this.jwt,
    required this.myId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final socket = SocketService();

  List chats = [];

  @override
  void initState() {
    super.initState();

    loadChats();

    socket.connect(userId: widget.myId);

    /// 🔥 REALTIME UPDATE (NO API SPAM)
    socket.onMessage((data) {
      updateChatList(data);
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  /// 🔥 LOAD INITIAL CHATS
  void loadChats() async {
    final data = await ApiService.getConversations(widget.jwt);

    if (!mounted) return;

    setState(() {
      chats = data;
    });
  }

  /// 🔥 REALTIME CHAT UPDATE
  void updateChatList(dynamic msg) {
    final senderId = msg['senderId'];
    final receiverId = msg['receiverId'];
    final text = msg['text'];

    final otherUserId =
        senderId == widget.myId ? receiverId : senderId;

    int index = chats.indexWhere(
      (c) => c['userId'] == otherUserId,
    );

    if (index != -1) {
      chats[index]['lastMessage'] = text;
      chats[index]['createdAt'] =
          DateTime.now().toIso8601String();
      chats[index]['senderId'] = senderId;
    } else {
      /// 🔥 NEW CHAT DEFAULT
      chats.insert(0, {
        'userId': otherUserId,
        'name': "Narada Link User", // ✅ FIXED DEFAULT
        'lastMessage': text,
        'createdAt': DateTime.now().toIso8601String(),
        'senderId': senderId,
      });
    }

    chats.sort((a, b) =>
        DateTime.parse(b['createdAt'])
            .compareTo(DateTime.parse(a['createdAt'])));

    setState(() {});
  }

  /// 🔥 SMART TIME FORMAT
  String formatChatTime(String date) {
    final dt = DateTime.parse(date).toLocal();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dt.year, dt.month, dt.day);

    final diff = today.difference(messageDay).inDays;

    if (diff == 0) {
      return DateFormat('h:mm a').format(dt);
    } else if (diff == 1) {
      return "Yesterday";
    } else {
      return DateFormat('d MMM').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: chats.isEmpty
            ? _emptyState(context)
            : _chatList(context),
      ),
    );
  }

  // ===========================
  // 🔥 EMPTY STATE
  // ===========================
  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          const Text(
            "No conversations yet",
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(
                    jwt: widget.jwt,
                    myId: widget.myId,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Find People",
                style: TextStyle(
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  // 🔥 CHAT LIST
  // ===========================
  Widget _chatList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];

        final userId = chat['userId'];

        /// 🔥 FINAL FIX (USE NAME)
        final name =
            (chat['name'] ?? "Narada Link User").toString();

        final avatar = chat['avatar'];
        final lastMessageRaw =
            (chat['lastMessage'] ?? "").toString();

        final isMe =
            chat['senderId'].toString() == widget.myId;

        final lastMessage =
            isMe ? "You: $lastMessageRaw" : lastMessageRaw;

        final time = chat['createdAt'] != null
            ? formatChatTime(chat['createdAt'])
            : "";

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  jwt: widget.jwt,
                  userId: userId,
                  myId: widget.myId,
                ),
              ),
            ).then((_) => loadChats());
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                /// 🔥 AVATAR
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.input,
                  backgroundImage:
                      avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null
                      ? Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : "U",
                          style: const TextStyle(
                              color: AppColors.primary),
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                /// 🔥 TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name, // ✅ FIXED
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔥 TIME
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}