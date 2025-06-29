import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_wrapped/var.dart';

import 'auth_form.dart';
import 'auth_service.dart';

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
    _authService.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
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
            SizedBox(height: s.height * 0.3),
            SizedBox(
              width: s.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      if (!isIOS)
                        ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
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
                                    if (_user == null) return;
                                    final doc = await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_user!.uid)
                                        .get();
                                    if (!doc.exists) {
                                      if (mounted) {
                                        startScreenPageController.nextPage(
                                          duration: const Duration(
                                              milliseconds: 1000),
                                          curve:
                                              Curves.easeInOutCubicEmphasized,
                                        );
                                      }
                                    } else {}
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
                                const Icon(Icons.person),
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
                      const SizedBox(height: 20),
                      Text(
                        isIOS ? '' : 'OR',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              final doc = await FirebaseFirestore.instance
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
                              } else {}
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
