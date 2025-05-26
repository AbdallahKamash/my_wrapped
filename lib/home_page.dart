import 'package:flutter/material.dart';
import 'package:my_wrapped/var.dart';
import 'package:my_wrapped/glowing_circle.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: s.width,
        height: s.height,
        color: isDarkMode ? darkPurple : lightPurple,
        child: Stack(
          children: [
            GlowingMovingCircle(
              color: isDarkMode ? lightPurple : darkPurple,
              size: 200,
              speed: 120,
            ),
            GlowingMovingCircle(
              color: isDarkMode ? lightPurple : darkPurple,
              size: 500,
              speed: 50,
            ),
            GlowingMovingCircle(
              color: isDarkMode ? lightPurple : darkPurple,
              size: 300,
              speed: 30,
            ),
            // ...your main content here...
            const Center(child: Placeholder()),
          ],
        ),
      ),
    );
  }
}
