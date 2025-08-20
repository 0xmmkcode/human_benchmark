import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_management.dart';
import 'app_logger.dart';
import 'admin_service.dart';

class GameManagementService {
  GameManagementService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference<Map<String, dynamic>>
  get _gameManagementCollection => _firestore.collection('game_management');

  // Check if user is admin
  static Future<bool> isUserAdmin() async {
    try {
      return await AdminService.isCurrentUserAdmin();
    } catch (e, st) {
      AppLogger.error('gameManagement.isUserAdmin', e, st);
      return false;
    }
  }

  // (Dev utility) Grant admin role to current user via AdminService
  static Future<bool> makeCurrentUserAdmin() async {
    try {
      return await AdminService.makeCurrentUserAdmin();
    } catch (e, st) {
      AppLogger.error('gameManagement.makeCurrentUserAdmin', e, st);
      return false;
    }
  }

  // Get all game management settings
  static Future<List<GameManagement>> getAllGameManagement() async {
    try {
      final querySnapshot = await _gameManagementCollection.get();
      return querySnapshot.docs
          .map((doc) => GameManagement.fromMap(doc.data()))
          .toList();
    } catch (e, st) {
      AppLogger.error('gameManagement.getAllGameManagement', e, st);
      return [];
    }
  }

  // Get all game management settings as a real-time stream for live updates
  static Stream<List<GameManagement>> getAllGameManagementStream() {
    try {
      return _gameManagementCollection
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GameManagement.fromMap(doc.data()))
              .toList());
    } catch (e, st) {
      AppLogger.error('gameManagement.getAllGameManagementStream', e, st);
      // Return a stream with empty list on error
      return Stream.value(<GameManagement>[]);
    }
  }

  // Get game management for a specific game
  static Future<GameManagement?> getGameManagement(String gameId) async {
    try {
      final doc = await _gameManagementCollection.doc(gameId).get();
      if (!doc.exists) return null;
      return GameManagement.fromMap(doc.data()!);
    } catch (e, st) {
      AppLogger.error('gameManagement.getGameManagement', e, st);
      return null;
    }
  }

  // Check if a game is accessible
  static Future<bool> isGameAccessible(String gameId) async {
    try {
      final gameManagement = await getGameManagement(gameId);
      if (gameManagement == null)
        return true; // Default to accessible if no management record

      return gameManagement.isAccessible &&
          !gameManagement.isBlockedTemporarily;
    } catch (e, st) {
      AppLogger.error('gameManagement.isGameAccessible', e, st);
      return false; // Default to blocked on error
    }
  }

  // Check if a game should be visible in menu
  static Future<bool> isGameVisible(String gameId) async {
    try {
      final gameManagement = await getGameManagement(gameId);
      if (gameManagement == null)
        return true; // Default to visible if no management record

      return gameManagement.isActive;
    } catch (e, st) {
      AppLogger.error('gameManagement.isGameVisible', e, st);
      return false; // Default to hidden on error
    }
  }

  // Update game status (admin only)
  static Future<bool> updateGameStatus({
    required String gameId,
    required GameStatus status,
    String? reason,
    DateTime? blockedUntil,
  }) async {
    try {
      if (!await isUserAdmin()) {
        throw Exception('User is not an admin');
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final gameManagement = GameManagement(
        gameId: gameId,
        gameName: _getGameDisplayName(gameId),
        status: status,
        reason: reason,
        blockedUntil: blockedUntil,
        updatedAt: DateTime.now(),
        updatedBy: user.uid,
      );

      await _gameManagementCollection.doc(gameId).set(gameManagement.toMap());
      AppLogger.log('Game status updated: $gameId -> ${status.name}');
      return true;
    } catch (e, st) {
      AppLogger.error('gameManagement.updateGameStatus', e, st);
      return false;
    }
  }

  // Initialize default game management records
  static Future<void> initializeDefaultGames() async {
    try {
      if (!await isUserAdmin()) return;

      final defaultGames = [
        'reaction_time',
        'number_memory',
        'decision_making',
        'personality_quiz',
        'aim_trainer',
        'verbal_memory',
        'visual_memory',
        'typing_speed',
        'sequence_memory',
        'chimp_test',
      ];

      final batch = _firestore.batch();
      final user = _auth.currentUser;

      for (final gameId in defaultGames) {
        final docRef = _gameManagementCollection.doc(gameId);
        final existingDoc = await docRef.get();

        if (!existingDoc.exists) {
          final gameManagement = GameManagement(
            gameId: gameId,
            gameName: _getGameDisplayName(gameId),
            status: GameStatus.active,
            updatedAt: DateTime.now(),
            updatedBy: user?.uid ?? 'system',
          );
          batch.set(docRef, gameManagement.toMap());
        }
      }

      await batch.commit();
      AppLogger.log('Default game management records initialized');
    } catch (e, st) {
      AppLogger.error('gameManagement.initializeDefaultGames', e, st);
    }
  }

  // Get accessible games for menu
  static Future<List<String>> getAccessibleGames() async {
    try {
      final allGames = await getAllGameManagement();
      return allGames
          .where((game) => game.isAccessible && !game.isBlockedTemporarily)
          .map((game) => game.gameId)
          .toList();
    } catch (e, st) {
      AppLogger.error('gameManagement.getAccessibleGames', e, st);
      return [];
    }
  }

  // Get accessible games as a real-time stream for live updates
  static Stream<List<String>> getAccessibleGamesStream() {
    try {
      return _gameManagementCollection
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GameManagement.fromMap(doc.data()))
              .where((game) => game.isAccessible && !game.isBlockedTemporarily)
              .map((game) => game.gameId)
              .toList());
    } catch (e, st) {
      AppLogger.error('gameManagement.getAccessibleGamesStream', e, st);
      // Return a stream with empty list on error
      return Stream.value(<String>[]);
    }
  }

  // Get visible games for menu
  static Future<List<String>> getVisibleGames() async {
    try {
      final allGames = await getAllGameManagement();
      return allGames
          .where((game) => game.isActive)
          .map((game) => game.gameId)
          .toList();
    } catch (e, st) {
      AppLogger.error('gameManagement.getVisibleGames', e, st);
      return [];
    }
  }

  // Get visible games as a real-time stream for live updates
  static Stream<List<String>> getVisibleGamesStream() {
    try {
      return _gameManagementCollection
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GameManagement.fromMap(doc.data()))
              .where((game) => game.isActive)
              .map((game) => game.gameId)
              .toList());
    } catch (e, st) {
      AppLogger.error('gameManagement.getVisibleGamesStream', e, st);
      // Return a stream with empty list on error
      return Stream.value(<String>[]);
    }
  }

  // Get visible games in fixed order for consistent navigation
  static Future<List<String>> getVisibleGamesInOrder() async {
    try {
      final allGames = await getAllGameManagement();
      final activeGames = allGames
          .where((game) => game.isActive)
          .map((game) => game.gameId)
          .toList();

      // Define the complete fixed order for ALL games
      final completeFixedOrder = [
        'reaction_time',      // 1. Reaction Time
        'personality_quiz',   // 2. Personality Quiz
        'number_memory',      // 3. Number Memory
        'chimp_test',         // 4. Chimp Test
        'decision_making',    // 5. Decision Making
        'aim_trainer',        // 6. Aim Trainer
        'verbal_memory',      // 7. Verbal Memory
        'visual_memory',      // 8. Visual Memory
        'typing_speed',       // 9. Typing Speed
        'sequence_memory',    // 10. Sequence Memory
      ];

      // Start with games in fixed order (if they're active)
      final orderedGames = <String>[];
      for (final gameId in completeFixedOrder) {
        if (activeGames.contains(gameId)) {
          orderedGames.add(gameId);
        }
      }

      // Add any other active games that aren't in the fixed order (future games)
      for (final gameId in activeGames) {
        if (!completeFixedOrder.contains(gameId)) {
          orderedGames.add(gameId);
        }
      }

      return orderedGames;
    } catch (e, st) {
      AppLogger.error('gameManagement.getVisibleGamesInOrder', e, st);
      return [];
    }
  }

  // Get visible games in fixed order as a real-time stream
  static Stream<List<String>> getVisibleGamesInOrderStream() {
    try {
      return _gameManagementCollection
          .snapshots()
          .map((snapshot) {
            final allGames = snapshot.docs
                .map((doc) => GameManagement.fromMap(doc.data()))
                .toList();
            
            final activeGames = allGames
                .where((game) => game.isActive)
                .map((game) => game.gameId)
                .toList();

            // Define the complete fixed order for ALL games
            final completeFixedOrder = [
              'reaction_time',      // 1. Reaction Time
              'personality_quiz',   // 2. Personality Quiz
              'number_memory',      // 3. Number Memory
              'chimp_test',         // 4. Chimp Test
              'decision_making',    // 5. Decision Making
              'aim_trainer',        // 6. Aim Trainer
              'verbal_memory',      // 7. Verbal Memory
              'visual_memory',      // 8. Visual Memory
              'typing_speed',       // 9. Typing Speed
              'sequence_memory',    // 10. Sequence Memory
            ];

            // Start with games in fixed order (if they're active)
            final orderedGames = <String>[];
            for (final gameId in completeFixedOrder) {
              if (activeGames.contains(gameId)) {
                orderedGames.add(gameId);
              }
            }

            // Add any other active games that aren't in the fixed order (future games)
            for (final gameId in activeGames) {
              if (!completeFixedOrder.contains(gameId)) {
                orderedGames.add(gameId);
              }
            }

            return orderedGames;
          });
    } catch (e, st) {
      AppLogger.error('gameManagement.getVisibleGamesInOrderStream', e, st);
      // Return a stream with empty list on error
      return Stream.value(<String>[]);
    }
  }

  // Get the order index of a game (for consistent positioning)
  static int getGameOrderIndex(String gameId) {
    // Define the complete fixed order for ALL games
    final completeFixedOrder = [
      'reaction_time',      // 0. Reaction Time
      'personality_quiz',   // 1. Personality Quiz
      'number_memory',      // 2. Number Memory
      'chimp_test',         // 3. Chimp Test
      'decision_making',    // 4. Decision Making
      'aim_trainer',        // 5. Aim Trainer
      'verbal_memory',      // 6. Verbal Memory
      'visual_memory',      // 7. Visual Memory
      'typing_speed',       // 8. Typing Speed
      'sequence_memory',    // 9. Sequence Memory
    ];

    final index = completeFixedOrder.indexOf(gameId);
    return index >= 0 ? index : completeFixedOrder.length; // Unknown games go to the end
  }

  // Get the complete list of all games in order (regardless of status)
  static List<String> getAllGamesInOrder() {
    return [
      'reaction_time',      // 0. Reaction Time
      'personality_quiz',   // 1. Personality Quiz
      'number_memory',      // 2. Number Memory
      'chimp_test',         // 3. Chimp Test
      'decision_making',    // 4. Decision Making
      'aim_trainer',        // 5. Aim Trainer
      'verbal_memory',      // 6. Verbal Memory
      'visual_memory',      // 7. Visual Memory
      'typing_speed',       // 8. Typing Speed
      'sequence_memory',    // 9. Sequence Memory
    ];
  }

  // Helper method to get game display names
  static String _getGameDisplayName(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return 'Reaction Time';
      case 'number_memory':
        return 'Number Memory';
      case 'decision_making':
        return 'Decision Making';
      case 'personality_quiz':
        return 'Personality Quiz';
      case 'aim_trainer':
        return 'Aim Trainer';
      case 'verbal_memory':
        return 'Verbal Memory';
      case 'visual_memory':
        return 'Visual Memory';
      case 'typing_speed':
        return 'Typing Speed';
      case 'sequence_memory':
        return 'Sequence Memory';
      case 'chimp_test':
        return 'Chimp Test';
      default:
        return gameId
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : '',
            )
            .join(' ');
    }
  }

  // Get game status with reason
  static Future<Map<String, dynamic>?> getGameStatusInfo(String gameId) async {
    try {
      final gameManagement = await getGameManagement(gameId);
      if (gameManagement == null) return null;

      return {
        'status': gameManagement.status.name,
        'reason': gameManagement.reason,
        'blockedUntil': gameManagement.blockedUntil,
        'isAccessible': gameManagement.isAccessible,
        'isVisible': gameManagement.isActive,
      };
    } catch (e, st) {
      AppLogger.error('gameManagement.getGameStatusInfo', e, st);
      return null;
    }
  }
}
