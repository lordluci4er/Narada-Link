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
  bool loading = false;

  @override
  void initState() {
    super.initState();

    loadChats();

    socket.connect(userId: widget.myId);

    /// 🔥 JOIN (IMPORTANT)
    socket.socket?.emit("join", widget.myId);

    /// 🔥 NEW MESSAGE
    socket.onNewMessage((data) {
      updateChatList(data);
    });

    /// 🔥 ✅ BULK SEEN (NEW SYSTEM)
    socket.onMessagesSeen((data) {
      final ids = data['messageIds'] ?? [];

      for (var chat in chats) {
        if (chat['userId'] == data['by']) {
          chat['unreadCount'] = 0;
        }
      }

      if (mounted) setState(() {});
    });

    /// 🔥 PROFILE UPDATE
    socket.onUserUpdated((_) {
      loadChats();
    });

    /// 🔥 ONLINE STATUS
    socket.onUserStatus((data) {
      final userId = data['userId'];

      final index = chats.indexWhere(
        (c) => c['userId'].toString() == userId.toString(),
      );

      if (index != -1 && mounted) {
        setState(() {
          chats[index]['isOnline'] = data['isOnline'] ?? false;
          chats[index]['lastSeen'] = data['lastSeen'];
        });
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  /// 🔥 LOAD CHATS
  void loadChats() async {
    setState(() => loading = true);

    final data = await ApiService.getConversations(widget.jwt);

    if (!mounted) return;

    setState(() {
      chats = data;
      loading = false;
    });
  }

  /// 🔥 REALTIME UPDATE
  void updateChatList(dynamic msg) {
    final senderId = msg['senderId']?.toString() ?? "";
    final receiverId = msg['receiverId']?.toString() ?? "";
    final text = (msg['text'] ?? "").toString();

    final otherUserId =
        senderId == widget.myId ? receiverId : senderId;

    int index = chats.indexWhere(
      (c) => c['userId'].toString() == otherUserId,
    );

    if (index != -1) {
      chats[index]['lastMessage'] = text;
      chats[index]['createdAt'] =
          DateTime.now().toIso8601String();
      chats[index]['senderId'] = senderId;

      if (senderId != widget.myId) {
        chats[index]['unreadCount'] =
            (chats[index]['unreadCount'] ?? 0) + 1;
      }
    } else {
      chats.insert(0, {
        'userId': otherUserId,
        'name': "Narada Link User",
        'username': "",
        'avatar': null,
        'lastMessage': text,
        'createdAt': DateTime.now().toIso8601String(),
        'senderId': senderId,
        'unreadCount': senderId == widget.myId ? 0 : 1,
        'isOnline': false,
        'lastSeen': null,
      });
    }

    chats.sort((a, b) =>
        DateTime.parse(b['createdAt'])
            .compareTo(DateTime.parse(a['createdAt'])));

    if (!mounted) return;
    setState(() {});
  }

  /// 🔥 TIME FORMAT
  String formatChatTime(String? date) {
    if (date == null || date.isEmpty) return "";

    try {
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
    } catch (_) {
      return "";
    }
  }

  /// 🔥 STATUS TEXT
  String getStatusText(chat) {
    if (chat['isOnline'] == true) return "🟢 Online";

    if (chat['lastSeen'] == null) return "";

    try {
      final diff = DateTime.now()
          .difference(DateTime.parse(chat['lastSeen']));

      if (diff.inMinutes < 1) return "👀 just now";
      if (diff.inMinutes < 60)
        return "👀 ${diff.inMinutes}m ago";
      if (diff.inHours < 24)
        return "💤 ${diff.inHours}h ago";

      return "💤 ${diff.inDays}d ago";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : chats.isEmpty
                ? _emptyState(context)
                : _chatList(context),
      ),
    );
  }

  /// 🔥 EMPTY STATE
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
              ).then((_) => loadChats());
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

  /// 🔥 CHAT LIST
  Widget _chatList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];

        final userId = chat['userId'];
        final name =
            (chat['name'] ?? "Narada Link User").toString();

        final avatar = chat['avatar'];
        final unread = chat['unreadCount'] ?? 0;
        final isOnline = chat['isOnline'] == true;

        final lastMessageRaw =
            (chat['lastMessage'] ?? "").toString();

        final isMe =
            chat['senderId']?.toString() == widget.myId;

        final lastMessage =
            isMe ? "You: $lastMessageRaw" : lastMessageRaw;

        final time = formatChatTime(chat['createdAt']);

        return GestureDetector(
          onTap: () {
            chats[index]['unreadCount'] = 0;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  jwt: widget.jwt,
                  userId: userId,
                  myId: widget.myId,
                  name: name,
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
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.input,
                      backgroundImage:
                          avatar != null &&
                                  avatar.toString().isNotEmpty
                              ? NetworkImage(avatar)
                              : null,
                      child: (avatar == null ||
                              avatar.toString().isEmpty)
                          ? Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : "U",
                              style: const TextStyle(
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color:
                              isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.card,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: unread > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        getStatusText(chat),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                                fontWeight: unread > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              margin:
                                  const EdgeInsets.only(left: 6),
                              padding:
                                  const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                unread.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

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