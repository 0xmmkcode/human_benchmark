import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_profile.dart';
import '../models/game_score.dart';
import '../models/user_score.dart';
import 'app_logger.dart';

class UserProfileService {
  UserProfileService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  static CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Get or create user profile
  static Future<UserProfile> getOrCreateUserProfile() async {
    try {
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase not initialized');
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final String uid = currentUser.uid;
      final DocumentSnapshot<Map<String, dynamic>> doc = await _usersCollection
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      } else {
        // Create new user profile
        final UserProfile newProfile = UserProfile.fromFirebaseUser(
          currentUser,
        );
        await _usersCollection.doc(uid).set(newProfile.toMap());
        return newProfile;
      }
    } catch (e, st) {
      AppLogger.error('userProfile.getOrCreate', e, st);
      rethrow;
    }
  }

  // Get user profile
  static Future<UserProfile?> getUserProfile(String uid) async {
    try {
      if (Firebase.apps.isEmpty) return null;

      final DocumentSnapshot<Map<String, dynamic>> doc = await _usersCollection
          .doc(uid)
          .get();
      if (!doc.exists) return null;

      return UserProfile.fromMap(doc.data()!);
    } catch (e, st) {
      AppLogger.error('userProfile.get', e, st);
      return null;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(UserProfile profile) async {
    try {
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase not initialized');
      }

      await _usersCollection.doc(profile.uid).set(profile.toMap());
      AppLogger.log('User profile updated successfully');
    } catch (e, st) {
      AppLogger.error('userProfile.update', e, st);
      rethrow;
    }
  }

  // Update specific profile fields
  static Future<void> updateProfileFields({
    required String uid,
    String? displayName,
    DateTime? birthday,
    String? country,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase not initialized');
      }

      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
      }
      if (birthday != null) {
        updates['birthday'] = Timestamp.fromDate(birthday);
      }
      if (country != null) {
        updates['country'] = country;
      }

      await _usersCollection.doc(uid).update(updates);
      AppLogger.log('Profile fields updated successfully');
    } catch (e, st) {
      AppLogger.error('userProfile.updateFields', e, st);
      rethrow;
    }
  }

  // Submit game score and update user profile
  static Future<void> submitGameScore({
    required GameType gameType,
    required int score,
    Map<String, dynamic>? gameData,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        AppLogger.log('Firebase not initialized, skipping score submission');
        return;
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.log('User not authenticated, skipping score submission');
        return;
      }

      final String uid = currentUser.uid;

      // Get current user profile
      final UserProfile currentProfile = await getOrCreateUserProfile();

      // Create game score
      final GameScore gameScore = GameScore.create(
        userId: uid,
        userName: currentProfile.displayName,
        gameType: gameType,
        score: score,
        gameData: gameData,
        isHighScore: false, // Will be determined below
      );

      // Get current game stats
      final GameStats currentStats = currentProfile.getGameStats(gameType);

      // Determine if this is a high score
      final bool isHighScore = _isHighScore(
        gameType,
        score,
        currentStats.highScore,
      );

      // Update game stats (respect game-specific high score direction)
      final int newTotalGames = currentStats.totalGames + 1;
      final double newAverageScore =
          ((currentStats.averageScore * currentStats.totalGames) + score) /
          newTotalGames;
      final bool descending = _shouldSortDescending(gameType);
      final int newHighScore = descending
          ? (score > currentStats.highScore ? score : currentStats.highScore)
          : ((currentStats.highScore == 0 || score < currentStats.highScore)
                ? score
                : currentStats.highScore);

      final GameStats updatedStats = currentStats.copyWith(
        highScore: newHighScore,
        totalGames: newTotalGames,
        averageScore: newAverageScore,
        lastPlayed: DateTime.now(),
        firstPlayed: currentStats.firstPlayed ?? DateTime.now(),
      );

      // Update user profile
      UserProfile updatedProfile = currentProfile
          .updateGameStats(gameType, updatedStats)
          .addGameScore(gameType, gameScore);

      // Recalculate overall stats
      updatedProfile = _recalculateOverallStats(updatedProfile);

      // Persist game activity for recent activity feeds
      try {
        await FirebaseFirestore.instance
            .collection('game_scores')
            .add(gameScore.toMap());
      } catch (_) {
        // Non-fatal: recent activity list will fall back to existing data
      }

      // Update the profile in Firestore
      await updateUserProfile(updatedProfile);

      AppLogger.event('score.submitted', {
        'userId': uid,
        'gameType': gameType.name,
        'score': score,
        'isHighScore': isHighScore,
      });
    } catch (e, st) {
      AppLogger.error('userProfile.submitScore', e, st);
      // Don't rethrow - we want the app to continue working
    }
  }

  // Get user's high score for a specific game
  static Future<int> getUserHighScore(GameType gameType) async {
    try {
      final UserProfile? profile = await getOrCreateUserProfile();
      return profile?.getHighScore(gameType) ?? 0;
    } catch (e, st) {
      AppLogger.error('userProfile.getHighScore', e, st);
      return 0;
    }
  }

  // Get user's game stats for a specific game
  static Future<GameStats> getUserGameStats(GameType gameType) async {
    try {
      final UserProfile? profile = await getOrCreateUserProfile();
      return profile?.getGameStats(gameType) ?? GameStats.empty();
    } catch (e, st) {
      AppLogger.error('userProfile.getGameStats', e, st);
      return GameStats.empty();
    }
  }

  // Get user's recent scores for a specific game
  static Future<List<GameScore>> getUserRecentScores(
    GameType gameType, {
    int limit = 10,
  }) async {
    try {
      final UserProfile? profile = await getOrCreateUserProfile();
      final scores = profile?.getRecentScores(gameType) ?? [];
      return scores.take(limit).toList();
    } catch (e, st) {
      AppLogger.error('userProfile.getRecentScores', e, st);
      return [];
    }
  }

  // Get leaderboard for a specific game
  static Stream<List<UserProfile>> getGameLeaderboard(
    GameType gameType, {
    int limit = 10,
  }) {
    if (Firebase.apps.isEmpty) {
      return Stream<List<UserProfile>>.value(const <UserProfile>[]);
    }

    AppLogger.event('leaderboard.game', {
      'gameType': gameType.name,
      'limit': limit,
    });

    // Determine sorting order based on game type
    final bool descending = _shouldSortDescending(gameType);

    return _usersCollection
        .orderBy('gameStats.${gameType.name}.highScore', descending: descending)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map((doc) => UserProfile.fromMap(doc.data()))
              .toList(growable: false);
        });
  }

  // Get overall leaderboard
  static Stream<List<UserProfile>> getOverallLeaderboard({int limit = 10}) {
    if (Firebase.apps.isEmpty) {
      return Stream<List<UserProfile>>.value(const <UserProfile>[]);
    }

    AppLogger.event('leaderboard.overall', {'limit': limit});

    return _usersCollection
        .orderBy('overallScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map((doc) => UserProfile.fromMap(doc.data()))
              .toList(growable: false);
        });
  }

  // Get user's ranking in a specific game
  static Future<int> getUserRanking(GameType gameType) async {
    try {
      if (Firebase.apps.isEmpty) return 0;

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 0;

      final String uid = currentUser.uid;

      // Determine sorting order based on game type
      final bool descending = _shouldSortDescending(gameType);

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _usersCollection
              .orderBy(
                'gameStats.${gameType.name}.highScore',
                descending: descending,
              )
              .get();

      final int userIndex = snapshot.docs.indexWhere(
        (doc) => doc.data()['uid'] == uid,
      );

      return userIndex >= 0 ? userIndex + 1 : 0;
    } catch (e, st) {
      AppLogger.error('userProfile.getUserRanking', e, st);
      return 0;
    }
  }

  // Migrate existing user data to new structure
  static Future<void> migrateUserData() async {
    try {
      if (Firebase.apps.isEmpty) return;

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final String uid = currentUser.uid;

      // Check if migration is already done
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _usersCollection.doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data['migrationCompleted'] == true) {
          AppLogger.log('Migration already completed for user: $uid');
          return;
        }
      }

      // Get existing user scores
      final CollectionReference<Map<String, dynamic>> userScoresCollection =
          _firestore.collection('user_scores');
      final DocumentSnapshot<Map<String, dynamic>> userScoreDoc =
          await userScoresCollection.doc(uid).get();

      if (userScoreDoc.exists) {
        final userScoreData = userScoreDoc.data()!;
        final UserProfile newProfile = UserProfile.fromFirebaseUser(
          currentUser,
        );

        // Migrate high scores and stats
        final Map<GameType, GameStats> migratedStats = {};
        final Map<GameType, List<GameScore>> migratedScores = {};

        for (final gameType in GameType.values) {
          final gameTypeName = gameType.name;

          if (userScoreData['highScores']?[gameTypeName] != null) {
            final highScore = (userScoreData['highScores'][gameTypeName] as num)
                .toInt();
            final totalGames =
                (userScoreData['totalGamesPlayed']?[gameTypeName] as num?)
                    ?.toInt() ??
                1;
            final averageScore = highScore
                .toDouble(); // Simplified for migration

            migratedStats[gameType] = GameStats(
              highScore: highScore,
              totalGames: totalGames,
              averageScore: averageScore,
              lastPlayed: DateTime.now(),
              firstPlayed: DateTime.now(),
            );
          }
        }

        final migratedProfile = newProfile.copyWith(
          gameStats: migratedStats,
          recentScores: migratedScores,
        );

        // Save migrated profile
        await updateUserProfile(migratedProfile);

        // Mark migration as completed
        await _usersCollection.doc(uid).update({
          'migrationCompleted': true,
          'migratedAt': FieldValue.serverTimestamp(),
        });

        AppLogger.log('User data migration completed for: $uid');
      }
    } catch (e, st) {
      AppLogger.error('userProfile.migrateData', e, st);
    }
  }

  // Private helper methods

  static bool _isHighScore(
    GameType gameType,
    int newScore,
    int currentHighScore,
  ) {
    if (currentHighScore == 0) return true;

    final bool descending = _shouldSortDescending(gameType);
    return descending
        ? newScore > currentHighScore
        : newScore < currentHighScore;
  }

  static bool _shouldSortDescending(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
      case GameType.aimTrainer:
        // Lower scores (milliseconds) are better
        return false;
      case GameType.decisionRisk:
      case GameType.personalityQuiz:
      case GameType.numberMemory:
      case GameType.verbalMemory:
      case GameType.visualMemory:
      case GameType.typingSpeed:
      case GameType.sequenceMemory:
      case GameType.chimpTest:
        // Higher scores are better
        return true;
    }
  }

  static UserProfile _recalculateOverallStats(UserProfile profile) {
    int totalGames = 0;
    int overallScore = 0;

    for (final gameType in GameType.values) {
      final stats = profile.getGameStats(gameType);
      totalGames += stats.totalGames;
      overallScore += stats.highScore;
    }

    return profile.copyWith(
      totalGamesPlayed: totalGames,
      overallScore: overallScore,
    );
  }
}
