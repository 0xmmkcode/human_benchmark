import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
  );

  static Stream<User?> get authStateChanges {
    if (Firebase.apps.isEmpty) {
      return const Stream<User?>.empty();
    }
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream<User?>.empty();
    }
  }

  static User? get currentUser {
    if (Firebase.apps.isEmpty) return null;
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool get isAuthenticated {
    return currentUser != null;
  }

  static Future<void> initializeAuth() async {
    if (kIsWeb && Firebase.apps.isNotEmpty) {
      try {
        // Set persistence to LOCAL for web to maintain auth state across sessions
        await _auth.setPersistence(Persistence.LOCAL);
        print('Auth persistence set to LOCAL successfully');

        // Check if user was previously authenticated
        final User? user = _auth.currentUser;
        if (user != null) {
          print('User was previously authenticated: ${user.email}');
        }
      } catch (e) {
        print('Failed to set auth persistence: $e');
      }
    }
  }

  static Future<bool> wasPreviouslyAuthenticated() async {
    if (Firebase.apps.isEmpty) return false;
    try {
      // Wait a bit for auth state to restore
      await Future.delayed(Duration(milliseconds: 500));
      return _auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  static Future<UserCredential?> signInWithGoogle() async {
    if (Firebase.apps.isEmpty) return null;

    try {
      if (kIsWeb) {
        // Web implementation with persistent auth
        final GoogleAuthProvider provider = GoogleAuthProvider();
        provider.addScope('email');
        // This will automatically use the persistence setting we configured
        return await _auth.signInWithPopup(provider);
      } else {
        // Mobile implementation: force account chooser
        await _googleSignIn.signOut();
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    if (Firebase.apps.isEmpty) return;

    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}
