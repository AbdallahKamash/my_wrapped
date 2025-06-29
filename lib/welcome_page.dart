import 'package:flutter/material.dart';
import 'package:my_wrapped/var.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'MyWrapped',
            style: TextStyle(
                color: isDarkMode ? lightPurple : darkPurple,
                fontWeight: FontWeight.w800,
                fontSize: 40),
          ),
          Text(
            'Wrap Up, Look Forward',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isDarkMode ? lightPurple : darkPurple,
                fontWeight: FontWeight.w800,
                fontSize: 20),
          ),
          Container(
            margin: const EdgeInsets.all(70),
            height: 60,
            width: s.width,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: isDarkMode ? lightPurple : darkPurple),
            child: InkWell(
              onTap: () {
                startScreenPageController.nextPage(
                    duration:
                    const Duration(milliseconds: 1000),
                    curve: Curves.easeInOutCubicEmphasized);
              },
              child: Center(
                  child: Text(
                    'Start',
                    style: TextStyle(
                        color:
                        isDarkMode ? darkPurple : lightPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 30),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
