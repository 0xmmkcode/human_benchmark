import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  static Future<UserCredential?> signInWithGoogle() async {
    if (Firebase.apps.isEmpty) return null;

    try {
      if (kIsWeb) {
        // Web implementation
        final GoogleAuthProvider provider = GoogleAuthProvider();
        provider.addScope('email');
        return await _auth.signInWithPopup(provider);
      } else {
        // Mobile implementation
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
