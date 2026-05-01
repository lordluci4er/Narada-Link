import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsernameScreen extends StatefulWidget {
  final String jwt;
  const UsernameScreen({super.key, required this.jwt});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final controller = TextEditingController();
  String error = "";

  void submit() async {
    final res = await ApiService.setUsername(
      controller.text,
      widget.jwt,
    );

    if (res != null) {
      Navigator.pushReplacementNamed(context, "/home");
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
            TextField(controller: controller),
            const SizedBox(height: 10),
            Text(error, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: submit,
              child: const Text("Continue"),
            )
          ],
        ),
      ),
    );
  }
}