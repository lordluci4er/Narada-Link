import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? status;
  final String? createdAt;
  final String? seenAt;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.status,
    this.createdAt,
    this.seenAt,
  });

  /// 🔥 GRADIENT TICKS (FINAL)
  Widget buildTicks(String? status) {
    if (!isMe) return const SizedBox();

    if (status == "sent") {
      return const Icon(Icons.check, size: 16, color: Colors.grey);
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
    if (date == null) return "";

    try {
      final dt = DateTime.parse(date).toLocal();

      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final ampm = dt.hour >= 12 ? "PM" : "AM";

      return "$hour:${dt.minute.toString().padLeft(2, '0')} $ampm";
    } catch (_) {
      return "";
    }
  }

  /// 🔥 SMART SEEN TEXT (UPGRADED)
  String seenAgo(String? seenAt) {
    if (seenAt == null) return "";

    try {
      final diff =
          DateTime.now().difference(DateTime.parse(seenAt));

      if (diff.inMinutes < 1) return "👀 Seen just now";
      if (diff.inMinutes < 60) return "👀 Seen ${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "👀 Active ${diff.inHours}h ago";

      return "💤 Seen earlier";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
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
            /// 🔥 MESSAGE TEXT
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 6),

            /// 🔥 TIME + TICKS
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
                buildTicks(status),
              ],
            ),

            /// 🔥 SEEN TEXT (ONLY SENDER)
            if (isMe && status == "seen")
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  seenAgo(seenAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}