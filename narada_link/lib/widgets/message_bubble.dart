import 'package:flutter/material.dart';

class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  final String? status;
  final String? createdAt;
  final String? seenAt;

  /// 🔥 REPLY CALLBACK
  final Function(Map<String, dynamic>)? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.status,
    this.createdAt,
    this.seenAt,
    this.onReply,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  double dragX = 0;

  /// 🔥 TICKS
  Widget buildTicks(String status) {
    if (!widget.isMe) return const SizedBox();

    switch (status) {
      case "sent":
        return const Icon(Icons.check, size: 16, color: Colors.grey);

      case "delivered":
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
          ).createShader(bounds),
          child: const Icon(Icons.done_all, size: 16, color: Colors.white),
        );

      case "seen":
        return const Icon(Icons.done_all, size: 16, color: Colors.blueAccent);

      default:
        return const Icon(Icons.schedule, size: 16, color: Colors.grey);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final safeStatus = widget.status ?? "sent";

    final text = widget.message['text'] ?? "";
    final replyText = widget.message['replyText'];

    return GestureDetector(
      /// 🔥 SWIPE DETECT
      onHorizontalDragUpdate: (details) {
        setState(() {
          dragX += details.delta.dx;

          if (dragX < 0) dragX = 0;
          if (dragX > 80) dragX = 80;
        });
      },

      onHorizontalDragEnd: (_) {
        if (dragX > 50 && widget.onReply != null) {
          widget.onReply!(widget.message);
        }

        setState(() => dragX = 0);
      },

      child: Transform.translate(
        offset: Offset(dragX, 0),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),

          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),

          constraints: const BoxConstraints(maxWidth: 260),

          decoration: BoxDecoration(
            color: widget.isMe
                ? const Color(0xFF2C2C2C)
                : const Color(0xFFE0E0E0),

            /// 🔥 SWIPE GLOW
            boxShadow: dragX > 20
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 10,
                    )
                  ]
                : [],

            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(widget.isMe ? 14 : 4),
              bottomRight: Radius.circular(widget.isMe ? 4 : 14),
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              /// 🔥 REPLY PREVIEW (FINAL MERGED)
              if (replyText != null && replyText.toString().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    border: const Border(
                      left: BorderSide(
                        color: Colors.blueAccent,
                        width: 3,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    replyText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: widget.isMe
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ),

              /// 💬 MESSAGE TEXT
              Text(
                text,
                style: TextStyle(
                  color: widget.isMe ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 6),

              /// ⏱ TIME + STATUS
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatTime(widget.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isMe
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 5),
                  buildTicks(safeStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}