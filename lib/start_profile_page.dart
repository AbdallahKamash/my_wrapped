import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_wrapped/var.dart';

import 'auth_service.dart';
import 'home_page.dart';

class StartProfilePage extends StatefulWidget {
  const StartProfilePage({super.key});

  @override
  State<StartProfilePage> createState() => _StartProfilePageState();
}

class _StartProfilePageState extends State<StartProfilePage> {
  User? _user;
  late final AuthService _authService;
  final _profileFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _birthday;
  bool _isLoading = false;

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDarkMode ? lightPurple : darkPurple,
        fontFamily: 'Clash',
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      hintText: hint,
      hintStyle: TextStyle(
        color: (isDarkMode ? lightPurple : darkPurple).withAlpha(175),
        fontFamily: 'Clash',
        fontWeight: FontWeight.w400,
        fontSize: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDarkMode ? lightPurple : darkPurple),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: isDarkMode ? lightPurple : darkPurple),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide:
        BorderSide(color: isDarkMode ? lightPurple : darkPurple, width: 2),
      ),
      filled: true,
      fillColor: (isDarkMode ? darkPurple : lightPurple).withAlpha(51),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
    );
  }

  Future<void> _saveProfile() async {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
      'name': _nameController.text.trim(),
      'birthday': _birthday?.toIso8601String(),
      'email': _user!.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubicEmphasized;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;

    final DateTime today = DateTime.now();
    final DateTime eighteenYearsAgo =
    DateTime(today.year - 18, today.month, today.day);
    final DateTime hundredYearsAgo =
    DateTime(today.year - 100, today.month, today.day);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24.0, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(bottom: 16),
                child: IconButton(
                  icon: Icon(Icons.logout,
                      color: isDarkMode
                          ? lightPurple
                          : darkPurple),
                  tooltip: 'Sign Out',
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                                'Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context)
                                        .pop(),
                                child:
                                const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(context)
                                      .pop();
                                  await _authService
                                      .signOut();
                                  if (mounted) {
                                    startScreenPageController
                                        .animateToPage(
                                      0,
                                      duration:
                                      const Duration(
                                          milliseconds:
                                          1000),
                                      curve: Curves
                                          .easeInOutCubicEmphasized,
                                    );
                                  }
                                },
                                child: const Text(
                                    'Sign Out'),
                              )
                            ]));
                  },
                ),
              ),
              Form(
                key: _profileFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontFamily: 'Clash',
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        color: isDarkMode
                            ? lightPurple
                            : darkPurple,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                          'full name', 'enter your name'),
                      style: TextStyle(
                        color: isDarkMode
                            ? lightPurple
                            : darkPurple,
                        fontFamily: 'Clash',
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(64),
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-z0-9À-ÿ ]"),
                        ),
                        TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                              if (newValue.text.contains('  ')) {
                                return oldValue;
                              }
                              return newValue;
                            }),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'enter your name';
                        }
                        if (v.length > 64) {
                          return 'name must be at most 64 characters';
                        }
                        if (v.startsWith(' ')) {
                          return 'name cannot start with a space';
                        }
                        if (RegExp(r' {2,}').hasMatch(v)) {
                          return 'only one space allowed between words';
                        }
                        if (!RegExp(r'^[A-Za-zÀ-ÿ0-9 ]+$')
                            .hasMatch(v)) {
                          return 'only Latin letters, numbers, and spaces allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        if (isIOS) {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (BuildContext context) =>
                                Container(
                                  height: 216,
                                  padding: const EdgeInsets.only(
                                      top: 6.0),
                                  margin: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom,
                                  ),
                                  color: CupertinoColors
                                      .systemBackground
                                      .resolveFrom(context),
                                  child: SafeArea(
                                    top: false,
                                    child: CupertinoDatePicker(
                                      initialDateTime:
                                      _birthday ??
                                          eighteenYearsAgo,
                                      minimumDate:
                                      hundredYearsAgo,
                                      maximumDate:
                                      eighteenYearsAgo,
                                      mode:
                                      CupertinoDatePickerMode
                                          .date,
                                      use24hFormat: true,
                                      onDateTimeChanged:
                                          (DateTime newDateTime) {
                                        setState(() => _birthday =
                                            newDateTime);
                                      },
                                    ),
                                  ),
                                ),
                          );
                        } else {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                            _birthday ?? eighteenYearsAgo,
                            firstDate: hundredYearsAgo,
                            lastDate: eighteenYearsAgo,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context)
                                    .copyWith(
                                  colorScheme:
                                  ColorScheme.light(
                                    primary: isDarkMode
                                        ? lightPurple
                                        : darkPurple,
                                    onPrimary: isDarkMode
                                        ? darkPurple
                                        : lightPurple,
                                    surface: isDarkMode
                                        ? darkPurple
                                        : lightPurple,
                                    onSurface: isDarkMode
                                        ? lightPurple
                                        : darkPurple,
                                  ),
                                  textTheme: TextTheme(
                                    titleMedium: TextStyle(
                                      fontFamily: 'Clash',
                                      color: isDarkMode
                                          ? lightPurple
                                          : darkPurple,
                                    ),
                                    bodyLarge: TextStyle(
                                      fontFamily: 'Clash',
                                      color: isDarkMode
                                          ? lightPurple
                                          : darkPurple,
                                    ),
                                    bodySmall: TextStyle(
                                      fontFamily: 'Clash',
                                      color: isDarkMode
                                          ? lightPurple
                                          : darkPurple,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(
                                    () => _birthday = picked);
                          }
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                              text: _birthday == null
                                  ? ''
                                  : '${_birthday!.toLocal().year}-${_birthday!.toLocal().month.toString().padLeft(2, '0')}-${_birthday!.toLocal().day.toString().padLeft(2, '0')}'),
                          decoration: _inputDecoration(
                            'Birthday',
                            _birthday == null
                                ? 'select your birthday'
                                : 'birthday',
                          ),
                          style: TextStyle(
                            color: isDarkMode
                                ? lightPurple
                                : darkPurple,
                            fontFamily: 'Clash',
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                          validator: (v) => _birthday == null
                              ? 'select your birthday'
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? Center(
                        child: CircularProgressIndicator(
                          color: isDarkMode
                              ? lightPurple
                              : darkPurple,
                        ))
                        : Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(40),
                        color: isDarkMode
                            ? lightPurple
                            : darkPurple,
                      ),
                      child: InkWell(
                        onTap: _saveProfile,
                        borderRadius:
                        BorderRadius.circular(40),
                        child: Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: isDarkMode
                                  ? darkPurple
                                  : lightPurple,
                              fontWeight:
                              FontWeight.w600,
                              fontSize: 20,
                              fontFamily: 'Clash',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
