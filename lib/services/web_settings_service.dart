import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/web_settings.dart';
import 'app_logger.dart';
import 'admin_service.dart';

class WebSettingsService {
  WebSettingsService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  static CollectionReference<Map<String, dynamic>>
      get _webSettingsCollection => _firestore.collection('web_settings');

  // Get web settings
  static Future<WebSettings> getWebSettings() async {
    try {
      final doc = await _webSettingsCollection.doc('main').get();
      if (!doc.exists) {
        // Return default settings if no document exists
        return WebSettings.defaultSettings;
      }
      return WebSettings.fromMap(doc.data()!);
    } catch (e, st) {
      AppLogger.error('webSettings.getWebSettings', e, st);
      // Return default settings on error
      return WebSettings.defaultSettings;
    }
  }

  // Get web settings as a real-time stream
  static Stream<WebSettings> getWebSettingsStream() {
    try {
      return _webSettingsCollection
          .doc('main')
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return WebSettings.defaultSettings;
        }
        return WebSettings.fromMap(snapshot.data()!);
      });
    } catch (e, st) {
      AppLogger.error('webSettings.getWebSettingsStream', e, st);
      // Return a stream with default settings on error
      return Stream.value(WebSettings.defaultSettings);
    }
  }

  // Update web settings (admin only)
  static Future<bool> updateWebSettings({
    required bool webGameEnabled,
    String? playStoreLink,
  }) async {
    try {
      if (!await AdminService.isCurrentUserAdmin()) {
        throw Exception('User is not an admin');
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final webSettings = WebSettings(
        webGameEnabled: webGameEnabled,
        playStoreLink: playStoreLink ?? WebSettings.defaultSettings.playStoreLink,
        updatedAt: DateTime.now(),
        updatedBy: user.uid,
      );

      await _webSettingsCollection.doc('main').set(webSettings.toMap());
      AppLogger.log('Web settings updated: webGameEnabled=$webGameEnabled');
      return true;
    } catch (e, st) {
      AppLogger.error('webSettings.updateWebSettings', e, st);
      return false;
    }
  }

  // Initialize default web settings
  static Future<void> initializeDefaultWebSettings() async {
    try {
      if (!await AdminService.isCurrentUserAdmin()) return;

      final doc = await _webSettingsCollection.doc('main').get();
      if (!doc.exists) {
        final defaultSettings = WebSettings.defaultSettings;
        await _webSettingsCollection.doc('main').set(defaultSettings.toMap());
        AppLogger.log('Default web settings initialized');
      }
    } catch (e, st) {
      AppLogger.error('webSettings.initializeDefaultWebSettings', e, st);
    }
  }

  // Check if web game is enabled
  static Future<bool> isWebGameEnabled() async {
    try {
      final settings = await getWebSettings();
      return settings.webGameEnabled;
    } catch (e, st) {
      AppLogger.error('webSettings.isWebGameEnabled', e, st);
      return false; // Default to disabled on error
    }
  }

  // Get play store link
  static Future<String> getPlayStoreLink() async {
    try {
      final settings = await getWebSettings();
      return settings.playStoreLink ?? WebSettings.defaultSettings.playStoreLink!;
    } catch (e, st) {
      AppLogger.error('webSettings.getPlayStoreLink', e, st);
      return WebSettings.defaultSettings.playStoreLink!;
    }
  }
}

