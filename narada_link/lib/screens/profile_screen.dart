import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'edit_profile_screen.dart';

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
    /// 🔄 LOADING
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    /// ❌ ERROR
    if (error.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Profile"),
          backgroundColor: AppColors.background,
        ),
        body: Center(
          child: Text(
            error,
            style: const TextStyle(color: AppColors.secondary),
          ),
        ),
      );
    }

    /// 🔥 SAFE DATA
    final name = (user?['name'] ?? "Narada Link User").toString();
    final username = (user?['username'] ?? "").toString();
    final email = (user?['email'] ?? "").toString();
    final avatar = (user?['avatar'] ?? "").toString();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,

        /// 🔥 EDIT BUTTON (SMART UPDATE)
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedUser = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    jwt: widget.jwt,
                    currentName: name,
                  ),
                ),
              );

              /// 🔥 INSTANT UI UPDATE (NO API CALL)
              if (updatedUser != null && mounted) {
                setState(() {
                  user = updatedUser;
                });
              } else {
                /// fallback
                fetchUser();
              }
            },
          )
        ],
      ),

      body: RefreshIndicator(
        onRefresh: fetchUser,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),

            /// 👤 AVATAR
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.card,
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "U",
                        style: const TextStyle(
                          fontSize: 24,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            /// 🧑 NAME
            Center(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 6),

            /// 🔥 USERNAME
            Center(
              child: Text(
                username.isNotEmpty ? "@$username" : "",
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📧 EMAIL
            if (email.isNotEmpty)
              Center(
                child: Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                  ),
                ),
              ),

            const SizedBox(height: 30),

            /// 📦 INFO CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow("Name", name),
                  const Divider(),
                  _infoRow(
                    "Username",
                    username.isNotEmpty ? "@$username" : "-",
                  ),
                  if (email.isNotEmpty) ...[
                    const Divider(),
                    _infoRow("Email", email),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔄 REFRESH BUTTON
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

  /// 🔥 REUSABLE ROW
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