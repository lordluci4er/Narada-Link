import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  final String jwt;
  const SearchScreen({super.key, required this.jwt});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  List users = [];
  bool loading = false;

  void searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => users = []);
      return;
    }

    setState(() => loading = true);

    final res = await ApiService.searchUsers(query, widget.jwt);

    setState(() {
      users = res;
      loading = false;
    });
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
          // 🔥 Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              onChanged: searchUsers,
              style: const TextStyle(color: AppColors.primary),
              decoration: InputDecoration(
                hintText: "Search username...",
                hintStyle: const TextStyle(color: AppColors.secondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
              ),
            ),
          ),

          // 🔥 Loading
          if (loading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // 🔥 Results
          Expanded(
            child: users.isEmpty
                ? const Center(
                    child: Text(
                      "No users found",
                      style: TextStyle(color: AppColors.secondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(user['avatar'] ?? ""),
                        ),
                        title: Text(
                          user['username'] ?? "",
                          style:
                              const TextStyle(color: AppColors.primary),
                        ),
                        subtitle: Text(
                          user['email'] ?? "",
                          style:
                              const TextStyle(color: AppColors.secondary),
                        ),
                        onTap: () {
                          // 🔥 Open Chat
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChatScreen(),
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