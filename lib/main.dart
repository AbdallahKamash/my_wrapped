import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_wrapped/glowing_circle.dart';
import 'package:my_wrapped/start_screen.dart';
import 'package:my_wrapped/var.dart';
import 'user_profile_setup_page.dart';
import 'home_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Widget? _home;
  bool _loading = true;
  bool _noInternet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  @override
  void didChangePlatformBrightness() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final newIsDarkMode = brightness == Brightness.dark;
    if (isDarkMode != newIsDarkMode) {
      setState(() {
        isDarkMode = newIsDarkMode;
      });
    }
  }

  Future<void> _initApp() async {
    setState(() {
      _loading = true;
      _noInternet = false;
    });
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.first == ConnectivityResult.none) {
      setState(() {
        _noInternet = true;
        _loading = false;
      });
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _home = const StartScreen();
          _loading = false;
        });
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        setState(() {
          _home = UserProfileSetupPage(user: user);
          _loading = false;
        });
      } else {
        setState(() {
          _home = const HomePage();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _noInternet = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQueryData.fromView instead of fromWindow
    final mediaQueryData = MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first);
    final newIsDarkMode = mediaQueryData.platformBrightness == Brightness.dark;
    if (isDarkMode != newIsDarkMode) {
      isDarkMode = newIsDarkMode;
    }
    final s = mediaQueryData.size;
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Clash',
        primarySwatch: Colors.deepPurple,
      ),
      debugShowCheckedModeBanner: false,
      home: _loading
          ? Scaffold(
              backgroundColor: Colors.black,
              body: Container(
                width: s.width,
                height: s.height,
                color: isDarkMode ? darkPurple : lightPurple,
                child: Stack(
                  children: [
                    GlowingMovingCircle(
                      color: (isDarkMode ? lightPurple : darkPurple),
                      size: 200,
                      speed: 120,
                    ),
                    GlowingMovingCircle(
                      color: (isDarkMode ? lightPurple : darkPurple),
                      size: 500,
                      speed: 50,
                    ),
                    GlowingMovingCircle(
                      color: (isDarkMode ? lightPurple : darkPurple),
                      size: 300,
                      speed: 30,
                    ),
                     Center(child: CircularProgressIndicator(
                      color: isDarkMode ? lightPurple : darkPurple,
                    )
                     )
                  ],
                ),
              ),
            )
          : _noInternet
              ? Scaffold(
                  backgroundColor: Colors.black,
                  body: Container(
                    width: s.width,
                    height: s.height,
                    color: isDarkMode ? darkPurple : lightPurple,
                    child: Stack(
                      children: [
                        GlowingMovingCircle(
                          color: (isDarkMode ? lightPurple : darkPurple),
                          size: 200,
                          speed: 120,
                        ),
                        GlowingMovingCircle(
                          color: (isDarkMode ? lightPurple : darkPurple),
                          size: 500,
                          speed: 50,
                        ),
                        GlowingMovingCircle(
                          color: (isDarkMode ? lightPurple : darkPurple),
                          size: 300,
                          speed: 30,
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                              const SizedBox(height: 20),
                              Text(
                                'No Internet Connection',
                                style: TextStyle(
                                  color: isDarkMode ? lightPurple : darkPurple,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Clash',
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode ? lightPurple : darkPurple,
                                  foregroundColor: isDarkMode ? darkPurple : lightPurple,
                                ),
                                onPressed: _initApp,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _home,
    );
  }
}
