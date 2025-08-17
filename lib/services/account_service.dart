import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_logger.dart';

class AccountService {
  AccountService._();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update user's display name
  static Future<bool> updateDisplayName(String newDisplayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update Firebase Auth display name
      await user.updateDisplayName(newDisplayName);

      // Update user_scores collection if it exists
      try {
        await _firestore
            .collection('user_scores')
            .doc(user.uid)
            .update({
          'userName': newDisplayName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // User scores might not exist yet, that's okay
        AppLogger.log('User scores collection not found, skipping update');
      }

      // Update game_scores collection
      try {
        final gameScoresQuery = await _firestore
            .collection('game_scores')
            .where('userId', isEqualTo: user.uid)
            .get();

        final batch = _firestore.batch();
        for (final doc in gameScoresQuery.docs) {
          batch.update(doc.reference, {
            'userName': newDisplayName,
          });
        }
        await batch.commit();
      } catch (e) {
        // Game scores might not exist yet, that's okay
        AppLogger.log('Game scores collection not found, skipping update');
      }

      AppLogger.log('Display name updated successfully: $newDisplayName');
      return true;
    } catch (e, st) {
      AppLogger.error('account.updateDisplayName', e, st);
      return false;
    }
  }

  // Update user's birthday
  static Future<bool> updateBirthday(DateTime birthday) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Store birthday in user_scores collection
      await _firestore
          .collection('user_scores')
          .doc(user.uid)
          .set({
        'birthday': Timestamp.fromDate(birthday),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.log('Birthday updated successfully: ${birthday.toIso8601String()}');
      return true;
    } catch (e, st) {
      AppLogger.error('account.updateBirthday', e, st);
      return false;
    }
  }

  // Get user's birthday
  static Future<DateTime?> getBirthday() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('user_scores')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['birthday'] != null) {
        final timestamp = doc.data()!['birthday'] as Timestamp;
        return timestamp.toDate();
      }
      return null;
    } catch (e, st) {
      AppLogger.error('account.getBirthday', e, st);
      return null;
    }
  }

  // Delete user account and all associated data
  static Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;

      // Delete user_scores
      try {
        await _firestore.collection('user_scores').doc(userId).delete();
      } catch (e) {
        AppLogger.log('User scores not found or already deleted');
      }

      // Delete game_scores
      try {
        final gameScoresQuery = await _firestore
            .collection('game_scores')
            .where('userId', isEqualTo: userId)
            .get();

        final batch = _firestore.batch();
        for (final doc in gameScoresQuery.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        AppLogger.log('Game scores not found or already deleted');
      }

      // Delete personality results
      try {
        final personalityResultsQuery = await _firestore
            .collection('users')
            .doc(userId)
            .collection('personalityResults')
            .get();

        final batch = _firestore.batch();
        for (final doc in personalityResultsQuery.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        AppLogger.log('Personality results not found or already deleted');
      }

      // Delete user settings
      try {
        await _firestore.collection('user_settings').doc(userId).delete();
      } catch (e) {
        AppLogger.log('User settings not found or already deleted');
      }

      // Delete the Firebase Auth user
      await user.delete();

      AppLogger.log('Account deleted successfully');
      return true;
    } catch (e, st) {
      AppLogger.error('account.deleteAccount', e, st);
      return false;
    }
  }

  // Get current user's display name
  static String? getCurrentDisplayName() {
    return _auth.currentUser?.displayName;
  }

  // Check if user has a display name set
  static bool hasDisplayName() {
    final displayName = _auth.currentUser?.displayName;
    return displayName != null && displayName.isNotEmpty;
  }
}
