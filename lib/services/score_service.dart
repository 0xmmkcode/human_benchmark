import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_logger.dart';
import 'user_profile_service.dart';
import '../models/user_score.dart';
import '../models/game_score.dart';

class ScoreService {
  ScoreService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static CollectionReference<Map<String, dynamic>> get _userScoresCollection =>
      _firestore.collection('user_scores');
  static CollectionReference<Map<String, dynamic>> get _gameScoresCollection =>
      _firestore.collection('game_scores');

  // Submit a game score - now primarily uses UserProfileService
  static Future<bool> submitGameScore({
    required String gameType,
    required int score,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        AppLogger.log('Firebase not initialized, using legacy method');
        return await _submitGameScoreLegacy(
          gameType: gameType,
          score: score,
          additionalData: additionalData,
        );
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.log('No authenticated user, using legacy method');
        return await _submitGameScoreLegacy(
          gameType: gameType,
          score: score,
          additionalData: additionalData,
        );
      }

      // Try to use new UserProfileService first
      try {
        // Convert string gameType to GameType enum
        final GameType gameTypeEnum = _stringToGameType(gameType);

        await UserProfileService.submitGameScore(
          gameType: gameTypeEnum,
          score: score,
          gameData: additionalData,
        );

        AppLogger.log('Score submitted successfully via UserProfileService');
        return true;
      } catch (e) {
        AppLogger.log('UserProfileService failed, falling back to legacy: $e');
      }

      // Fallback to legacy method
      return await _submitGameScoreLegacy(
        gameType: gameType,
        score: score,
        additionalData: additionalData,
      );
    } catch (e, st) {
      AppLogger.error('score.submitGameScore', e, st);
      return false;
    }
  }

  // Helper method to convert string to GameType enum
  static GameType _stringToGameType(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'reaction_time':
      case 'reactiontime':
        return GameType.reactionTime;
      case 'number_memory':
      case 'numbermemory':
        return GameType.numberMemory;
      case 'decision_making':
      case 'decision_making':
      case 'decisionrisk':
        return GameType.decisionRisk;
      case 'personality':
      case 'personalityquiz':
        return GameType.personalityQuiz;
      case 'aim_trainer':
      case 'aimtrainer':
        return GameType.aimTrainer;
      case 'verbal_memory':
      case 'verbalmemory':
        return GameType.verbalMemory;
      case 'visual_memory':
      case 'visualmemory':
        return GameType.visualMemory;
      case 'sequence_memory':
      case 'sequencememory':
        return GameType.sequenceMemory;
      case 'chimp_test':
      case 'chimptest':
        return GameType.chimpTest;
      default:
        return GameType.reactionTime; // Default fallback
    }
  }

  // Legacy method for submitting game scores
  static Future<bool> _submitGameScoreLegacy({
    required String gameType,
    required int score,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // Convert string gameType to GameType enum
      final GameType gameTypeEnum = _stringToGameType(gameType);

      // Create GameScore using the model
      final GameScore gameScore = GameScore.create(
        userId: currentUser.uid,
        userName: currentUser.displayName,
        gameType: gameTypeEnum,
        score: score,
        gameData: additionalData,
        isHighScore: false, // Will be determined by user profile logic
      );

      // Save to game_scores collection using the model
      await _gameScoresCollection.add(gameScore.toMap());

      // Also write a simplified activity document to recent_ectivity
      try {
        await FirebaseFirestore.instance.collection('recent_ectivity').add({
          'userId': currentUser.uid,
          'userName': currentUser.displayName,
          'gameType': gameTypeEnum.name,
          'gameName': GameScore.getDisplayName(gameTypeEnum),
          'score': score,
          'playedAt': FieldValue.serverTimestamp(),
          'isHighScore': false,
        });
      } catch (_) {
        // Non-fatal; dashboard can fall back to game_scores
      }

      // Update user_scores collection
      final userScoreRef = _userScoresCollection.doc(currentUser.uid);
      final userScoreDoc = await userScoreRef.get();

      if (userScoreDoc.exists) {
        // Update existing user score
        final currentData = userScoreDoc.data()!;
        final currentScores = Map<String, dynamic>.from(
          currentData['gameScores'] ?? {},
        );

        // Update game-specific stats
        if (currentScores[gameType] == null) {
          currentScores[gameType] = {
            'highScore': score,
            'totalGames': 1,
            'averageScore': score.toDouble(),
            'lastPlayed': FieldValue.serverTimestamp(),
            'firstPlayed': FieldValue.serverTimestamp(),
          };
        } else {
          final gameStats = Map<String, dynamic>.from(currentScores[gameType]);
          final currentHighScore = gameStats['highScore'] ?? 0;
          final currentTotalGames = gameStats['totalGames'] ?? 0;
          final currentAverage = gameStats['averageScore'] ?? 0.0;

          gameStats['highScore'] = score > currentHighScore
              ? score
              : currentHighScore;
          gameStats['totalGames'] = currentTotalGames + 1;
          gameStats['averageScore'] =
              ((currentAverage * currentTotalGames) + score) /
              (currentTotalGames + 1);
          gameStats['lastPlayed'] = FieldValue.serverTimestamp();

          currentScores[gameType] = gameStats;
        }

        // Update overall stats
        final totalGames = (currentData['totalGames'] ?? 0) + 1;
        final totalScore = (currentData['totalScore'] ?? 0) + score;
        final averageScore = totalScore / totalGames;

        await userScoreRef.update({
          'gameScores': currentScores,
          'totalGames': totalGames,
          'totalScore': totalScore,
          'averageScore': averageScore,
          'lastActive': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new user score document
        final userScoreData = {
          'userId': currentUser.uid,
          'email': currentUser.email,
          'displayName': currentUser.displayName,
          'photoURL': currentUser.photoURL,
          'gameScores': {
            gameType: {
              'highScore': score,
              'totalGames': 1,
              'averageScore': score.toDouble(),
              'lastPlayed': FieldValue.serverTimestamp(),
              'firstPlayed': FieldValue.serverTimestamp(),
            },
          },
          'totalGames': 1,
          'totalScore': score,
          'averageScore': score.toDouble(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await userScoreRef.set(userScoreData);
      }

      AppLogger.log('Score submitted successfully via legacy method');
      return true;
    } catch (e, st) {
      AppLogger.error('score._submitGameScoreLegacy', e, st);
      return false;
    }
  }

  // Get user's high score for a specific game - now uses UserProfileService
  static Future<int> getUserHighScore(String gameType) async {
    try {
      if (Firebase.apps.isEmpty) {
        return await _getUserHighScoreLegacy(gameType);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 0;

      // Try to use new UserProfileService first
      try {
        final gameTypeEnum = _stringToGameType(gameType);
        final highScore = await UserProfileService.getUserHighScore(
          gameTypeEnum,
        );
        return highScore;
      } catch (e) {
        AppLogger.log('UserProfileService failed, falling back to legacy: $e');
      }

      // Fallback to legacy method
      return await _getUserHighScoreLegacy(gameType);
    } catch (e, st) {
      AppLogger.error('score.getUserHighScore', e, st);
      return 0;
    }
  }

  // Legacy method for getting user high score
  static Future<int> _getUserHighScoreLegacy(String gameType) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 0;

      final doc = await _userScoresCollection.doc(currentUser.uid).get();
      if (!doc.exists) return 0;

      final data = doc.data()!;
      final gameScores = data['gameScores'] as Map<String, dynamic>?;
      if (gameScores == null || gameScores[gameType] == null) return 0;

      return gameScores[gameType]['highScore'] ?? 0;
    } catch (e, st) {
      AppLogger.error('score._getUserHighScoreLegacy', e, st);
      return 0;
    }
  }

  // Get reaction time statistics - now uses UserProfileService
  static Future<Map<String, dynamic>> getReactionTimeStats() async {
    try {
      if (Firebase.apps.isEmpty) {
        return await _getReactionTimeStatsLegacy();
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return {};

      // Try to use new UserProfileService first
      try {
        final gameStats = await UserProfileService.getUserGameStats(
          GameType.reactionTime,
        );
        return {
          'highScore': gameStats.highScore,
          'totalGames': gameStats.totalGames,
          'averageScore': gameStats.averageScore,
          'lastPlayed': gameStats.lastPlayed,
          'firstPlayed': gameStats.firstPlayed,
        };
      } catch (e) {
        AppLogger.log('UserProfileService failed, falling back to legacy: $e');
      }

      // Fallback to legacy method
      return await _getReactionTimeStatsLegacy();
    } catch (e, st) {
      AppLogger.error('score.getReactionTimeStats', e, st);
      return {};
    }
  }

  // Legacy method for getting reaction time stats
  static Future<Map<String, dynamic>> _getReactionTimeStatsLegacy() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return {};

      final doc = await _userScoresCollection.doc(currentUser.uid).get();
      if (!doc.exists) return {};

      final data = doc.data()!;
      final gameScores = data['gameScores'] as Map<String, dynamic>?;
      if (gameScores == null || gameScores['reaction_time'] == null) return {};

      return gameScores['reaction_time'];
    } catch (e, st) {
      AppLogger.error('score._getReactionTimeStatsLegacy', e, st);
      return {};
    }
  }

  // Update reaction time average - now uses UserProfileService
  static Future<void> updateReactionTimeAverage(int newScore) async {
    try {
      if (Firebase.apps.isEmpty) {
        await _updateReactionTimeAverageLegacy(newScore);
        return;
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Try to use new UserProfileService first
      try {
        await UserProfileService.submitGameScore(
          gameType: GameType.reactionTime,
          score: newScore,
        );
        return;
      } catch (e) {
        AppLogger.log('UserProfileService failed, falling back to legacy: $e');
      }

      // Fallback to legacy method
      await _updateReactionTimeAverageLegacy(newScore);
    } catch (e, st) {
      AppLogger.error('score.updateReactionTimeAverage', e, st);
    }
  }

  // Legacy method for updating reaction time average
  static Future<void> _updateReactionTimeAverageLegacy(int newScore) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userScoreRef = _userScoresCollection.doc(currentUser.uid);
      final userScoreDoc = await userScoreRef.get();

      if (userScoreDoc.exists) {
        final currentData = userScoreDoc.data()!;
        final gameScores = Map<String, dynamic>.from(
          currentData['gameScores'] ?? {},
        );

        if (gameScores['reaction_time'] == null) {
          gameScores['reaction_time'] = {
            'highScore': newScore,
            'totalGames': 1,
            'averageScore': newScore.toDouble(),
            'lastPlayed': FieldValue.serverTimestamp(),
            'firstPlayed': FieldValue.serverTimestamp(),
          };
        } else {
          final currentStats = Map<String, dynamic>.from(
            gameScores['reaction_time'],
          );
          final currentHighScore = currentStats['highScore'] ?? 0;
          final currentTotalGames = currentStats['totalGames'] ?? 0;
          final currentAverage = currentStats['averageScore'] ?? 0.0;

          currentStats['highScore'] = newScore > currentHighScore
              ? newScore
              : currentHighScore;
          currentStats['totalGames'] = currentTotalGames + 1;
          currentStats['averageScore'] =
              ((currentAverage * currentTotalGames) + newScore) /
              (currentTotalGames + 1);
          currentStats['lastPlayed'] = FieldValue.serverTimestamp();

          gameScores['reaction_time'] = currentStats;
        }

        await userScoreRef.update({
          'gameScores': gameScores,
          'lastActive': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e, st) {
      AppLogger.error('score._updateReactionTimeAverageLegacy', e, st);
    }
  }

  // Initialize reaction time stats - now uses UserProfileService
  static Future<void> initializeReactionTimeStats() async {
    try {
      if (Firebase.apps.isEmpty) {
        await _initializeReactionTimeStatsLegacy();
        return;
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Try to use new UserProfileService first
      try {
        await UserProfileService.getOrCreateUserProfile();
        return;
      } catch (e) {
        AppLogger.log('UserProfileService failed, falling back to legacy: $e');
      }

      // Fallback to legacy method
      await _initializeReactionTimeStatsLegacy();
    } catch (e, st) {
      AppLogger.error('score.initializeReactionTimeStats', e, st);
    }
  }

  // Legacy method for initializing reaction time stats
  static Future<void> _initializeReactionTimeStatsLegacy() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userScoreRef = _userScoresCollection.doc(currentUser.uid);
      final userScoreDoc = await userScoreRef.get();

      if (!userScoreDoc.exists) {
        await userScoreRef.set({
          'userId': currentUser.uid,
          'email': currentUser.email,
          'displayName': currentUser.displayName,
          'photoURL': currentUser.photoURL,
          'gameScores': {
            'reaction_time': {
              'highScore': 0,
              'totalGames': 0,
              'averageScore': 0.0,
              'lastPlayed': null,
              'firstPlayed': null,
            },
          },
          'totalGames': 0,
          'totalScore': 0,
          'averageScore': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e, st) {
      AppLogger.error('score._initializeReactionTimeStatsLegacy', e, st);
    }
  }

  // Get user's recent scores as a stream - kept for backward compatibility
  static Stream<List<Map<String, dynamic>>> getUserRecentScoresStream(
    String gameType, {
    int limit = 10,
  }) {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value([]);

      return _gameScoresCollection
          .where('userId', isEqualTo: currentUser.uid)
          .where('gameType', isEqualTo: gameType)
          .orderBy('playedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e, st) {
      AppLogger.error('score.getUserRecentScoresStream', e, st);
      return Stream.value([]);
    }
  }

  // Get user's recent scores - now uses UserProfileService
  static Future<List<Map<String, dynamic>>> getUserRecentScores(
    String gameType, {
    int limit = 10,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        return await _getUserRecentScoresLegacy(gameType, limit);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      // Try to use new UserProfileService first
      try {
        final gameTypeEnum = _stringToGameType(gameType);
        final recentScores = await UserProfileService.getUserRecentScores(
          gameTypeEnum,
          limit: limit,
        );
        return recentScores.map((score) => score.toMap()).toList();
      } catch (e) {
        AppLogger.log('UserProfileService failed, falling back to legacy: $e');
      }

      // Fallback to legacy method
      return await _getUserRecentScoresLegacy(gameType, limit);
    } catch (e, st) {
      AppLogger.error('score.getUserRecentScores', e, st);
      return [];
    }
  }

  // Legacy method for getting user recent scores
  static Future<List<Map<String, dynamic>>> _getUserRecentScoresLegacy(
    String gameType,
    int limit,
  ) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final querySnapshot = await _gameScoresCollection
          .where('userId', isEqualTo: currentUser.uid)
          .where('gameType', isEqualTo: gameType)
          .orderBy('playedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e, st) {
      AppLogger.error('score._getUserRecentScoresLegacy', e, st);
      return [];
    }
  }

  // Get top scores for a specific game type
  static Future<List<GameScore>> getTopScores({
    required GameType gameType,
    int limit = 10,
  }) async {
    try {
      if (Firebase.apps.isEmpty) return [];

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await _gameScoresCollection
              .where('gameType', isEqualTo: gameType.name)
              .orderBy('score', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => GameScore.fromMap(doc.data()))
          .toList();
    } catch (e, st) {
      AppLogger.error('score.getTopScores', e, st);
      return [];
    }
  }

  // Get recent game activities for a user
  static Future<List<GameScore>> getRecentActivities({int limit = 10}) async {
    try {
      if (Firebase.apps.isEmpty) return [];

      final String userId = await _getUserId();
      if (userId.isEmpty) return [];

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await _gameScoresCollection
              .where('userId', isEqualTo: userId)
              .orderBy('playedAt', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => GameScore.fromMap(doc.data()))
          .toList(growable: false);
    } catch (e, st) {
      AppLogger.error('score.getRecentActivities', e, st);
      return [];
    }
  }

  // Get user's complete score profile
  static Future<UserScore?> getUserScoreProfile() async {
    try {
      if (Firebase.apps.isEmpty) return null;

      // Prefer new UserProfileService source of truth
      try {
        final userProfile = await UserProfileService.getOrCreateUserProfile();
        // Map UserProfile to UserScore for UI compatibility
        final Map<GameType, int> highScores = {};
        final Map<GameType, int> totalGamesPlayed = {};
        final Map<GameType, DateTime> lastPlayedAt = {};

        for (final gameType in GameType.values) {
          final stats = userProfile.getGameStats(gameType);
          highScores[gameType] = stats.highScore;
          totalGamesPlayed[gameType] = stats.totalGames;
          if (stats.lastPlayed != null) {
            lastPlayedAt[gameType] = stats.lastPlayed!;
          }
        }

        return UserScore(
          userId: userProfile.uid,
          userName: userProfile.displayName,
          highScores: highScores,
          totalGamesPlayed: totalGamesPlayed,
          lastPlayedAt: lastPlayedAt,
          createdAt: userProfile.createdAt,
          updatedAt: userProfile.updatedAt,
        );
      } catch (_) {
        // Fallback to legacy collection if mapping fails
      }

      final String userId = await _getUserId();
      if (userId.isEmpty) return null;

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _userScoresCollection.doc(userId).get();

      if (!doc.exists) return null;

      return UserScore.fromMap(doc.data()!);
    } catch (e, st) {
      AppLogger.error('score.getUserProfile', e, st);
      return null;
    }
  }

  // Get leaderboard for a specific game - now uses UserProfileService
  static Future<List<UserScore>> getGameLeaderboard(
    String gameType, {
    int limit = 100,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        return await _getGameLeaderboardLegacy(gameType, limit);
      }

      // Try to use new UserProfileService first
      try {
        final gameTypeEnum = _stringToGameType(gameType);
        final leaderboardStream = UserProfileService.getGameLeaderboard(
          gameTypeEnum,
          limit: limit,
        );
        final leaderboard = await leaderboardStream.first;

        // Sort by best score (for reaction time, lower is better)
        final sortedLeaderboard = leaderboard.toList()
          ..sort((a, b) {
            final aStats = a.getGameStats(gameTypeEnum);
            final bStats = b.getGameStats(gameTypeEnum);

            if (gameTypeEnum == GameType.reactionTime) {
              // For reaction time, lower scores are better
              return aStats.highScore.compareTo(bStats.highScore);
            } else {
              // For other games, higher scores are better
              return bStats.highScore.compareTo(aStats.highScore);
            }
          });

        return sortedLeaderboard.map((profile) {
          final gameStats = profile.getGameStats(gameTypeEnum);
          return UserScore(
            userId: profile.uid,
            userName: profile.displayName,
            highScores: {gameTypeEnum: gameStats.highScore},
            totalGamesPlayed: {gameTypeEnum: gameStats.totalGames},
            lastPlayedAt: {
              gameTypeEnum: gameStats.lastPlayed ?? DateTime.now(),
            },
            createdAt: profile.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      } catch (e) {
        AppLogger.log('UserProfileService failed, falling back to legacy: $e');
      }

      // Fallback to legacy method
      return await _getGameLeaderboardLegacy(gameType, limit);
    } catch (e, st) {
      AppLogger.error('score.getGameLeaderboard', e, st);
      return [];
    }
  }

  // Legacy method for getting game leaderboard
  static Future<List<UserScore>> _getGameLeaderboardLegacy(
    String gameType,
    int limit,
  ) async {
    try {
      final querySnapshot = await _userScoresCollection
          .where('gameScores.$gameType.highScore', isGreaterThan: 0)
          .orderBy(
            'gameScores.$gameType.highScore',
            descending: false,
          ) // Always ascending for consistent sorting
          .limit(limit)
          .get();

      final List<UserScore> leaderboard = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final gameStats = data['gameScores']?[gameType];
        final gameTypeEnum = _stringToGameType(gameType);
        return UserScore(
          userId: doc.id,
          userName: data['displayName'] ?? 'Player',
          highScores: {gameTypeEnum: gameStats?['highScore'] ?? 0},
          totalGamesPlayed: {gameTypeEnum: gameStats?['totalGames'] ?? 0},
          lastPlayedAt: {gameTypeEnum: DateTime.now()},
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      // Sort by best score (for reaction time, lower is better)
      leaderboard.sort((a, b) {
        final aScore = a.getHighScore(_stringToGameType(gameType));
        final bScore = b.getHighScore(_stringToGameType(gameType));

        if (gameType == 'reaction_time') {
          // For reaction time, lower scores are better
          return aScore.compareTo(bScore);
        } else {
          // For other games, higher scores are better
          return bScore.compareTo(aScore);
        }
      });

      return leaderboard;
    } catch (e, st) {
      AppLogger.error('score._getGameLeaderboardLegacy', e, st);
      return [];
    }
  }

  // Get overall leaderboard across all games
  static Stream<List<UserScore>> getOverallLeaderboard({int limit = 100}) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value([]);
      }

      return _userScoresCollection
          .orderBy('totalScore', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserScore.fromMap(doc.data()))
                .toList(),
          );
    } catch (e, st) {
      AppLogger.error('score.getOverallLeaderboard', e, st);
      return Stream.value([]);
    }
  }

  // Get reaction time leaderboard specifically (lower scores are better)
  static Future<List<UserScore>> getReactionTimeLeaderboard({
    int limit = 100,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        return await _getReactionTimeLeaderboardLegacy(limit);
      }

      // Try to use new UserProfileService first
      try {
        final leaderboardStream = UserProfileService.getGameLeaderboard(
          GameType.reactionTime,
          limit: limit,
        );
        final leaderboard = await leaderboardStream.first;

        // Sort by best reaction time (lower is better)
        final sortedLeaderboard = leaderboard.toList()
          ..sort((a, b) {
            final aStats = a.getGameStats(GameType.reactionTime);
            final bStats = b.getGameStats(GameType.reactionTime);
            return aStats.highScore.compareTo(bStats.highScore);
          });

        return sortedLeaderboard.map((profile) {
          final gameStats = profile.getGameStats(GameType.reactionTime);
          return UserScore(
            userId: profile.uid,
            userName: profile.displayName,
            highScores: {GameType.reactionTime: gameStats.highScore},
            totalGamesPlayed: {GameType.reactionTime: gameStats.totalGames},
            lastPlayedAt: {
              GameType.reactionTime: gameStats.lastPlayed ?? DateTime.now(),
            },
            createdAt: profile.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      } catch (e) {
        AppLogger.log('UserProfileService failed, falling back to legacy: $e');
      }

      // Fallback to legacy method
      return await _getReactionTimeLeaderboardLegacy(limit);
    } catch (e, st) {
      AppLogger.error('score.getReactionTimeLeaderboard', e, st);
      return [];
    }
  }

  // Legacy method for getting reaction time leaderboard
  static Future<List<UserScore>> _getReactionTimeLeaderboardLegacy(
    int limit,
  ) async {
    try {
      final querySnapshot = await _userScoresCollection
          .where('gameScores.reaction_time.highScore', isGreaterThan: 0)
          .orderBy(
            'gameScores.reaction_time.highScore',
            descending: false,
          ) // Ascending for reaction time (lower is better)
          .limit(limit)
          .get();

      final List<UserScore> leaderboard = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final gameStats = data['gameScores']?['reaction_time'];
        return UserScore(
          userId: doc.id,
          userName: data['displayName'] ?? 'Player',
          highScores: {GameType.reactionTime: gameStats?['highScore'] ?? 0},
          totalGamesPlayed: {
            GameType.reactionTime: gameStats?['totalGames'] ?? 0,
          },
          lastPlayedAt: {GameType.reactionTime: DateTime.now()},
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      // Sort by best reaction time (lower is better)
      leaderboard.sort((a, b) {
        final aScore = a.getHighScore(GameType.reactionTime);
        final bScore = b.getHighScore(GameType.reactionTime);
        return aScore.compareTo(bScore);
      });

      return leaderboard;
    } catch (e, st) {
      AppLogger.error('score._getReactionTimeLeaderboardLegacy', e, st);
      return [];
    }
  }

  // Get reaction time statistics as a real-time stream
  static Stream<Map<String, dynamic>> getReactionTimeStatsStream() {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value({});
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value({});

      return _userScoresCollection
          .doc(currentUser.uid)
          .snapshots()
          .map<Map<String, dynamic>>((doc) {
            if (!doc.exists) return <String, dynamic>{};

            final data = doc.data()!;
            final gameScores = data['gameScores'] as Map<String, dynamic>?;
            if (gameScores == null || gameScores['reaction_time'] == null)
              return <String, dynamic>{};

            return gameScores['reaction_time'] as Map<String, dynamic>;
          })
          .handleError((error, stackTrace) {
            AppLogger.error(
              'score.getReactionTimeStatsStream',
              error,
              stackTrace,
            );
            return <String, dynamic>{};
          });
    } catch (e, st) {
      AppLogger.error('score.getReactionTimeStatsStream', e, st);
      return Stream.value({});
    }
  }

  // Get user's high score as a real-time stream
  static Stream<int> getUserHighScoreStream(String gameType) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(0);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value(0);

      return _userScoresCollection
          .doc(currentUser.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return 0;

            final data = doc.data()!;
            final gameScores = data['gameScores'] as Map<String, dynamic>?;
            if (gameScores == null || gameScores[gameType] == null) return 0;

            return (gameScores[gameType]['highScore'] as num?)?.toInt() ?? 0;
          })
          .handleError((error, stackTrace) {
            AppLogger.error('score.getUserHighScoreStream', error, stackTrace);
            return 0;
          });
    } catch (e, st) {
      AppLogger.error('score.getUserHighScoreStream', e, st);
      return Stream.value(0);
    }
  }

  // Get user's complete score profile as a real-time stream
  static Stream<UserScore?> getUserScoreProfileStream() {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(null);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value(null);

      return _userScoresCollection
          .doc(currentUser.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;

            try {
              return UserScore.fromMap(doc.data()!);
            } catch (e) {
              AppLogger.error('score.parseUserScoreProfile', e, null);
              return null;
            }
          })
          .handleError((error, stackTrace) {
            AppLogger.error(
              'score.getUserScoreProfileStream',
              error,
              stackTrace,
            );
            return null;
          });
    } catch (e, st) {
      AppLogger.error('score.getUserScoreProfileStream', e, st);
      return Stream.value(null);
    }
  }

  // Get game leaderboard as a real-time stream
  static Stream<List<UserScore>> getGameLeaderboardStream({
    required GameType gameType,
    int limit = 100,
  }) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value([]);
      }

      // Determine sorting order based on game type
      final bool descending = _shouldSortDescending(gameType);
      final String gameTypeField = 'gameScores.${gameType.name}.highScore';

      return _userScoresCollection
          .orderBy(gameTypeField, descending: descending)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) {
                  try {
                    return UserScore.fromMap(doc.data());
                  } catch (e) {
                    AppLogger.error('score.parseGameLeaderboard', e, null);
                    return null;
                  }
                })
                .where((score) => score != null)
                .cast<UserScore>()
                .toList(),
          )
          .handleError((error, stackTrace) {
            AppLogger.error(
              'score.getGameLeaderboardStream',
              error,
              stackTrace,
            );
            return <UserScore>[];
          });
    } catch (e, st) {
      AppLogger.error('score.getGameLeaderboardStream', e, st);
      return Stream.value([]);
    }
  }

  // Get overall leaderboard as a real-time stream (enhanced version)
  static Stream<List<UserScore>> getOverallLeaderboardStream({
    int limit = 100,
  }) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value([]);
      }

      return _userScoresCollection
          .orderBy('totalScore', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) {
                  try {
                    return UserScore.fromMap(doc.data());
                  } catch (e) {
                    AppLogger.error('score.parseOverallLeaderboard', e, null);
                    return null;
                  }
                })
                .where((score) => score != null)
                .cast<UserScore>()
                .toList(),
          )
          .handleError((error, stackTrace) {
            AppLogger.error(
              'score.getOverallLeaderboardStream',
              error,
              stackTrace,
            );
            return <UserScore>[];
          });
    } catch (e, st) {
      AppLogger.error('score.getOverallLeaderboardStream', e, st);
      return Stream.value([]);
    }
  }

  // Get user's ranking in a specific game as a real-time stream
  static Stream<int> getUserRankingStream({
    required GameType gameType,
    int limit = 1000, // Higher limit to get accurate ranking
  }) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(-1);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value(-1);

      // Determine sorting order based on game type
      final bool descending = _shouldSortDescending(gameType);
      final String gameTypeField = 'gameScores.${gameType.name}.highScore';

      return _userScoresCollection
          .orderBy(gameTypeField, descending: descending)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            final userIndex = snapshot.docs.indexWhere(
              (doc) => doc.id == currentUser.uid,
            );
            return userIndex >= 0 ? userIndex + 1 : -1;
          })
          .handleError((error, stackTrace) {
            AppLogger.error('score.getUserRankingStream', error, stackTrace);
            return -1;
          });
    } catch (e, st) {
      AppLogger.error('score.getUserRankingStream', e, st);
      return Stream.value(-1);
    }
  }

  // Get user's total games played as a real-time stream
  static Stream<int> getUserTotalGamesStream() {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(0);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value(0);

      return _userScoresCollection
          .doc(currentUser.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return 0;

            final data = doc.data()!;
            return (data['totalGames'] as num?)?.toInt() ?? 0;
          })
          .handleError((error, stackTrace) {
            AppLogger.error('score.getUserTotalGamesStream', error, stackTrace);
            return 0;
          });
    } catch (e, st) {
      AppLogger.error('score.getUserTotalGamesStream', e, st);
      return Stream.value(0);
    }
  }

  // Get user's average score as a real-time stream
  static Stream<double> getUserAverageScoreStream() {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(0.0);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value(0.0);

      return _userScoresCollection
          .doc(currentUser.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return 0.0;

            final data = doc.data()!;
            return (data['averageScore'] as num?)?.toDouble() ?? 0.0;
          })
          .handleError((error, stackTrace) {
            AppLogger.error(
              'score.getUserAverageScoreStream',
              error,
              stackTrace,
            );
            return 0.0;
          });
    } catch (e, st) {
      AppLogger.error('score.getUserAverageScoreStream', e, st);
      return Stream.value(0.0);
    }
  }

  // Get user's last played date as a real-time stream
  static Stream<DateTime?> getUserLastPlayedStream() {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(null);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value(null);

      return _userScoresCollection
          .doc(currentUser.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;

            final data = doc.data()!;
            final lastActive = data['lastActive'];
            if (lastActive is Timestamp) {
              return lastActive.toDate();
            }
            return null;
          })
          .handleError((error, stackTrace) {
            AppLogger.error('score.getUserLastPlayedStream', error, stackTrace);
            return null;
          });
    } catch (e, st) {
      AppLogger.error('score.getUserLastPlayedStream', e, st);
      return Stream.value(null);
    }
  }

  // Private helper methods
  static Future<String> _getUserId() async {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      return FirebaseAuth.instance.currentUser!.uid;
    }
    return '';
  }

  static bool _shouldSortDescending(GameType gameType) {
    return gameType == GameType.reactionTime;
  }
}
