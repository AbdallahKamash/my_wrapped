import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_wrapped/var.dart'; // Assuming this defines isIOS, startScreenPageController, lightPurple, darkPurple

import 'auth_form.dart'; // Assuming this is your custom AuthForm widget
import 'auth_service.dart';
import 'home_page.dart'; // Assuming this is your custom AuthService

class SignInUpForm extends StatefulWidget {
  const SignInUpForm({super.key});

  @override
  State<SignInUpForm> createState() => _SignInUpFormState();
}

class _SignInUpFormState extends State<SignInUpForm> {
  final _signInFormKey = GlobalKey<FormState>();
  User? _user;
  late final AuthService _authService;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(FirebaseAuth.instance);
    // Listen to authentication state changes to update the UI
    _authService.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
    // Add listener for page changes to clear form fields
    startScreenPageController.addListener(_handlePageChange);
  }

  // Handles page changes in the PageController to clear form fields
  void _handlePageChange() {
    if (!mounted) return;
    if (startScreenPageController.hasClients) {
      final currentPage = startScreenPageController.page?.round() ?? 0;
      // If navigating away from the sign-in/up page (assuming it's page 1)
      if (currentPage != 1) {
        FocusScope.of(context).unfocus(); // Dismiss keyboard
        _emailController.clear();
        _passwordController.clear();
      }
    }
  }

  @override
  void dispose() {
    // Remove the listener to prevent memory leaks
    startScreenPageController.removeListener(_handlePageChange);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update dark mode status based on system theme
    final mediaQueryData = MediaQuery.of(context);
    final newIsDarkMode = mediaQueryData.platformBrightness == Brightness.dark;
    if (isDarkMode != newIsDarkMode) {
      if (mounted) {
        setState(() {
          isDarkMode = newIsDarkMode;
        });
      } else {
        isDarkMode = newIsDarkMode; // Update without rebuilding if not mounted
      }
    }
  }

  // Helper function to show a SnackBar message
  void _showSnackBar(String message, {SnackBarAction? action}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), action: action),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    final mediaQueryData = MediaQuery.of(context);
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button to navigate to the previous page
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, mediaQueryData.padding.top + 40, 0, 0),
              alignment: Alignment.centerLeft,
              child: InkWell(
                  onTap: () {
                    startScreenPageController.previousPage(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOutCubicEmphasized);
                  },
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDarkMode ? lightPurple : darkPurple,
                    size: 20,
                  )),
            ),
            SizedBox(height: s.height * 0.3), // Spacer
            SizedBox(
              width: s.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      // Google Sign-In Button (Visible when not iOS)
                      if (!isIOS)
                        ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null // Disable button if loading
                              : () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  final error =
                                      await _authService.signInWithGoogle();
                                  if (error != null) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    _showSnackBar(error);
                                  } else {
                                    // Check if user document exists in Firestore
                                    if (_user == null) return;
                                    final doc = await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_user!.uid)
                                        .get();
                                    if (!doc.exists) {
                                      // If user document doesn't exist, navigate to next page (e.g., profile setup)
                                      if (mounted) {
                                        startScreenPageController.nextPage(
                                          duration: const Duration(
                                              milliseconds: 1000),
                                          curve:
                                              Curves.easeInOutCubicEmphasized,
                                        );
                                      }
                                    } else {
                                      // User document exists, proceed to main app (or whatever is next)
                                    }
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },
                          icon: Image.asset(
                            'assets/icons/PNGs/google_logo.png',
                            height: 24.0,
                            width: 24.0,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person), // Fallback icon
                          ),
                          label: const Text(
                            'Sign in with Google',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                isDarkMode ? darkPurple : lightPurple,
                            backgroundColor:
                                isDarkMode ? lightPurple : darkPurple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                  color: isDarkMode
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade400),
                            ),
                            elevation: 3,
                          ),
                        ),
                      // Apple Sign-In Button (Visible only on iOS)
                      if (isIOS)
                        ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null // Disable button if loading
                              : () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  final error =
                                      await _authService.signInWithApple();
                                  if (error != null) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    _showSnackBar(error);
                                  } else {
                                    // Check if user document exists in Firestore
                                    if (_user == null) return;
                                    final doc = await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_user!.uid)
                                        .get();
                                    if (!doc.exists) {
                                      // If user document doesn't exist, navigate to next page
                                      if (mounted) {
                                        startScreenPageController.nextPage(
                                          duration: const Duration(
                                              milliseconds: 1000),
                                          curve:
                                              Curves.easeInOutCubicEmphasized,
                                        );
                                      }
                                    } else {
                                      // User document exists, proceed to main app
                                    }
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },
                          icon: Icon(
                            Icons.apple, // Apple icon
                            color: isDarkMode ? darkPurple : lightPurple,
                            size: 25, // Icon color for dark background
                          ),
                          label: Text(
                            'Sign in with Apple',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                isDarkMode ? darkPurple : lightPurple,
                            backgroundColor:
                                isDarkMode ? lightPurple : darkPurple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                  color: isDarkMode
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade400),
                            ),
                            elevation: 3,
                          ),
                        ),
                      const SizedBox(height: 20),
                      // "OR" text, hidden if only Apple sign-in is shown
                      Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Email/Password Authentication Form
                      AuthForm(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        formKey: _signInFormKey,
                        isLoading: _isLoading,
                        onSignIn: () async {
                          if (_signInFormKey.currentState?.validate() ??
                              false) {
                            setState(() {
                              _isLoading = true;
                            });
                            final error =
                                await _authService.signInWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              onEmailNotVerified: (user) {
                                _showSnackBar(
                                  'Please verify your email address. A verification link has been sent.',
                                  action: SnackBarAction(
                                    label: 'Resend',
                                    onPressed: () async {
                                      await user.sendEmailVerification();
                                      _showSnackBar(
                                          'Verification email resent!');
                                    },
                                  ),
                                );
                              },
                            );
                            if (error != null) {
                              setState(() {
                                _isLoading = false;
                              });
                              _showSnackBar(error);
                            } else {
                              if (_user == null) return;
                              doc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_user!.uid)
                                  .get();
                              if (!doc.exists) {
                                if (mounted) {
                                  startScreenPageController.nextPage(
                                    duration:
                                        const Duration(milliseconds: 1000),
                                    curve: Curves.easeInOutCubicEmphasized,
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  Navigator.of(context).pushReplacement(PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const HomePage(),
                                      transitionsBuilder: (context, animation,
                                              secondaryAnimation, child) =>
                                          SlideTransition(
                                              position: Tween<Offset>(
                                                      begin: const Offset(
                                                          1.0, 0.0),
                                                      end: Offset.zero)
                                                  .chain(CurveTween(curve: Curves.easeInOutCubicEmphasized))
                                                  .animate(animation),
                                              child: child),
                                      transitionDuration: const Duration(milliseconds: 500)));
                                }
                              }
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        onSignUp: () async {
                          if (_signInFormKey.currentState?.validate() ??
                              false) {
                            setState(() {
                              _isLoading = true;
                            });
                            final error =
                                await _authService.signUpWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                            if (error != null) {
                              setState(() {
                                _isLoading = false;
                              });
                              _showSnackBar(error);
                            } else {
                              _showSnackBar(
                                  'Sign-up successful! Please check your email for verification.');
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        onForgotPassword: () async {
                          setState(() {
                            _isLoading = true;
                          });
                          final error =
                              await _authService.sendPasswordResetEmail(
                            email: _emailController.text.trim(),
                          );
                          setState(() {
                            _isLoading = false;
                          });
                          if (error != null) {
                            _showSnackBar(error);
                          } else {
                            _showSnackBar(
                                'Password reset email sent to ${_emailController.text.trim()}');
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
    );
  }
}
