import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';

class ProfileScreen extends StatefulWidget {
  final String jwt;
  const ProfileScreen({super.key, required this.jwt});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool loading = true;
  String error = "";

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      final data = await ApiService.getMe(widget.jwt);

      if (!mounted) return;

      if (data == null) {
        setState(() {
          error = "Failed to load profile";
          loading = false;
        });
        return;
      }

      setState(() {
        user = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = "Something went wrong";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Loading
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    // ❌ Error UI
    if (error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
          child: Text(
            error,
            style: const TextStyle(color: AppColors.secondary),
          ),
        ),
      );
    }

    final username = user?['username'] ?? "No Username";
    final email = user?['email'] ?? "";
    final avatar = user?['avatar'] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: fetchUser, // 🔥 pull to refresh
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),

            // 👤 Avatar
            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: AppColors.card,
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.primary,
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            // 🧑 Username
            Center(
              child: Text(
                username,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 📧 Email
            Center(
              child: Text(
                email,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔥 Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow("Username", username),
                  const Divider(),
                  _infoRow("Email", email),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔄 Refresh Button
            ElevatedButton.icon(
              onPressed: fetchUser,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 reusable row
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.secondary)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}