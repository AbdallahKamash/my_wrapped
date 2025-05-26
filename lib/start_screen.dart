import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_wrapped/glowing_circle.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'var.dart'; 
import 'auth_service.dart'; 
import 'auth_form.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_setup_page.dart'; // <-- Add this import

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});
  @override
  State<StartScreen> createState() => _StartScreenState();
}
class _StartScreenState extends State<StartScreen> {
  User? _user;
  late final AuthService _authService;      
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _authService = AuthService(FirebaseAuth.instance);
    _authService.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _user = user; 
        });
      }
    });
    startScreenPageController.addListener(_handlePageChange);
  }
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
  void _handlePageChange() {
    if (!mounted) return;
    if (startScreenPageController.hasClients) {
      final currentPage = startScreenPageController.page?.round() ?? 0;
      if (currentPage != 1) {
        FocusScope.of(context).unfocus();
        _emailController.clear();
        _passwordController.clear();
      }
    }
  }
  @override
  void dispose() {
    startScreenPageController.removeListener(_handlePageChange);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  void _showSnackBar(String message, {SnackBarAction? action}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), action: action),
      );
    }
  }

  Future<void> _checkAndNavigateProfileSetup(User? user) async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => UserProfileSetupPage(user: user),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(1.0, 0.0), // Slide from right
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.ease));
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      }
    } else {
      // User data exists, proceed to home page or main app
      // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
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
          child: Container(
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
                PageView(
                  physics: const NeverScrollableScrollPhysics(), 
                  controller: startScreenPageController,
                  children: [
                    Center(
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
                                    duration: const Duration(milliseconds: 1000),
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
                    ),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.fromLTRB(
                                20, mediaQueryData.padding.top + 10, 0, 0),
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                                onTap: () {
                                  startScreenPageController.previousPage(
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.easeInOutCubicEmphasized);
                                },
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color:
                                  isDarkMode ? lightPurple : darkPurple,
                                  size: 20,
                                )),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: s.width,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                               Column(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isLoading ? null : () async {
                                        setState(() { _isLoading = true; });
                                        final error = await _authService.signInWithGoogle();
                                        if (error != null) {
                                          setState(() { _isLoading = false; });
                                          _showSnackBar(error);
                                        } else {
                                          await _checkAndNavigateProfileSetup(FirebaseAuth.instance.currentUser);
                                          setState(() { _isLoading = false; });
                                        }
                                      },
                                      icon: Image.asset(
                                        'assets/icons/PNGs/google_logo.png',
                                        height: 24.0,
                                        width: 24.0,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
                                      ),
                                      label: const Text(
                                        'Sign in with Google',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: isDarkMode ? darkPurple : lightPurple,
                                        backgroundColor: isDarkMode ? lightPurple : darkPurple,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                          side: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    AuthForm(
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      formKey: _formKey,
                                      isLoading: _isLoading,
                                      onSignIn: () async {
                                        if (_formKey.currentState?.validate() ?? false) {
                                          setState(() { _isLoading = true; });
                                          final error = await _authService.signInWithEmailAndPassword(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text.trim(),
                                            onEmailNotVerified: (user) {
                                              _showSnackBar(
                                                'Please verify your email address. A verification link has been sent.',
                                                action: SnackBarAction(
                                                  label: 'Resend',
                                                  onPressed: () async {
                                                    await user.sendEmailVerification();
                                                    _showSnackBar('Verification email resent!');
                                                  },
                                                ),
                                              );
                                            },
                                          );
                                          if (error != null) {
                                            setState(() { _isLoading = false; });
                                            _showSnackBar(error);
                                          } else {
                                            await _checkAndNavigateProfileSetup(FirebaseAuth.instance.currentUser);
                                            setState(() { _isLoading = false; });
                                          }
                                        }
                                      },
                                      onSignUp: () async {
                                        if (_formKey.currentState?.validate() ?? false) {
                                          setState(() { _isLoading = true; });
                                          final error = await _authService.signUpWithEmailAndPassword(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text.trim(),
                                          );
                                          if (error != null) {
                                            setState(() { _isLoading = false; });
                                            _showSnackBar(error);
                                          } else {
                                            _showSnackBar('Sign-up successful! Please check your email for verification.');
                                            await _checkAndNavigateProfileSetup(FirebaseAuth.instance.currentUser);
                                            setState(() { _isLoading = false; });
                                          }
                                        }
                                      },
                                      onForgotPassword: () async {
                                        setState(() { _isLoading = true; });
                                        final error = await _authService.sendPasswordResetEmail(
                                          email: _emailController.text.trim(),
                                        );
                                        setState(() { _isLoading = false; });
                                        if (error != null) {
                                          _showSnackBar(error);
                                        } else {
                                          _showSnackBar('Password reset email sent to ${_emailController.text.trim()}');
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'NOTE: THIS APP IS UNDER DEVELOPMENT',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
