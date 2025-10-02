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

  // Get user profile as a real-time stream
  static Stream<UserProfile?> getUserProfileStream(String uid) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(null);
      }

      return _usersCollection
          .doc(uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;

            try {
              return UserProfile.fromMap(doc.data()!);
            } catch (e) {
              AppLogger.error('userProfile.parseProfile', e, null);
              return null;
            }
          })
          .handleError((error, stackTrace) {
            AppLogger.error(
              'userProfile.getUserProfileStream',
              error,
              stackTrace,
            );
            return null;
          });
    } catch (e, st) {
      AppLogger.error('userProfile.getUserProfileStream', e, st);
      return Stream.value(null);
    }
  }

  // Get current user's profile as a real-time stream
  static Stream<UserProfile?> getCurrentUserProfileStream() {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(null);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value(null);

      return getUserProfileStream(currentUser.uid);
    } catch (e, st) {
      AppLogger.error('userProfile.getCurrentUserProfileStream', e, st);
      return Stream.value(null);
    }
  }

  // Get user's high score as a real-time stream
  static Stream<int> getUserHighScoreStream(GameType gameType) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(0);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value(0);

      return _usersCollection
          .doc(currentUser.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return 0;

            try {
              final profile = UserProfile.fromMap(doc.data()!);
              return profile.getHighScore(gameType);
            } catch (e) {
              AppLogger.error('userProfile.parseHighScore', e, null);
              return 0;
            }
          })
          .handleError((error, stackTrace) {
            AppLogger.error(
              'userProfile.getUserHighScoreStream',
              error,
              stackTrace,
            );
            return 0;
          });
    } catch (e, st) {
      AppLogger.error('userProfile.getUserHighScoreStream', e, st);
      return Stream.value(0);
    }
  }

  // Get user's game stats as a real-time stream
  static Stream<GameStats> getUserGameStatsStream(GameType gameType) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(GameStats.empty());
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value(GameStats.empty());

      return _usersCollection
          .doc(currentUser.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return GameStats.empty();

            try {
              final profile = UserProfile.fromMap(doc.data()!);
              return profile.getGameStats(gameType);
            } catch (e) {
              AppLogger.error('userProfile.parseGameStats', e, null);
              return GameStats.empty();
            }
          })
          .handleError((error, stackTrace) {
            AppLogger.error(
              'userProfile.getUserGameStatsStream',
              error,
              stackTrace,
            );
            return GameStats.empty();
          });
    } catch (e, st) {
      AppLogger.error('userProfile.getUserGameStatsStream', e, st);
      return Stream.value(GameStats.empty());
    }
  }

  // Get user's recent scores as a real-time stream
  static Stream<List<GameScore>> getUserRecentScoresStream(
    GameType gameType, {
    int limit = 10,
  }) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value([]);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value([]);

      return _usersCollection
          .doc(currentUser.uid)
          .collection('gameScores')
          .where('gameType', isEqualTo: gameType.name)
          .orderBy('playedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) {
                  try {
                    return GameScore.fromMap(doc.data());
                  } catch (e) {
                    AppLogger.error('userProfile.parseGameScore', e, null);
                    return null;
                  }
                })
                .where((score) => score != null)
                .cast<GameScore>()
                .toList(),
          )
          .handleError((error, stackTrace) {
            AppLogger.error(
              'userProfile.getUserRecentScoresStream',
              error,
              stackTrace,
            );
            return <GameScore>[];
          });
    } catch (e, st) {
      AppLogger.error('userProfile.getUserRecentScoresStream', e, st);
      return Stream.value([]);
    }
  }

  // Get user's ranking in a specific game as a real-time stream
  static Stream<int> getUserRankingStream(GameType gameType) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(-1);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value(-1);

      // Get all users ordered by high score for this game
      return _usersCollection
          .orderBy('gameStats.${gameType.name}.highScore', descending: true)
          .snapshots()
          .map((snapshot) {
            final userIndex = snapshot.docs.indexWhere(
              (doc) => doc.id == currentUser!.uid,
            );
            return userIndex >= 0 ? userIndex + 1 : -1;
          })
          .handleError((error, stackTrace) {
            AppLogger.error(
              'userProfile.getUserRankingStream',
              error,
              stackTrace,
            );
            return -1;
          });
    } catch (e, st) {
      AppLogger.error('userProfile.getUserRankingStream', e, st);
      return Stream.value(-1);
    }
  }

  // Get user's overall stats as a real-time stream
  static Stream<Map<String, dynamic>> getUserOverallStatsStream() {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value({});
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value({});

      return _usersCollection
          .doc(currentUser.uid)
          .snapshots()
          .map<Map<String, dynamic>>((doc) {
            if (!doc.exists) return <String, dynamic>{};

            try {
              final profile = UserProfile.fromMap(doc.data()!);
              return <String, dynamic>{
                'totalGames': profile.totalGamesPlayed,
                'overallScore': profile.overallScore,
                'lastGamePlayed': profile.lastGamePlayed,
                'createdAt': profile.createdAt,
              };
            } catch (e) {
              AppLogger.error('userProfile.parseOverallStats', e, null);
              return <String, dynamic>{};
            }
          })
          .handleError((error, stackTrace) {
            AppLogger.error(
              'userProfile.getUserOverallStatsStream',
              error,
              stackTrace,
            );
            return <String, dynamic>{};
          });
    } catch (e, st) {
      AppLogger.error('userProfile.getUserOverallStatsStream', e, st);
      return Stream.value({});
    }
  }

  // Get user's recent activity as a real-time stream
  static Stream<List<GameScore>> getUserRecentActivityStream({int limit = 10}) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value([]);
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return Stream.value([]);

      return _usersCollection
          .doc(currentUser.uid)
          .collection('gameScores')
          .orderBy('playedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) {
                  try {
                    return GameScore.fromMap(doc.data());
                  } catch (e) {
                    AppLogger.error('userProfile.parseRecentActivity', e, null);
                    return null;
                  }
                })
                .where((score) => score != null)
                .cast<GameScore>()
                .toList(),
          )
          .handleError((error, stackTrace) {
            AppLogger.error(
              'userProfile.getUserRecentActivityStream',
              error,
              stackTrace,
            );
            return <GameScore>[];
          });
    } catch (e, st) {
      AppLogger.error('userProfile.getUserRecentActivityStream', e, st);
      return Stream.value([]);
    }
  }

  // Get game leaderboard as a real-time stream
  static Stream<List<UserScore>> getGameLeaderboardStream(
    GameType gameType, {
    int limit = 100,
  }) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value([]);
      }

      // Determine sorting order based on game type
      final bool descending = _shouldSortDescending(gameType);
      final String gameTypeField = 'gameStats.${gameType.name}.highScore';

      return _usersCollection
          .orderBy(gameTypeField, descending: descending)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) {
                  try {
                    final profile = UserProfile.fromMap(doc.data());
                    // Convert UserProfile to UserScore
                    return UserScore(
                      userId: profile.uid,
                      userName: profile.displayName,
                      highScores: profile.gameStats.map(
                        (key, value) => MapEntry(key, value.highScore),
                      ),
                      totalGamesPlayed: profile.gameStats.map(
                        (key, value) => MapEntry(key, value.totalGames),
                      ),
                      lastPlayedAt: profile.gameStats.map(
                        (key, value) =>
                            MapEntry(key, value.lastPlayed ?? DateTime.now()),
                      ),
                      createdAt: profile.createdAt,
                      updatedAt: profile.updatedAt,
                    );
                  } catch (e) {
                    AppLogger.error('userProfile.parseLeaderboard', e, null);
                    return null;
                  }
                })
                .where((score) => score != null)
                .cast<UserScore>()
                .toList(),
          )
          .handleError((error, stackTrace) {
            AppLogger.error(
              'userProfile.getGameLeaderboardStream',
              error,
              stackTrace,
            );
            return <UserScore>[];
          });
    } catch (e, st) {
      AppLogger.error('userProfile.getGameLeaderboardStream', e, st);
      return Stream.value([]);
    }
  }

  // Get overall leaderboard as a real-time stream
  static Stream<List<UserScore>> getOverallLeaderboardStream({
    int limit = 100,
  }) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value([]);
      }

      return _usersCollection
          .orderBy('averageScore', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) {
                  try {
                    final profile = UserProfile.fromMap(doc.data());
                    // Convert UserProfile to UserScore
                    return UserScore(
                      userId: profile.uid,
                      userName: profile.displayName,
                      highScores: profile.gameStats.map(
                        (key, value) => MapEntry(key, value.highScore),
                      ),
                      totalGamesPlayed: profile.gameStats.map(
                        (key, value) => MapEntry(key, value.totalGames),
                      ),
                      lastPlayedAt: profile.gameStats.map(
                        (key, value) =>
                            MapEntry(key, value.lastPlayed ?? DateTime.now()),
                      ),
                      createdAt: profile.createdAt,
                      updatedAt: profile.updatedAt,
                    );
                  } catch (e) {
                    AppLogger.error(
                      'userProfile.parseOverallLeaderboard',
                      e,
                      null,
                    );
                    return null;
                  }
                })
                .where((score) => score != null)
                .cast<UserScore>()
                .toList(),
          )
          .handleError((error, stackTrace) {
            AppLogger.error(
              'userProfile.getOverallLeaderboardStream',
              error,
              stackTrace,
            );
            return <UserScore>[];
          });
    } catch (e, st) {
      AppLogger.error('userProfile.getOverallLeaderboardStream', e, st);
      return Stream.value([]);
    }
  }
}
