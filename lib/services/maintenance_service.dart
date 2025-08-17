import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:human_benchmark/services/app_logger.dart';

class MaintenanceService {
  static const String _maintenanceCollection = 'app_settings';
  static const String _maintenanceDoc = 'maintenance';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache the maintenance status to avoid repeated Firestore calls
  static bool? _cachedMaintenanceStatus;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Check if the app is currently in maintenance mode
  static Future<bool> isMaintenanceMode() async {
    try {
      // Check cache first
      if (_cachedMaintenanceStatus != null && _lastCacheTime != null) {
        final timeSinceCache = DateTime.now().difference(_lastCacheTime!);
        if (timeSinceCache < _cacheValidDuration) {
          return _cachedMaintenanceStatus!;
        }
      }

      // If Firebase is not available, return false (app is available)
      if (Firebase.apps.isEmpty) {
        AppLogger.log(
          'Firebase not available, assuming app is not in maintenance mode',
        );
        return false;
      }

      // Fetch maintenance status from Firestore
      final doc = await _firestore
          .collection(_maintenanceCollection)
          .doc(_maintenanceDoc)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final isMaintenance = data?['isMaintenanceMode'] ?? false;
        final maintenanceMessage =
            data?['maintenanceMessage'] ?? 'App is under maintenance';

        // Cache the result
        _cachedMaintenanceStatus = isMaintenance;
        _lastCacheTime = DateTime.now();

        if (isMaintenance) {
          AppLogger.log('Maintenance mode detected: $maintenanceMessage');
        }

        return isMaintenance;
      }

      // No maintenance document found, app is available
      _cachedMaintenanceStatus = false;
      _lastCacheTime = DateTime.now();
      return false;
    } catch (e, st) {
      AppLogger.error('maintenance.checkStatus', e, st);

      // On error, assume app is available (fail-safe)
      return false;
    }
  }

  /// Get maintenance message if app is in maintenance mode
  static Future<String> getMaintenanceMessage() async {
    try {
      if (Firebase.apps.isEmpty) {
        return 'App is temporarily unavailable';
      }

      final doc = await _firestore
          .collection(_maintenanceCollection)
          .doc(_maintenanceDoc)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['maintenanceMessage'] ?? 'App is under maintenance';
      }

      return 'App is under maintenance';
    } catch (e, st) {
      AppLogger.error('maintenance.getMessage', e, st);
      return 'App is temporarily unavailable';
    }
  }

  /// Clear the maintenance status cache (useful for testing)
  static void clearCache() {
    _cachedMaintenanceStatus = null;
    _lastCacheTime = null;
  }

  /// Check if maintenance mode is enabled (synchronous, uses cache)
  static bool get isMaintenanceModeSync {
    if (_cachedMaintenanceStatus == null || _lastCacheTime == null) {
      return false; // Not cached, assume not in maintenance
    }

    final timeSinceCache = DateTime.now().difference(_lastCacheTime!);
    if (timeSinceCache >= _cacheValidDuration) {
      // Cache expired, clear it
      clearCache();
      return false;
    }

    return _cachedMaintenanceStatus!;
  }
}
