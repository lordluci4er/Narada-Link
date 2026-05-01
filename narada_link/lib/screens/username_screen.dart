import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart'; // 🔥 NEW IMPORT

class UsernameScreen extends StatefulWidget {
  final String jwt;
  const UsernameScreen({super.key, required this.jwt});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final controller = TextEditingController();
  String error = "";
  bool loading = false;

  void submit() async {
    if (controller.text.trim().isEmpty) {
      setState(() {
        error = "Username cannot be empty";
      });
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    final res = await ApiService.setUsername(
      controller.text,
      widget.jwt,
    );

    setState(() {
      loading = false;
    });

    if (res != null) {
      // 🔥 UPDATED NAVIGATION
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(jwt: widget.jwt),
        ),
      );
    } else {
      setState(() {
        error = "Username already taken or invalid";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Username")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Enter username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: loading ? null : submit,
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}