import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_wrapped/glowing_circle.dart';
import 'package:my_wrapped/home_page.dart';
import 'package:my_wrapped/start_screen.dart';
import 'package:my_wrapped/var.dart';

PageController startScreenPageController = PageController(initialPage: 0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  isIOS = Platform.isIOS;
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

  
  
  SystemUiOverlayStyle _currentSystemUiOverlayStyle = _createSystemUiOverlayStyle(
    WidgetsBinding.instance.platformDispatcher.platformBrightness,
  );

  
  
  static SystemUiOverlayStyle _createSystemUiOverlayStyle(Brightness platformBrightness) {
    if (platformBrightness == Brightness.dark) {
      
      
      
      
      
      
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.black, 
        statusBarIconBrightness: Brightness.light, 
        statusBarBrightness: Brightness.dark,      
      );
    } else {
      
      
      
      
      
      
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.white, 
        statusBarIconBrightness: Brightness.dark,  
        statusBarBrightness: Brightness.light,     
      );
    }
  }

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    _initApp();
    
  }

  @override
  void dispose() {
    
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    
    
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

      doc = await FirebaseFirestore.instance
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

    
    if (isDarkMode != newIsDarkMode) {
      isDarkMode = newIsDarkMode;
      
      
      setState(() { 
        _currentSystemUiOverlayStyle = _createSystemUiOverlayStyle(
          mediaQueryData.platformBrightness,
        );
      });
    }

    final s = mediaQueryData.size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _currentSystemUiOverlayStyle, 
      child: MaterialApp(
        title: 'My Wrapped App',
        theme: ThemeData(
          fontFamily: 'Clash',
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
                const GlowingCircles(), 
                Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode ? lightPurple : darkPurple, 
                    ))
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
                const GlowingCircles(), 
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off,
                          size: 60, color: Colors.grey), 
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
      ),
    );
  }
}
