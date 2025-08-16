import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();

  // Keys for settings
  static const String _keyShowNameInLeaderboard = 'show_name_in_leaderboard';
  static const String _keyAnonymousMode = 'anonymous_mode';
  static const String _keyDisplayName = 'display_name';

  /// Get whether to show name in leaderboard
  static Future<bool> getShowNameInLeaderboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyShowNameInLeaderboard) ??
          true; // Default to true
    } catch (e) {
      print('Failed to get show name setting: $e');
      return true;
    }
  }

  /// Set whether to show name in leaderboard
  static Future<void> setShowNameInLeaderboard(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowNameInLeaderboard, value);
    } catch (e) {
      print('Failed to set show name setting: $e');
    }
  }

  /// Get anonymous mode setting
  static Future<bool> getAnonymousMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAnonymousMode) ?? false; // Default to false
    } catch (e) {
      print('Failed to get anonymous mode setting: $e');
      return false;
    }
  }

  /// Set anonymous mode setting
  static Future<void> setAnonymousMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAnonymousMode, value);
    } catch (e) {
      print('Failed to set anonymous mode setting: $e');
    }
  }

  /// Get custom display name
  static Future<String?> getDisplayName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDisplayName);
    } catch (e) {
      print('Failed to get display name: $e');
      return null;
    }
  }

  /// Set custom display name
  static Future<void> setDisplayName(String? name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (name != null && name.isNotEmpty) {
        await prefs.setString(_keyDisplayName, name);
      } else {
        await prefs.remove(_keyDisplayName);
      }
    } catch (e) {
      print('Failed to set display name: $e');
    }
  }

  /// Get the name to display in leaderboard based on settings
  static Future<String> getLeaderboardDisplayName({
    String? firebaseUserName,
    String? localUserName,
  }) async {
    try {
      final showName = await getShowNameInLeaderboard();
      if (!showName) return 'Anonymous';

      final anonymousMode = await getAnonymousMode();
      if (anonymousMode) return 'Anonymous';

      // Priority: Custom display name > Firebase user name > Local user name > Anonymous
      final customName = await getDisplayName();
      if (customName != null && customName.isNotEmpty) {
        return customName;
      }

      if (firebaseUserName != null && firebaseUserName.isNotEmpty) {
        return firebaseUserName;
      }

      if (localUserName != null && localUserName.isNotEmpty) {
        return localUserName;
      }

      return 'Anonymous';
    } catch (e) {
      print('Failed to get leaderboard display name: $e');
      return 'Anonymous';
    }
  }
}
