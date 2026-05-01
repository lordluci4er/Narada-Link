import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

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

  @override
  void dispose() {
    controller.dispose(); // 🔥 memory safe
    super.dispose();
  }

  void submit() async {
    final username = controller.text.trim();

    if (username.isEmpty) {
      setState(() {
        error = "Username cannot be empty";
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        error = "Minimum 3 characters required";
      });
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    final res = await ApiService.setUsername(username, widget.jwt);

    if (!mounted) return; // 🔥 safety

    setState(() {
      loading = false;
    });

    if (res != null) {
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
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: const Text("Choose Username"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 🔥 Title
            const Text(
              "Create your identity",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "This will be visible to others",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 Input
            TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(),
              decoration: InputDecoration(
                hintText: "Enter username",
                errorText: error.isEmpty ? null : error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}