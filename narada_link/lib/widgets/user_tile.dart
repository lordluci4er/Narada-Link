import 'package:flutter/material.dart';
import '../utils/colors.dart';

class UserTile extends StatelessWidget {
  final String username;
  final VoidCallback? onTap;

  const UserTile({
    super.key,
    required this.username,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            /// 🔥 Avatar Circle
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.input,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : "?",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// 🔥 Username
            Expanded(
              child: Text(
                username,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            /// 🔥 Arrow icon
            const Icon(
              Icons.chevron_right,
              color: AppColors.secondary,
            )
          ],
        ),
      ),
    );
  }
}