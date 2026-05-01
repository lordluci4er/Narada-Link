import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      setState(() {
        error = "Something went wrong";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(child: Text(error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 👤 Avatar
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (user?['avatar'] != null &&
                      user!['avatar'].toString().isNotEmpty)
                  ? NetworkImage(user!['avatar'])
                  : null,
              child: (user?['avatar'] == null ||
                      user!['avatar'].toString().isEmpty)
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),

            const SizedBox(height: 20),

            // 🧑 Username
            Text(
              user?['username'] ?? "No Username",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // 📧 Email
            Text(
              user?['email'] ?? "",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // 🔄 Refresh Button (useful)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  loading = true;
                });
                fetchUser();
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
          ],
        ),
      ),
    );
  }
}