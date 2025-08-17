import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_logger.dart';

class AdminService {
  AdminService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection for admin roles
  static CollectionReference<Map<String, dynamic>> get _adminRolesCollection =>
      _firestore.collection('admin_roles');

  // Check if current user is an admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      if (Firebase.apps.isEmpty) return false;

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      return await isUserAdmin(currentUser.uid);
    } catch (e, st) {
      AppLogger.error('admin.isCurrentUserAdmin', e, st);
      return false;
    }
  }

  // Check if a specific user is an admin
  static Future<bool> isUserAdmin(String userId) async {
    try {
      if (Firebase.apps.isEmpty) return false;

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _adminRolesCollection.doc(userId).get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final bool isAdmin = data['isAdmin'] as bool? ?? false;

      AppLogger.log('User $userId admin check: isAdmin=$isAdmin');

      return isAdmin;
    } catch (e, st) {
      AppLogger.error('admin.isUserAdmin', e, st);
      return false;
    }
  }

  // Simple method to make current user admin (for development/testing)
  static Future<bool> makeCurrentUserAdmin() async {
    try {
      if (Firebase.apps.isEmpty) return false;

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // Create simple admin role
      await _adminRolesCollection.doc(currentUser.uid).set({
        'isAdmin': true,
        'role': 'admin',
        'grantedAt': FieldValue.serverTimestamp(),
        'notes': 'Admin access granted',
      });

      AppLogger.log('Admin role created for user ${currentUser.uid}');
      return true;
    } catch (e, st) {
      AppLogger.error('admin.makeCurrentUserAdmin', e, st);
      return false;
    }
  }
}
