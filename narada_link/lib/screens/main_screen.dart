import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
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

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();

    screens = [
      HomeScreen(jwt: widget.jwt), // 🔥 FIXED (IMPORTANT)
      SearchScreen(jwt: widget.jwt),
      ProfileScreen(jwt: widget.jwt),
    ];
  }

  @override
  Widget build(BuildContext context) {
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