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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQueryData = MediaQuery.of(context);
    final newIsDarkMode = mediaQueryData.platformBrightness == Brightness.dark;
    if (isDarkMode != newIsDarkMode) {
      if (mounted) {
        setState(() {
          isDarkMode = newIsDarkMode;
        });
      } else {
        isDarkMode = newIsDarkMode;
      }
    }
  }

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
            GlowingCircles(),
             Center(child: Container(
               color: Colors.yellow,
             )),
          ],
        ),
      ),
    );
  }
}
