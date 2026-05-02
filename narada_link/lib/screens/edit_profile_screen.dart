import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';

class EditProfileScreen extends StatefulWidget {
  final String jwt;
  final String currentName;

  const EditProfileScreen({
    super.key,
    required this.jwt,
    required this.currentName,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;

  bool loading = false;
  String error = "";

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  /// 🔥 SAVE PROFILE
  void saveProfile() async {
    final name = nameController.text.trim();

    if (name.length < 2) {
      setState(() {
        error = "Name must be at least 2 characters";
      });
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    final res = await ApiService.updateProfile(
      name,
      "", // 🔥 avatar later
      widget.jwt,
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (res != null) {
      Navigator.pop(context, true); // 🔥 go back + refresh trigger
    } else {
      setState(() {
        error = "Failed to update profile";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// 🧑 NAME INPUT
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.primary),
              decoration: InputDecoration(
                labelText: "Name",
                labelStyle: const TextStyle(color: AppColors.secondary),
                errorText: error.isEmpty ? null : error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 💾 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}