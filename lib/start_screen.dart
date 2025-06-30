import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_wrapped/glowing_circle.dart';
import 'package:my_wrapped/sign_in_up_form.dart';
import 'package:my_wrapped/start_profile_page.dart';
import 'package:my_wrapped/welcome_page.dart';
import 'var.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {

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
    final mediaQueryData = MediaQuery.of(context);
    final s = mediaQueryData.size;

    return MediaQuery(
      data: mediaQueryData.copyWith(
        textScaler: TextScaler.noScaling,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, dynamic result) {
            if (didPop) {
              return;
            }
            if (startScreenPageController.hasClients) {
              final currentPage = startScreenPageController.page?.round() ?? 0;
              if (currentPage == 1) {
                startScreenPageController.previousPage(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOutCubicEmphasized,
                );
              } else if (currentPage == 0) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  SystemNavigator.pop();
                }
              }
            } else {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
          },
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Container(
              width: s.width,
              height: s.height,
              color: isDarkMode ? darkPurple : lightPurple,
              child: Stack(
                children: [
                  GlowingCircles(),
                  PageView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: startScreenPageController,
                    children: [
                      WelcomePage(),
                      SignInUpForm(),
                      StartProfilePage(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
