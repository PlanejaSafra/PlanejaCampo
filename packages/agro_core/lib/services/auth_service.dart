import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication service for Firebase (Google Sign-In and Anonymous).
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user (if any).
  static User? get currentUser => _auth.currentUser;

  /// Check if user is signed in.
  static bool get isSignedIn => _auth.currentUser != null;

  /// Sign in with Google.
  /// Returns the User if successful, throws exception if fails.
  static Future<User?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled sign-in
        return null;
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      // Re-throw for caller to handle
      rethrow;
    }
  }

  /// Sign in anonymously.
  /// Returns the User if successful, throws exception if fails.
  static Future<User?> signInAnonymous() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      // Re-throw for caller to handle
      rethrow;
    }
  }

  /// Sign out (works for both Google and Anonymous).
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Link anonymous account to Google account (upgrade).
  /// Useful if user starts as anonymous and later wants to sign in with Google.
  static Future<User?> linkAnonymousToGoogle() async {
    if (_auth.currentUser == null || !_auth.currentUser!.isAnonymous) {
      throw Exception('No anonymous user to link');
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link credentials
      final UserCredential userCredential =
          await _auth.currentUser!.linkWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }
}
