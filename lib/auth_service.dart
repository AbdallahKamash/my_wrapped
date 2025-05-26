import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// A service class to encapsulate all Firebase Authentication operations.
class AuthService {
  // FirebaseAuth instance to interact with Firebase Authentication services.
  final FirebaseAuth _auth;
  // GoogleSignIn instance to handle the Google Sign-In flow.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Constructor requires a FirebaseAuth instance.
  AuthService(this._auth);

  // Provides a stream of the current authentication state changes.
  // Useful for automatically updating UI when a user signs in or out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Handles Google Sign-In.
  ///
  /// Returns a [String] error message if sign-in fails, otherwise returns `null` on success.
  Future<String?> signInWithGoogle() async {
    try {
      // Initiate the Google Sign-In process.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If the user cancels the sign-in, googleUser will be null.
      if (googleUser == null) {
        return 'Google Sign-in cancelled.';
      }

      // Obtain authentication details from the Google user.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a Firebase credential using Google's ID token and access token.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential.
      await _auth.signInWithCredential(credential);
      return null; // Indicates success
    } on FirebaseAuthException catch (e) {
      // Catch and handle Firebase-specific authentication errors.
      print('Firebase Auth Error during Google Sign-In: ${e.code} - ${e.message}');
      return 'Google Sign-in failed: ${e.message}';
    } catch (e) {
      // Catch any other unexpected errors during the process.
      print('Error during Google Sign-In: $e');
      return 'Sign-in failed: $e';
    }
  }

  /// Handles email and password sign-in.
  ///
  /// Takes [email] and [password]. Optionally, a `onEmailNotVerified` callback can be provided
  /// to handle cases where the email is not verified.
  /// Returns a [String] error message if sign-in fails, otherwise returns `null` on success.
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
    Function(User)? onEmailNotVerified,
  }) async {
    try {
      // Attempt to sign in with email and password.
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the user's email is verified.
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // If not verified, invoke the callback and sign out the user (optional, but good for forcing verification).
        onEmailNotVerified?.call(userCredential.user!);
        await _auth.signOut();
      }
      return null; // Indicates success
    } on FirebaseAuthException catch (e) {
      // Map Firebase authentication error codes to user-friendly messages.
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many sign-in attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Sign-in failed: ${e.message}';
      }
      print('Firebase Auth Error during Email Sign-In: ${e.code} - ${e.message}');
      return errorMessage;
    } catch (e) {
      print('Error during Email Sign-In: $e');
      return 'An unexpected error occurred: $e';
    }
  }

  /// Handles email and password user registration (sign-up).
  ///
  /// Takes [email] and [password]. Sends an email verification link upon successful registration.
  /// Returns a [String] error message if sign-up fails, otherwise returns `null` on success.
  Future<String?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Attempt to create a new user with email and password.
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If user creation is successful, send an email verification link.
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
        // Optionally sign out the user after sign-up to force email verification.
        await _auth.signOut();
      }
      return null; // Indicates success
    } on FirebaseAuthException catch (e) {
      // Map Firebase authentication error codes to user-friendly messages.
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Sign-up failed: ${e.message}';
      }
      print('Firebase Auth Error during Email Sign-Up: ${e.code} - ${e.message}');
      return errorMessage;
    } catch (e) {
      print('Error during Email Sign-Up: $e');
      return 'An unexpected error occurred: $e';
    }
  }

  /// Sends a password reset email to the provided [email].
  ///
  /// Returns a [String] error message if sending the reset email fails, otherwise returns `null` on success.
  Future<String?> sendPasswordResetEmail({required String email}) async {
    // Basic validation for the email format.
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Please enter a valid email to reset password.';
    }

    try {
      // Send the password reset email.
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Indicates success
    } on FirebaseAuthException catch (e) {
      // Map Firebase authentication error codes to user-friendly messages.
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Failed to send reset email: ${e.message}';
      }
      print('Firebase Auth Error sending password reset: ${e.code} - ${e.message}');
      return errorMessage;
    } catch (e) {
      print('Error sending password reset: $e');
      return 'An unexpected error occurred: $e';
    }
  }

  /// Signs out the currently authenticated user from both Google and Firebase.
  ///
  /// Returns a [String] error message if sign-out fails, otherwise returns `null` on success.
  Future<String?> signOut() async {
    try {
      // Attempt to sign out from Google first.
      await _googleSignIn.signOut();
      // Then sign out from Firebase.
      await _auth.signOut();
      return null; // Indicates success
    } catch (e) {
      print('Error during sign out: $e');
      return 'Sign-out failed: $e';
    }
  }
}
