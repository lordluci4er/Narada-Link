import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class UsernameScreen extends StatefulWidget {
  final String jwt;

  const UsernameScreen({
    super.key,
    required this.jwt,
  });

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();

  String error = "";
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  void submit() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();

    /// 🔥 VALIDATION
    if (name.isEmpty) {
      setState(() => error = "Name cannot be empty");
      return;
    }

    if (name.length < 2) {
      setState(() => error = "Enter a valid name");
      return;
    }

    if (username.isEmpty) {
      setState(() => error = "Username cannot be empty");
      return;
    }

    if (username.length < 3) {
      setState(() =>
          error = "Username must be at least 3 characters");
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    /// 🔥 SINGLE API CALL (FIXED)
    final res = await ApiService.setUsername(
      name,
      username,
      widget.jwt,
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    /// ✅ SUCCESS
    if (res != null && res['user'] != null) {
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
        title: const Text("Set Profile"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// 🔥 TITLE
            const Text(
              "Create your profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Name & username will be visible to others",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 25),

            /// 🔥 NAME INPUT
            TextField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: "Enter your name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 15),

            /// 🔥 USERNAME INPUT
            TextField(
              controller: usernameController,
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

            const SizedBox(height: 25),

            /// 🔥 BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
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