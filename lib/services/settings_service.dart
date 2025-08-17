import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_settings.dart';
import 'app_logger.dart';

class SettingsService {
  SettingsService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  static CollectionReference<Map<String, dynamic>>
  get _userSettingsCollection => _firestore.collection('user_settings');

  // Get current user ID
  static String? get _currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  static bool get isUserAuthenticated => _auth.currentUser != null;

  // Get user settings
  static Future<UserSettings?> getUserSettings() async {
    try {
      if (!isUserAuthenticated) {
        AppLogger.log('User not authenticated, cannot fetch settings');
        return null;
      }

      final userId = _currentUserId!;
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _userSettingsCollection.doc(userId).get();

      if (!doc.exists) {
        // Create default settings for new user
        final defaultSettings = UserSettings.defaults(userId);
        await _userSettingsCollection.doc(userId).set(defaultSettings.toMap());
        AppLogger.log('Created default settings for user: $userId');
        return defaultSettings;
      }

      final settings = UserSettings.fromMap(doc.data()!);
      AppLogger.log('Retrieved settings for user: $userId');
      return settings;
    } catch (e, st) {
      AppLogger.error('settings.getUserSettings', e, st);
      return null;
    }
  }

  // Stream user settings for real-time updates
  static Stream<UserSettings?> getUserSettingsStream() {
    if (!isUserAuthenticated) {
      return Stream.value(null);
    }

    final userId = _currentUserId!;
    return _userSettingsCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserSettings.fromMap(doc.data()!);
    });
  }

  // Update user settings
  static Future<bool> updateUserSettings(UserSettings settings) async {
    try {
      if (!isUserAuthenticated) {
        AppLogger.log('User not authenticated, cannot update settings');
        return false;
      }

      final userId = _currentUserId!;
      final updatedSettings = settings.copyWith(
        userId: userId,
        updatedAt: DateTime.now(),
      );

      await _userSettingsCollection.doc(userId).set(updatedSettings.toMap());
      AppLogger.log('Updated settings for user: $userId');
      return true;
    } catch (e, st) {
      AppLogger.error('settings.updateUserSettings', e, st);
      return false;
    }
  }

  // Update specific setting
  static Future<bool> updateSetting<T>(String settingKey, T value) async {
    try {
      if (!isUserAuthenticated) {
        AppLogger.log('User not authenticated, cannot update setting');
        return false;
      }

      final userId = _currentUserId!;
      final updateData = {
        settingKey: value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _userSettingsCollection.doc(userId).update(updateData);
      AppLogger.log('Updated setting $settingKey for user: $userId');
      return true;
    } catch (e, st) {
      AppLogger.error('settings.updateSetting', e, st);
      return false;
    }
  }

  // Update game-specific settings
  static Future<bool> updateGameSettings(
    String gameType,
    Map<String, dynamic> settings,
  ) async {
    try {
      if (!isUserAuthenticated) {
        AppLogger.log('User not authenticated, cannot update game settings');
        return false;
      }

      final userId = _currentUserId!;
      final updateData = {
        'gameSpecificSettings.$gameType': settings,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _userSettingsCollection.doc(userId).update(updateData);
      AppLogger.log('Updated game settings for $gameType, user: $userId');
      return true;
    } catch (e, st) {
      AppLogger.error('settings.updateGameSettings', e, st);
      return false;
    }
  }

  // Reset settings to defaults
  static Future<bool> resetToDefaults() async {
    try {
      if (!isUserAuthenticated) {
        AppLogger.log('User not authenticated, cannot reset settings');
        return false;
      }

      final userId = _currentUserId!;
      final defaultSettings = UserSettings.defaults(userId);

      await _userSettingsCollection.doc(userId).set(defaultSettings.toMap());
      AppLogger.log('Reset settings to defaults for user: $userId');
      return true;
    } catch (e, st) {
      AppLogger.error('settings.resetToDefaults', e, st);
      return false;
    }
  }

  // Delete user settings (when user deletes account)
  static Future<bool> deleteUserSettings() async {
    try {
      if (!isUserAuthenticated) {
        AppLogger.log('User not authenticated, cannot delete settings');
        return false;
      }

      final userId = _currentUserId!;
      await _userSettingsCollection.doc(userId).delete();
      AppLogger.log('Deleted settings for user: $userId');
      return true;
    } catch (e, st) {
      AppLogger.error('settings.deleteUserSettings', e, st);
      return false;
    }
  }

  // Get setting value with fallback
  static T getSettingValue<T>(
    UserSettings? settings,
    String settingKey,
    T defaultValue,
  ) {
    if (settings == null) return defaultValue;

    switch (settingKey) {
      case 'soundEnabled':
        return settings.soundEnabled as T;
      case 'vibrationEnabled':
        return settings.vibrationEnabled as T;
      case 'notificationsEnabled':
        return settings.notificationsEnabled as T;
      case 'theme':
        return settings.theme as T;
      case 'language':
        return settings.language as T;
      case 'autoSaveEnabled':
        return settings.autoSaveEnabled as T;
      case 'showTutorials':
        return settings.showTutorials as T;
      default:
        return defaultValue;
    }
  }

  // Check if setting is enabled
  static bool isSettingEnabled(UserSettings? settings, String settingKey) {
    return getSettingValue(settings, settingKey, false);
  }

  // Get theme mode
  static String getThemeMode(UserSettings? settings) {
    return getSettingValue(settings, 'theme', 'system');
  }

  // Get language
  static String getLanguage(UserSettings? settings) {
    return getSettingValue(settings, 'language', 'en');
  }

  // Get game-specific setting
  static T getGameSetting<T>(
    UserSettings? settings,
    String gameType,
    String settingKey,
    T defaultValue,
  ) {
    if (settings == null) return defaultValue;

    final gameSettings = settings.getGameSettings(gameType);
    return gameSettings[settingKey] as T? ?? defaultValue;
  }

  // Check if game setting is enabled
  static bool isGameSettingEnabled(
    UserSettings? settings,
    String gameType,
    String settingKey,
  ) {
    return getGameSetting(settings, gameType, settingKey, false);
  }

  // Export settings (for backup)
  static Map<String, dynamic> exportSettings(UserSettings settings) {
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settings.toMap(),
    };
  }

  // Import settings (from backup)
  static UserSettings? importSettings(Map<String, dynamic> data) {
    try {
      final settingsData = data['settings'] as Map<String, dynamic>?;
      if (settingsData == null) return null;

      return UserSettings.fromMap(settingsData);
    } catch (e) {
      AppLogger.error('settings.importSettings', e);
      return null;
    }
  }

  // Validate settings
  static bool validateSettings(UserSettings settings) {
    try {
      // Check required fields
      if (settings.userId.isEmpty) return false;

      // Check valid theme values
      if (!['light', 'dark', 'system'].contains(settings.theme)) return false;

      // Check valid language values
      if (!['en', 'es', 'fr', 'de'].contains(settings.language)) return false;

      // Check valid boolean values
      if (!settings.soundEnabled) return false;
      if (!settings.vibrationEnabled) return false;
      if (!settings.notificationsEnabled) return false;
      if (!settings.autoSaveEnabled) return false;
      if (!settings.showTutorials) return false;

      return true;
    } catch (e) {
      AppLogger.error('settings.validateSettings', e);
      return false;
    }
  }

  // Get settings summary for display
  static Map<String, dynamic> getSettingsSummary(UserSettings? settings) {
    if (settings == null) {
      return {
        'status': 'Not available',
        'theme': 'System',
        'language': 'English',
        'sound': 'Unknown',
        'notifications': 'Unknown',
      };
    }

    return {
      'status': 'Active',
      'theme': _getThemeDisplayName(settings.theme),
      'language': _getLanguageDisplayName(settings.language),
      'sound': settings.soundEnabled ? 'Enabled' : 'Disabled',
      'notifications': settings.notificationsEnabled ? 'Enabled' : 'Disabled',
      'lastUpdated': _formatDate(settings.updatedAt),
    };
  }

  // Helper methods for display names
  static String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System';
      default:
        return 'Unknown';
    }
  }

  static String _getLanguageDisplayName(String language) {
    switch (language) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return 'Unknown';
    }
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
