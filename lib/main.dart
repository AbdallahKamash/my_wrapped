import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_wrapped/glowing_circle.dart';
import 'package:my_wrapped/start_screen.dart';
import 'package:my_wrapped/var.dart';

import 'home_page.dart';

PageController startScreenPageController = PageController(initialPage: 0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  isIOS = Platform.isIOS; // Determine if the platform is iOS
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

  // Define the SystemUiOverlayStyle here, and update it when brightness changes
  // Initialize it with the current platform brightness
  SystemUiOverlayStyle _currentSystemUiOverlayStyle = _createSystemUiOverlayStyle(
    WidgetsBinding.instance.platformDispatcher.platformBrightness,
  );

  /// Helper function to create the SystemUiOverlayStyle based on the given platform brightness.
  /// This ensures status bar icons are dark in light mode and light in dark mode.
  static SystemUiOverlayStyle _createSystemUiOverlayStyle(Brightness platformBrightness) {
    if (platformBrightness == Brightness.dark) {
      // For dark mode:
      // statusBarColor: Sets the background color of the status bar (Android).
      // statusBarIconBrightness: Controls the color of status bar icons (e.g., Wi-Fi, battery) on Android.
      //   Brightness.light makes icons light (e.g., white).
      // statusBarBrightness: Controls the color of status bar text/icons on iOS.
      //   Brightness.dark means the content *below* the status bar is dark, so iOS icons should be light.
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.black, // Dark background for status bar
        statusBarIconBrightness: Brightness.light, // Light icons for Android
        statusBarBrightness: Brightness.dark,      // Light icons for iOS
      );
    } else {
      // For light mode:
      // statusBarColor: Sets the background color of the status bar (Android).
      // statusBarIconBrightness: Controls the color of status bar icons on Android.
      //   Brightness.dark makes icons dark (e.g., black).
      // statusBarBrightness: Controls the color of status bar text/icons on iOS.
      //   Brightness.light means the content *below* the status bar is light, so iOS icons should be dark.
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.white, // Light background for status bar
        statusBarIconBrightness: Brightness.dark,  // Dark icons for Android
        statusBarBrightness: Brightness.light,     // Dark icons for iOS
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Add this observer to listen for platform brightness changes
    WidgetsBinding.instance.addObserver(this);
    _initApp();
    // The initial status bar color will be set by AnnotatedRegion in build method.
  }

  @override
  void dispose() {
    // Remove the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // This method is called when the platform's brightness changes (e.g., dark mode enabled/disabled)
    // Update the state variable to trigger a rebuild and apply the new style via AnnotatedRegion.
    setState(() {
      _currentSystemUiOverlayStyle = _createSystemUiOverlayStyle(
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
      );
    });
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

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        setState(() {
          startScreenPageController = PageController(initialPage: 3);
          _home = StartScreen();
          _loading = false;
        });
      } else {
        setState(() {
          _home = const HomePage();
          _loading = false;
        });
      }
    } catch (e) {
      // Catch any errors during Firebase operations, likely network-related
      setState(() {
        _noInternet = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first);
    final newIsDarkMode = mediaQueryData.platformBrightness == Brightness.dark;

    // Update isDarkMode global variable if it has changed
    if (isDarkMode != newIsDarkMode) {
      isDarkMode = newIsDarkMode;
      // When isDarkMode changes, update the style for AnnotatedRegion
      // This will trigger a rebuild and apply the new style.
      setState(() { // Use setState to ensure the widget rebuilds and AnnotatedRegion updates
        _currentSystemUiOverlayStyle = _createSystemUiOverlayStyle(
          mediaQueryData.platformBrightness,
        );
      });
    }

    final s = mediaQueryData.size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _currentSystemUiOverlayStyle, // Apply the determined style
      child: MaterialApp(
        title: 'My Wrapped App',
        theme: ThemeData(
          fontFamily: 'Clash',
        ),
        debugShowCheckedModeBanner: false,
        home: _loading
            ? Scaffold(
          backgroundColor: Colors.black, // Fallback background
          body: Container(
            width: s.width,
            height: s.height,
            color: isDarkMode ? darkPurple : lightPurple, // App background color
            child: Stack(
              children: [
                const GlowingCircles(), // Your custom glowing circles widget
                Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode ? lightPurple : darkPurple, // Progress indicator color
                    ))
              ],
            ),
          ),
        )
            : _noInternet
            ? Scaffold(
          backgroundColor: Colors.black, // Fallback background
          body: Container(
            width: s.width,
            height: s.height,
            color: isDarkMode ? darkPurple : lightPurple, // App background color
            child: Stack(
              children: [
                const GlowingCircles(), // Your custom glowing circles widget
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off,
                          size: 60, color: Colors.grey), // No internet icon
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
                          backgroundColor:
                          isDarkMode ? lightPurple : darkPurple,
                          foregroundColor:
                          isDarkMode ? darkPurple : lightPurple,
                        ),
                        onPressed: _initApp, // Retry button
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
            : _home, // Display home screen or start screen
      ),
    );
  }
}
