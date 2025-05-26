import 'package:flutter/material.dart';
import 'package:my_wrapped/var.dart'; // Assuming this contains `isDarkMode`, `lightPurple`, `darkPurple`

class AuthForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final VoidCallback onForgotPassword;

  const AuthForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.isLoading,
    required this.onSignIn,
    required this.onSignUp,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size; // Get screen size for responsive design

    return AutofillGroup( // Added AutofillGroup for password manager
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email], // Autofill hint
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: isDarkMode ? lightPurple : darkPurple),
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(color: isDarkMode ? lightPurple.withAlpha(175) : darkPurple.withAlpha(175)),
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
                ),
                style: TextStyle(color: isDarkMode ? lightPurple : darkPurple),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                controller: passwordController,
                obscureText: true,
                autofillHints: const [AutofillHints.password, AutofillHints.newPassword], // Autofill hints
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: isDarkMode ? lightPurple : darkPurple),
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(color: isDarkMode ? lightPurple.withAlpha(175) : darkPurple.withAlpha(175)),
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
                ),
                style: TextStyle(color: isDarkMode ? lightPurple : darkPurple),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 8) { // Minimum 8 characters
                    return 'Password must be at least 8 characters.';
                  }
                  if (!value.contains(RegExp(r'[A-Z]'))) {
                    return 'Password needs an uppercase letter.';
                  }
                  if (!value.contains(RegExp(r'[a-z]'))) {
                    return 'Password needs a lowercase letter.';
                  }
                  if (!value.contains(RegExp(r'[0-9]'))) {
                    return 'Password needs a digit.';
                  }
                  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                    return 'Password needs a special character.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(isDarkMode ? lightPurple : darkPurple),
            )
                : Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 60,
                  width: s.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: isDarkMode ? lightPurple : darkPurple,
                  ),
                  child: InkWell(
                    onTap: onSignIn,
                    child: Center(
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: isDarkMode ? darkPurple : lightPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 60,
                  width: s.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: isDarkMode ? darkPurple : lightPurple,
                    border: Border.all(
                      color: isDarkMode ? lightPurple : darkPurple,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: onSignUp,
                    child: Center(
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: isDarkMode ? lightPurple : darkPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onForgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: isDarkMode ? lightPurple : darkPurple,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
