import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:my_wrapped/start_screen.dart';
import 'package:my_wrapped/var.dart';
import 'package:my_wrapped/glowing_circle.dart';
import 'auth_service.dart';

class UserProfileSetupPage extends StatefulWidget {
  final User user;
  const UserProfileSetupPage({super.key, required this.user});

  @override
  State<UserProfileSetupPage> createState() => _UserProfileSetupPageState();
}

class _UserProfileSetupPageState extends State<UserProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _numberController = TextEditingController();
  DateTime? _birthday;
  bool _isLoading = false;
  bool _signingOut = false;
  final AuthService _authService = AuthService(FirebaseAuth.instance);
  final _usernameFocusNode = FocusNode();
  String? _usernameError;
  bool _usernameAvailable = false;
  bool _checkingUsername = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameFocusNode.dispose();
    super.dispose();
  }

  // Username input formatter and validation
  String _formatUsername(String input) {
    // Allow only @ at the start, then allowed characters, but don't remove trailing special chars here
    String cleaned = input;
    // Remove all @ except at the start
    cleaned = cleaned.replaceAll('@', '');
    cleaned = '@$cleaned';
    // Only allow allowed characters after @
    String afterAt = cleaned.substring(1).replaceAll(RegExp(r'[^a-zA-Z0-9_.\-]'), '');
    cleaned = '@$afterAt';
    return cleaned;
  }

  void _onUsernameChanged() {
    String raw = _usernameController.text;
    String formatted = _formatUsername(raw);
    if (raw != formatted) {
      _usernameController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _validateUsername(formatted);
  }

  Future<void> _validateUsername(String username) async {
    String checkUsername = username.startsWith('@') ? username.substring(1) : username;
    // Check for invalid ending (but don't block typing)
    bool endsWithSpecial = RegExp(r'[_.\-]$').hasMatch(checkUsername);
    if (checkUsername.isEmpty ||
        checkUsername.contains(' ') ||
        checkUsername.contains(RegExp(r'[^a-zA-Z0-9_.\-]'))) {
      setState(() {
        _usernameError = 'Invalid username format';
        _usernameAvailable = false;
      });
      return;
    }
    setState(() {
      _usernameError = endsWithSpecial ? 'Cannot end username with special character' : null;
      _checkingUsername = true;
      _usernameAvailable = false;
    });
    // Check Firestore for existing username
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    bool taken = query.docs.any((doc) => doc.id != widget.user.uid);
    setState(() {
      _checkingUsername = false;
      if (taken) {
        _usernameError = 'Username already taken';
        _usernameAvailable = false;
      } else if (!endsWithSpecial) {
        _usernameError = null;
        _usernameAvailable = true;
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_usernameAvailable) {
      setState(() {
        _usernameError ??= 'Please choose a valid username';
      });
      return;
    }
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'number': _numberController.text.trim(),
      'birthday': _birthday?.toIso8601String(),
      'email': widget.user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.of(context).pop(); // Or navigate to home page
    }
  }

  Future<void> _handleSignOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => StartScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(-1.0, 0.0), // Slide from left
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.ease));
            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
        (route) => false,
      );
    }
    setState(() => _signingOut = false);
  }

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
        borderSide: BorderSide(color: isDarkMode ? lightPurple : darkPurple, width: 2),
      ),
      filled: true,
      fillColor: (isDarkMode ? darkPurple : lightPurple).withAlpha(51),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sign out button container at the top
                        Container(
                          alignment: Alignment.centerRight,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: IconButton(
                            icon: Icon(Icons.logout, color: isDarkMode ? lightPurple : darkPurple),
                            tooltip: 'Sign Out',
                            onPressed: _signingOut ? null : _handleSignOut,
                          ),
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Complete Your Profile',
                                style: TextStyle(
                                  fontFamily: 'Clash',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 32,
                                  color: isDarkMode ? lightPurple : darkPurple,
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextFormField(
                                controller: _nameController,
                                decoration: _inputDecoration('full name', 'enter your name'),
                                style: TextStyle(
                                  color: isDarkMode ? lightPurple : darkPurple,
                                  fontFamily: 'Clash',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(64),
                                  // Allow any number of spaces except at the beginning, only Latin letters and numbers
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r"^[A-Za-zÀ-ÿ0-9 ]*$"),
                                  ),
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'enter your name';
                                  if (v.length > 64) return 'name must be at most 64 characters';
                                  if (v.startsWith(' ')) return 'name cannot start with a space';
                                  if (RegExp(r' {2,}').hasMatch(v)) return 'only one space allowed between words';
                                  if (!RegExp(r'^[A-Za-zÀ-ÿ0-9 ]+$').hasMatch(v)) {
                                    return 'only Latin letters, numbers, and spaces allowed';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _usernameController,
                                focusNode: _usernameFocusNode,
                                decoration: _inputDecoration('username', 'choose a username').copyWith(
                                  suffixIcon: _checkingUsername
                                      ? Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isDarkMode ? lightPurple : darkPurple,
                                              ),
                                            ),
                                          ),
                                        )
                                      : _usernameAvailable
                                          ? Icon(Icons.check_circle, color: Colors.green)
                                          : (_usernameError != null
                                              ? Icon(Icons.error, color: Colors.red)
                                              : null),
                                  errorText: _usernameError,
                                ),
                                style: TextStyle(
                                  color: isDarkMode ? lightPurple : darkPurple,
                                  fontFamily: 'Clash',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                                inputFormatters: [
                                  // Only allow: @ at start, then a-z, 0-9, _, -, .
                                  FilteringTextInputFormatter.allow(RegExp(r'^@?[a-z0-9_.\-]*$')),
                                ],
                                validator: (v) {
                                  String val = v ?? '';
                                  if (val.isEmpty) return 'enter a username';
                                  if (!val.startsWith('@')) return 'username must start with @';
                                  String body = val.substring(1);
                                  if (body.isEmpty) return 'enter a username';
                                  if (!RegExp(r'^[a-z0-9_.\-]+$').hasMatch(body)) return 'only a-z, 0-9, _, -, . allowed';
                                  if (body.contains(' ')) return 'no spaces allowed';
                                  if (RegExp(r'[_.\-]$').hasMatch(body)) return 'cannot end with special character';
                                  if (_usernameError != null) return _usernameError;
                                  return null;
                                },
                                onChanged: (v) {
                                  // Already handled by listener
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _numberController,
                                decoration: _inputDecoration('phone Number', 'enter your phone number'),
                                style: TextStyle(
                                  color: isDarkMode ? lightPurple : darkPurple,
                                  fontFamily: 'Clash',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (v) => v == null || v.trim().isEmpty ? 'enter your phone number' : null,
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime(2000, 1, 1),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: isDarkMode ? lightPurple : darkPurple,
                                            onPrimary: isDarkMode ? darkPurple : lightPurple,
                                            surface: isDarkMode ? darkPurple : lightPurple,
                                            onSurface: isDarkMode ? lightPurple : darkPurple,
                                          ),
                                          textTheme: TextTheme(
                                            titleMedium: TextStyle(
                                              fontFamily: 'Clash',
                                              color: isDarkMode ? lightPurple : darkPurple,
                                            ),
                                            bodyLarge: TextStyle(
                                              fontFamily: 'Clash',
                                              color: isDarkMode ? lightPurple : darkPurple,
                                            ),
                                            bodySmall: TextStyle(
                                              fontFamily: 'Clash',
                                              color: isDarkMode ? lightPurple : darkPurple,
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) setState(() => _birthday = picked);
                                },
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: _inputDecoration(
                                      'Birthday',
                                      _birthday == null
                                          ? 'select your birthday'
                                          : 'birthday: ${_birthday!.toLocal().toString().split(' ')[0]}',
                                    ),
                                    style: TextStyle(
                                      color: isDarkMode ? lightPurple : darkPurple,
                                      fontFamily: 'Clash',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                    ),
                                    validator: (v) => _birthday == null ? 'select your birthday' : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _isLoading
                                  ? Center(child: CircularProgressIndicator(
                              color: isDarkMode ? lightPurple : darkPurple,
                            ))
                                  : Container(
                                      width: double.infinity,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(40),
                                        color: isDarkMode ? lightPurple : darkPurple,
                                      ),
                                      child: InkWell(
                                        onTap: _saveProfile,
                                        borderRadius: BorderRadius.circular(40),
                                        child: Center(
                                          child: Text(
                                            'Save',
                                            style: TextStyle(
                                              color: isDarkMode ? darkPurple : lightPurple,
                                              fontWeight: FontWeight.w600,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
