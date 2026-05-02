import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  /// 🔥 STATUS SYSTEM
  final String? status;
  final String? createdAt;
  final String? seenAt; // ✅ FIX ADDED

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.status,
    this.createdAt,
    this.seenAt, // ✅ REQUIRED FOR FUTURE USE
  });

  /// 🔥 GRADIENT TICKS
  Widget buildTicks(String? status) {
    if (!isMe) return const SizedBox();

    if (status == "sent") {
      return const Icon(
        Icons.check,
        size: 16,
        color: Colors.grey,
      );
    }

    if (status == "delivered") {
      return ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.purple, Colors.deepPurple],
        ).createShader(bounds),
        child: const Icon(
          Icons.done_all,
          size: 16,
          color: Colors.white,
        ),
      );
    }

    if (status == "seen") {
      return const Icon(
        Icons.done_all,
        size: 16,
        color: Colors.blueAccent,
      );
    }

    return const SizedBox();
  }

  /// 🔥 TIME FORMAT
  String formatTime(String? date) {
    if (date == null || date.isEmpty) return "";

    try {
      final dt = DateTime.parse(date).toLocal();

      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final ampm = dt.hour >= 12 ? "PM" : "AM";

      return "$hour:${dt.minute.toString().padLeft(2, '0')} $ampm";
    } catch (_) {
      return "";
    }
  }

  /// 🔥 (OPTIONAL) SMART SEEN — NOT USED HERE
  /// 👉 ChatScreen me use hoga (last message only)
  String smartSeen(String? seenAt) {
    if (seenAt == null) return "";

    try {
      final diff =
          DateTime.now().difference(DateTime.parse(seenAt));

      if (diff.inSeconds < 10) return "👀 Seen just now";
      if (diff.inMinutes < 1) return "👀 Seen few sec ago";
      if (diff.inMinutes < 60)
        return "👀 Seen ${diff.inMinutes}m ago";
      if (diff.inHours < 24)
        return "👀 Seen ${diff.inHours}h ago";

      return "Seen earlier";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeStatus = status ?? "sent";

    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        margin:
            const EdgeInsets.symmetric(vertical: 4, horizontal: 10),

        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 14),

        constraints: const BoxConstraints(maxWidth: 260),

        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF2C2C2C)
              : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 14),
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            /// 💬 TEXT
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 6),

            /// ⏱ TIME + TICKS
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatTime(createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(width: 5),
                buildTicks(safeStatus),
              ],
            ),

            /// ❌ IMPORTANT:
            /// 👉 seen text yaha nahi dikhana
            /// 👉 ChatScreen me last message ke niche show hoga
          ],
        ),
      ),
    );
  }
}