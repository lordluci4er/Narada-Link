import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  final String jwt;
  final String myId;

  const SearchScreen({
    super.key,
    required this.jwt,
    required this.myId,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();

  List users = [];
  bool loading = false;

  /// 🔍 SEARCH FUNCTION
  void searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => users = []);
      return;
    }

    setState(() => loading = true);

    try {
      final res = await ApiService.searchUsers(query, widget.jwt);

      if (!mounted) return;

      setState(() {
        users = res;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        users = [];
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Search"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),

      body: Column(
        children: [
          /// 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              onChanged: searchUsers,
              style: const TextStyle(color: AppColors.primary),
              decoration: const InputDecoration(
                hintText: "Search username...",
                hintStyle: TextStyle(color: AppColors.secondary),
                prefixIcon: Icon(Icons.search, color: AppColors.secondary),
              ),
            ),
          ),

          /// 🔄 LOADING
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(),
            ),

          /// 📋 RESULTS
          Expanded(
            child: users.isEmpty
                ? Center(
                    child: Text(
                      controller.text.isEmpty
                          ? "Start typing to find users"
                          : "No users found",
                      style: const TextStyle(color: AppColors.secondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];

                      /// 🔥 SAFE DATA
                      final name =
                          (user['name'] ?? "Narada Link User").toString();

                      final username =
                          (user['username'] ?? "").toString();

                      final avatar = user['avatar'];

                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),

                        /// 👤 AVATAR
                        leading: CircleAvatar(
                          backgroundColor: AppColors.card,
                          backgroundImage:
                              (avatar != null &&
                                      avatar.toString().isNotEmpty)
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

                        /// 🔥 NAME + USERNAME
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (username.isNotEmpty)
                              Text(
                                "@$username",
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),

                        /// 🔥 OPEN CHAT (FINAL FIX)
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                jwt: widget.jwt,
                                userId: user['_id'],
                                myId: widget.myId,
                                name: name, // ✅ FIXED
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}