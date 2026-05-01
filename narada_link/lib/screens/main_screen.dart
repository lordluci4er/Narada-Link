import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/api_service.dart';

import 'home_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final String jwt;
  const MainScreen({super.key, required this.jwt});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  List<Widget> screens = [];
  String? myId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initUser();
  }

  /// 🔥 GET CURRENT USER ID
  Future<void> initUser() async {
    try {
      final user = await ApiService.getMe(widget.jwt);

      if (user != null && user['_id'] != null) {
        myId = user['_id'];

        // 🔥 IMPORTANT FIX
        screens = [
          HomeScreen(
            jwt: widget.jwt,
            myId: myId!, // ✅ FIXED
          ),
          SearchScreen(
            jwt: widget.jwt,
            myId: myId!,
          ),
          ProfileScreen(jwt: widget.jwt),
        ];
      } else {
        print("❌ Failed to fetch user or missing _id");
      }
    } catch (e) {
      print("🔥 initUser error: $e");
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// 🔄 Loading state
    if (loading || screens.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}