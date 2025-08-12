import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  AuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

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
      final GoogleAuthProvider provider = GoogleAuthProvider();
      provider.addScope('email');
      if (kIsWeb) {
        return await _auth.signInWithPopup(provider);
      }
      return await _auth.signInWithProvider(provider);
    } catch (_) {
      return null;
    }
  }

  static Future<void> signOut() async {
    if (Firebase.apps.isEmpty) return;
    await _auth.signOut();
  }
}
