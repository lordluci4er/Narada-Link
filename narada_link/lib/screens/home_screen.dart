import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'chat_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  final String jwt; // 🔥 ADD THIS
  final List<Map<String, dynamic>> chats = [];

  HomeScreen({super.key, required this.jwt});

  @override
  Widget build(BuildContext context) {
    final isEmpty = chats.isEmpty;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Narada Link",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
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

          // 🔥 Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Recent conversations",
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isEmpty ? _emptyState(context) : _chatList(context),
          ),
        ],
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

            Text(
              "No conversations yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Find people and start your first conversation.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 25),

            // 🔥 FIXED BUTTON
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(jwt: jwt), // 🔥 FIXED
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

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChatScreen(),
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
                    chat['name'][0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat['name'],
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat['lastMessage'],
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Text(
                  chat['time'],
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