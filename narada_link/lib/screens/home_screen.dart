import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/api_service.dart';
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
  List chats = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  /// 🔥 LOAD RECENT CHATS
  void loadChats() async {
    final data = await ApiService.getRecentChats(widget.jwt);

    setState(() {
      chats = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = chats.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Narada Link",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  )
                ],
              ),
            ),

            /// 🔥 SUBTITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Recent conversations",
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 🔥 CONTENT
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : isEmpty
                      ? _emptyState(context)
                      : _chatList(context),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================
  // 🔥 EMPTY STATE
  // ===========================
  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "No conversations yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Find people and start your first conversation.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 25),

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  "Find People",
                  style: TextStyle(
                    color: AppColors.background,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================
  // 🔥 CHAT LIST
  // ===========================
  Widget _chatList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final chat = chats[index];

        final userId = chat['_id']; // 🔥 from backend
        final lastMessage = chat['lastMessage'] ?? "";

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
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.input,
                  child: Text(
                    userId.toString()[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userId, // 🔥 for now (later name fetch karenge)
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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