import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_management.dart';
import 'app_logger.dart';

class GameManagementService {
  GameManagementService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  static CollectionReference<Map<String, dynamic>>
  get _gameManagementCollection => _firestore.collection('game_management');

  // Get all game management settings
  static Future<List<GameManagement>> getAllGameSettings() async {
    try {
      final snapshot = await _gameManagementCollection.get();

      if (snapshot.docs.isEmpty) {
        // Initialize with default games if collection is empty
        await _initializeDefaultGames();
        return GameManagement.defaultGames;
      }

      return snapshot.docs
          .map((doc) => GameManagement.fromMap(doc.data()))
          .toList();
    } catch (e, st) {
      AppLogger.error('gameManagement.getAllGameSettings', e, st);
      return GameManagement.defaultGames;
    }
  }

  // Get game setting by ID
  static Future<GameManagement?> getGameSetting(String gameId) async {
    try {
      final doc = await _gameManagementCollection.doc(gameId).get();
      if (!doc.exists) return null;

      return GameManagement.fromMap(doc.data()!);
    } catch (e, st) {
      AppLogger.error('gameManagement.getGameSetting', e, st);
      return null;
    }
  }

  // Check if a game is enabled
  static Future<bool> isGameEnabled(String gameId) async {
    try {
      final gameSetting = await getGameSetting(gameId);
      return gameSetting?.isEnabled ?? false;
    } catch (e, st) {
      AppLogger.error('gameManagement.isGameEnabled', e, st);
      return false; // Default to disabled on error
    }
  }

  // Update game enabled status
  static Future<bool> updateGameStatus(String gameId, bool isEnabled) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.log('No authenticated user for game status update');
        return false;
      }

      final now = FieldValue.serverTimestamp();
      await _gameManagementCollection.doc(gameId).update({
        'isEnabled': isEnabled,
        'updatedAt': now,
        'updatedBy': currentUser.uid,
      });

      AppLogger.log(
        'Game $gameId ${isEnabled ? 'enabled' : 'disabled'} by ${currentUser.uid}',
      );
      return true;
    } catch (e, st) {
      AppLogger.error('gameManagement.updateGameStatus', e, st);
      return false;
    }
  }

  // Get all enabled games
  static Future<List<GameManagement>> getEnabledGames() async {
    try {
      final allGames = await getAllGameSettings();
      return allGames.where((game) => game.isEnabled).toList();
    } catch (e, st) {
      AppLogger.error('gameManagement.getEnabledGames', e, st);
      return GameManagement.defaultGames
          .where((game) => game.isEnabled)
          .toList();
    }
  }

  // Stream of enabled games for real-time updates
  static Stream<List<GameManagement>> getEnabledGamesStream() {
    try {
      return _gameManagementCollection
          .where('isEnabled', isEqualTo: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => GameManagement.fromMap(doc.data()))
                .toList(),
          );
    } catch (e, st) {
      AppLogger.error('gameManagement.getEnabledGamesStream', e, st);
      // Return a stream with default enabled games on error
      return Stream.value(
        GameManagement.defaultGames.where((game) => game.isEnabled).toList(),
      );
    }
  }

  // Stream of all game settings for real-time updates
  static Stream<List<GameManagement>> getAllGameSettingsStream() {
    try {
      return _gameManagementCollection.snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) {
          // Return default games if collection is empty
          return GameManagement.defaultGames;
        }
        return snapshot.docs
            .map((doc) => GameManagement.fromMap(doc.data()))
            .toList();
      });
    } catch (e, st) {
      AppLogger.error('gameManagement.getAllGameSettingsStream', e, st);
      // Return a stream with default games on error
      return Stream.value(GameManagement.defaultGames);
    }
  }

  // Get all disabled games
  static Future<List<GameManagement>> getDisabledGames() async {
    try {
      final allGames = await getAllGameSettings();
      return allGames.where((game) => !game.isEnabled).toList();
    } catch (e, st) {
      AppLogger.error('gameManagement.getDisabledGames', e, st);
      return GameManagement.defaultGames
          .where((game) => !game.isEnabled)
          .toList();
    }
  }

  // Initialize default games in Firestore
  static Future<void> _initializeDefaultGames() async {
    try {
      AppLogger.log('Initializing default games in Firestore...');

      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      for (final game in GameManagement.defaultGames) {
        final gameData = game.toMap();
        gameData['createdAt'] = now;
        gameData['updatedAt'] = now;

        batch.set(_gameManagementCollection.doc(game.gameId), gameData);
      }

      await batch.commit();
      AppLogger.log('Default games initialized successfully');
    } catch (e, st) {
      AppLogger.error('gameManagement.initializeDefaultGames', e, st);
    }
  }

  // Reset all games to default state
  static Future<bool> resetToDefaults() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.log('No authenticated user for reset operation');
        return false;
      }

      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      for (final game in GameManagement.defaultGames) {
        final gameData = game.toMap();
        gameData['createdAt'] = now;
        gameData['updatedAt'] = now;
        gameData['updatedBy'] = currentUser.uid;

        batch.set(_gameManagementCollection.doc(game.gameId), gameData);
      }

      await batch.commit();
      AppLogger.log('Games reset to defaults by ${currentUser.uid}');
      return true;
    } catch (e, st) {
      AppLogger.error('gameManagement.resetToDefaults', e, st);
      return false;
    }
  }

  // Bulk update game statuses
  static Future<bool> bulkUpdateGameStatuses(
    Map<String, bool> gameStatuses,
  ) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.log('No authenticated user for bulk update');
        return false;
      }

      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      for (final entry in gameStatuses.entries) {
        batch.update(_gameManagementCollection.doc(entry.key), {
          'isEnabled': entry.value,
          'updatedAt': now,
          'updatedBy': currentUser.uid,
        });
      }

      await batch.commit();
      AppLogger.log('Bulk game status update completed by ${currentUser.uid}');
      return true;
    } catch (e, st) {
      AppLogger.error('gameManagement.bulkUpdateGameStatuses', e, st);
      return false;
    }
  }
}
