import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_profile.dart';
import '../models/user_score.dart';
import '../models/game_score.dart';
import 'app_logger.dart';

class MigrationService {
  MigrationService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');
  static CollectionReference<Map<String, dynamic>> get _userScoresCollection =>
      _firestore.collection('user_scores');
  static CollectionReference<Map<String, dynamic>> get _gameScoresCollection =>
      _firestore.collection('game_scores');

  // Migrate all existing user data to new structure
  static Future<void> migrateAllUserData() async {
    try {
      if (Firebase.apps.isEmpty) {
        AppLogger.log('Firebase not initialized, skipping migration');
        return;
      }

      AppLogger.log('Starting migration of all user data...');

      // Get all existing user scores
      final QuerySnapshot<Map<String, dynamic>> userScoresSnapshot =
          await _userScoresCollection.get();

      int migratedCount = 0;
      int errorCount = 0;

      for (final doc in userScoresSnapshot.docs) {
        try {
          final String uid = doc.id;
          final userScoreData = doc.data();

          // Check if migration is already done for this user
          final DocumentSnapshot<Map<String, dynamic>> userDoc =
              await _usersCollection.doc(uid).get();

          if (userDoc.exists) {
            final data = userDoc.data()!;
            if (data['migrationCompleted'] == true) {
              AppLogger.log('Migration already completed for user: $uid');
              continue;
            }
          }

          // Get user's game scores
          final QuerySnapshot<Map<String, dynamic>> gameScoresSnapshot =
              await _gameScoresCollection
                  .where('userId', isEqualTo: uid)
                  .orderBy('playedAt', descending: true)
                  .get();

          // Create new user profile
          final UserProfile newProfile = await _createUserProfileFromLegacyData(
            uid: uid,
            userScoreData: userScoreData,
            gameScoresData: gameScoresSnapshot.docs
                .map((doc) => doc.data())
                .toList(),
          );

          // Save new profile
          await _usersCollection.doc(uid).set(newProfile.toMap());

          // Mark migration as completed
          await _usersCollection.doc(uid).update({
            'migrationCompleted': true,
            'migratedAt': FieldValue.serverTimestamp(),
            'migratedFrom': 'legacy_user_scores',
          });

          migratedCount++;
          AppLogger.log('Successfully migrated user: $uid');
        } catch (e) {
          errorCount++;
          AppLogger.error('migration.user.$doc.id', e);
          AppLogger.log('Failed to migrate user ${doc.id}: $e');
        }
      }

      AppLogger.log(
        'Migration completed. Successfully migrated: $migratedCount, Errors: $errorCount',
      );
    } catch (e, st) {
      AppLogger.error('migration.allUsers', e, st);
      AppLogger.log('Failed to migrate all user data: $e');
    }
  }

  // Migrate specific user data
  static Future<bool> migrateUserData(String uid) async {
    try {
      if (Firebase.apps.isEmpty) return false;

      // Check if migration is already done
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _usersCollection.doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data['migrationCompleted'] == true) {
          AppLogger.log('Migration already completed for user: $uid');
          return true;
        }
      }

      // Get existing user scores
      final DocumentSnapshot<Map<String, dynamic>> userScoreDoc =
          await _userScoresCollection.doc(uid).get();

      if (!userScoreDoc.exists) {
        AppLogger.log('No legacy data found for user: $uid');
        return false;
      }

      final userScoreData = userScoreDoc.data()!;

      // Get user's game scores
      final QuerySnapshot<Map<String, dynamic>> gameScoresSnapshot =
          await _gameScoresCollection
              .where('userId', isEqualTo: uid)
              .orderBy('playedAt', descending: true)
              .get();

      // Create new user profile
      final UserProfile newProfile = await _createUserProfileFromLegacyData(
        uid: uid,
        userScoreData: userScoreData,
        gameScoresData: gameScoresSnapshot.docs
            .map((doc) => doc.data())
            .toList(),
      );

      // Save new profile
      await _usersCollection.doc(uid).set(newProfile.toMap());

      // Mark migration as completed
      await _usersCollection.doc(uid).update({
        'migrationCompleted': true,
        'migratedAt': FieldValue.serverTimestamp(),
        'migratedFrom': 'legacy_user_scores',
      });

      AppLogger.log('Successfully migrated user: $uid');
      return true;
    } catch (e, st) {
      AppLogger.error('migration.user.$uid', e, st);
      AppLogger.log('Failed to migrate user $uid: $e');
      return false;
    }
  }

  // Create user profile from legacy data
  static Future<UserProfile> _createUserProfileFromLegacyData({
    required String uid,
    required Map<String, dynamic> userScoreData,
    required List<Map<String, dynamic>> gameScoresData,
  }) async {
    // Get user auth data if available
    String? email;
    String? displayName;
    String? photoURL;

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        email = user.email;
        displayName = user.displayName;
        photoURL = user.photoURL;
      }
    } catch (e) {
      AppLogger.log('Could not get user auth data: $e');
    }

    // Parse legacy data
    final Map<GameType, GameStats> gameStats = {};
    final Map<GameType, List<GameScore>> recentScores = {};

    // Parse high scores and stats from legacy user_scores
    for (final gameType in GameType.values) {
      final gameTypeName = gameType.name;

      if (userScoreData['highScores']?[gameTypeName] != null) {
        final highScore = (userScoreData['highScores'][gameTypeName] as num)
            .toInt();
        final totalGames =
            (userScoreData['totalGamesPlayed']?[gameTypeName] as num?)
                ?.toInt() ??
            1;

        // Calculate average from game scores if available
        double averageScore = highScore.toDouble();
        final gameScoresForType = gameScoresData
            .where((score) => score['gameType'] == gameTypeName)
            .map((score) => (score['score'] as num).toInt())
            .toList();

        if (gameScoresForType.isNotEmpty) {
          averageScore =
              gameScoresForType.reduce((a, b) => a + b) /
              gameScoresForType.length;
        }

        // Get last played date
        DateTime? lastPlayed;
        if (userScoreData['lastPlayedAt']?[gameTypeName] != null) {
          final timestamp = userScoreData['lastPlayedAt'][gameTypeName];
          if (timestamp is Timestamp) {
            lastPlayed = timestamp.toDate();
          }
        }

        gameStats[gameType] = GameStats(
          highScore: highScore,
          totalGames: totalGames,
          averageScore: averageScore,
          lastPlayed: lastPlayed,
          firstPlayed: lastPlayed ?? DateTime.now(),
        );
      }
    }

    // Parse recent game scores
    for (final gameScoreData in gameScoresData.take(100)) {
      // Limit to last 100 scores
      try {
        final gameScore = GameScore.fromMap(gameScoreData);
        final gameType = gameScore.gameType;

        if (!recentScores.containsKey(gameType)) {
          recentScores[gameType] = [];
        }

        // Keep only the most recent 10 scores per game type
        if (recentScores[gameType]!.length < 10) {
          recentScores[gameType]!.add(gameScore);
        }
      } catch (e) {
        AppLogger.log('Failed to parse game score: $e');
      }
    }

    // Calculate overall stats
    int totalGamesPlayed = 0;
    int overallScore = 0;

    for (final stats in gameStats.values) {
      totalGamesPlayed += stats.totalGames;
      overallScore += stats.highScore;
    }

    // Get last game played
    DateTime? lastGamePlayed;
    for (final stats in gameStats.values) {
      if (stats.lastPlayed != null) {
        if (lastGamePlayed == null ||
            stats.lastPlayed!.isAfter(lastGamePlayed)) {
          lastGamePlayed = stats.lastPlayed;
        }
      }
    }

    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      gameStats: gameStats,
      recentScores: recentScores,
      totalGamesPlayed: totalGamesPlayed,
      overallScore: overallScore,
      lastGamePlayed: lastGamePlayed,
    );
  }

  // Clean up legacy collections after successful migration
  static Future<void> cleanupLegacyData() async {
    try {
      if (Firebase.apps.isEmpty) return;

      AppLogger.log('Starting cleanup of legacy data...');

      // Note: This is destructive and should only be run after confirming
      // all data has been successfully migrated
      AppLogger.log('WARNING: This will delete all legacy data collections!');
      AppLogger.log('Only run this after confirming successful migration.');

      // For safety, this is commented out by default
      // Uncomment only after thorough testing and confirmation

      /*
      // Delete legacy collections
      await _firestore.runTransaction((transaction) async {
        // Delete user_scores collection
        final userScoresSnapshot = await _userScoresCollection.get();
        for (final doc in userScoresSnapshot.docs) {
          transaction.delete(doc.reference);
        }
        
        // Delete game_scores collection
        final gameScoresSnapshot = await _gameScoresCollection.get();
        for (final doc in gameScoresSnapshot.docs) {
          transaction.delete(doc.reference);
        }
      });
      
      AppLogger.log('Legacy data cleanup completed');
      */

      AppLogger.log('Legacy data cleanup skipped for safety');
    } catch (e, st) {
      AppLogger.error('migration.cleanup', e, st);
      AppLogger.log('Failed to cleanup legacy data: $e');
    }
  }

  // Get migration status
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      if (Firebase.apps.isEmpty) return {};

      // Check if user is authenticated
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return {
          'error': 'User not authenticated. Please sign in first.',
          'totalUsers': 0,
          'migratedUsers': 0,
          'pendingUsers': 0,
          'migrationProgress': 0,
          'isComplete': false,
        };
      }

      try {
        // Try to get total users from legacy collection
        int totalUsers = 0;
        try {
          final userScoresSnapshot = await _userScoresCollection.get();
          totalUsers = userScoresSnapshot.docs.length;
          AppLogger.log(
            'Successfully read legacy user_scores collection: $totalUsers users',
          );
        } catch (e) {
          AppLogger.log('Could not read legacy user_scores collection: $e');
          return {
            'error':
                'Cannot access legacy user data. Check if user_scores collection exists and you have read permissions.',
            'totalUsers': 0,
            'migratedUsers': 0,
            'pendingUsers': 0,
            'migrationProgress': 0,
            'isComplete': false,
          };
        }

        // Try to get migrated users count
        int migratedUsers = 0;
        try {
          final migratedSnapshot = await _usersCollection
              .where('migrationCompleted', isEqualTo: true)
              .get();
          migratedUsers = migratedSnapshot.docs.length;
          AppLogger.log(
            'Successfully read users collection: $migratedUsers migrated users',
          );
        } catch (e) {
          AppLogger.log('Could not read migrated users count: $e');
          if (e.toString().contains('permission-denied')) {
            return {
              'error':
                  'Permission denied accessing users collection. This usually means:\n'
                  '• Firestore security rules need to be updated\n'
                  '• Rules have not been deployed yet\n'
                  '• You need to wait for rules to take effect (2-5 minutes)\n\n'
                  'Legacy users found: $totalUsers\n'
                  'Action: Deploy updated firestore.rules and wait for propagation.',
              'totalUsers': totalUsers,
              'migratedUsers': 0,
              'pendingUsers': totalUsers,
              'migrationProgress': 0,
              'isComplete': false,
            };
          } else {
            return {
              'error':
                  'Error reading users collection: $e\n\n'
                  'Legacy users found: $totalUsers\n'
                  'Action: Check database connection and permissions.',
              'totalUsers': totalUsers,
              'migratedUsers': 0,
              'pendingUsers': totalUsers,
              'migrationProgress': 0,
              'isComplete': false,
            };
          }
        }

        return {
          'totalUsers': totalUsers,
          'migratedUsers': migratedUsers,
          'pendingUsers': totalUsers - migratedUsers,
          'migrationProgress': totalUsers > 0
              ? (migratedUsers / totalUsers * 100).round()
              : 0,
          'isComplete': migratedUsers >= totalUsers,
          'error': null,
        };
      } catch (e) {
        AppLogger.log('Error reading migration status: $e');
        return {
          'error':
              'Unexpected error reading migration status: $e\n\n'
              'Action: Check console logs and database connection.',
          'totalUsers': 0,
          'migratedUsers': 0,
          'pendingUsers': 0,
          'migrationProgress': 0,
          'isComplete': false,
        };
      }
    } catch (e, st) {
      AppLogger.error('migration.status', e, st);
      return {
        'error':
            'Migration status check failed: $e\n\n'
            'Action: Check authentication and try again.',
        'totalUsers': 0,
        'migratedUsers': 0,
        'pendingUsers': 0,
        'migrationProgress': 0,
        'isComplete': false,
      };
    }
  }
}
