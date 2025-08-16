import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalStorageService {
  LocalStorageService._();

  // Keys for local storage
  static const String _keyBestTime = 'reaction_time_best';
  static const String _keyTimesList = 'reaction_time_times';
  static const String _keyUserId = 'local_user_id';
  static const String _keyUserName = 'local_user_name';

  /// Get the best reaction time from local storage
  static Future<int?> getBestTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyBestTime);
    } catch (e) {
      print('Failed to get best time from local storage: $e');
      return null;
    }
  }

  /// Save the best reaction time to local storage
  static Future<void> saveBestTime(int time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyBestTime, time);
    } catch (e) {
      print('Failed to save best time to local storage: $e');
    }
  }

  /// Get all reaction times from local storage
  static Future<List<int>> getTimesList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> timesStrings =
          prefs.getStringList(_keyTimesList) ?? [];
      return timesStrings
          .map((s) => int.tryParse(s) ?? 0)
          .where((t) => t > 0)
          .toList();
    } catch (e) {
      print('Failed to get times list from local storage: $e');
      return [];
    }
  }

  /// Add a new reaction time to local storage
  static Future<void> addTime(int time) async {
    try {
      if (time <= 0) return; // Don't store invalid times

      final prefs = await SharedPreferences.getInstance();
      final List<String> currentTimes =
          prefs.getStringList(_keyTimesList) ?? [];
      currentTimes.add(time.toString());

      // Keep only the last 100 times to prevent storage bloat
      if (currentTimes.length > 100) {
        currentTimes.removeRange(0, currentTimes.length - 100);
      }

      await prefs.setStringList(_keyTimesList, currentTimes);
    } catch (e) {
      print('Failed to add time to local storage: $e');
    }
  }

  /// Get or create a local user ID for anonymous users
  static Future<String> getLocalUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString(_keyUserId);

      if (userId == null || userId.isEmpty) {
        // Generate a new local user ID
        userId = _generateLocalUserId();
        await prefs.setString(_keyUserId, userId);
      }

      return userId;
    } catch (e) {
      print('Failed to get local user ID: $e');
      return _generateLocalUserId();
    }
  }

  /// Get local user name (if set)
  static Future<String?> getLocalUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserName);
    } catch (e) {
      print('Failed to get local user name: $e');
      return null;
    }
  }

  /// Set local user name
  static Future<void> setLocalUserName(String? name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (name != null && name.isNotEmpty) {
        await prefs.setString(_keyUserName, name);
      } else {
        await prefs.remove(_keyUserName);
      }
    } catch (e) {
      print('Failed to set local user name: $e');
    }
  }

  /// Get local leaderboard data (top 10 scores)
  static Future<List<Map<String, dynamic>>> getLocalLeaderboard() async {
    try {
      final times = await getTimesList();
      if (times.isEmpty) return [];

      // Sort by best time (ascending for reaction time)
      times.sort();

      // Take top 10
      final topTimes = times.take(10).toList();

      // Get user name from settings
      final userName = await getLocalUserName();
      final displayName = userName ?? 'Anonymous Player';

      // Create leaderboard entries
      return topTimes.asMap().entries.map((entry) {
        final index = entry.key;
        final time = entry.value;

        return {
          'rank': index + 1,
          'time': time,
          'userId': 'local_user',
          'userName': displayName,
          'isLocal': true,
        };
      }).toList();
    } catch (e) {
      print('Failed to get local leaderboard: $e');
      return [];
    }
  }

  /// Clear all local data (useful for testing or user reset)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyBestTime);
      await prefs.remove(_keyTimesList);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserName);
    } catch (e) {
      print('Failed to clear local data: $e');
    }
  }

  /// Generate a unique local user ID
  static String _generateLocalUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'local_${timestamp}_$random';
  }

  /// Check if this is a web platform
  static bool get isWeb => kIsWeb;
}
