import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_score.dart';
import '../models/game_score.dart';
import 'app_logger.dart';

class DashboardService {
  DashboardService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static CollectionReference<Map<String, dynamic>> get _userScoresCollection =>
      _firestore.collection('user_scores');
  static CollectionReference<Map<String, dynamic>> get _gameScoresCollection =>
      _firestore.collection('game_scores');

  // Check if Firebase is properly initialized for the current platform
  static bool get _isFirebaseAvailable {
    try {
      if (Firebase.apps.isEmpty) return false;

      // Additional check for mobile platforms
      if (!kIsWeb) {
        // On mobile, ensure Firestore is accessible
        return true; // _firestore.app is always non-null when Firebase is initialized
      }

      return true;
    } catch (e) {
      AppLogger.error('dashboard.firebase_check', e, null);
      return false;
    }
  }

  // Get dashboard overview data
  static Future<DashboardOverview> getDashboardOverview() async {
    try {
      if (!_isFirebaseAvailable) {
        return DashboardOverview.empty();
      }

      // Use Future.wait for concurrent operations on mobile for better performance
      if (!kIsWeb) {
        final results = await Future.wait([
          _getTotalUsers(),
          _getTotalGamesPlayed(),
          _getActiveUsersToday(),
          _getRecentActivity(),
          _getRecentPlayers(),
          getComprehensiveGameStatistics(),
        ]);

        return DashboardOverview(
          totalUsers: results[0] as int,
          totalGamesPlayed: results[1] as int,
          activeUsersToday: results[2] as int,
          recentActivity: results[3] as List<RecentActivity>,
          topPerformers: results[4] as List<PlayerDashboardData>,
          gameStatistics: results[5] as Map<GameType, GameStatistics>,
        );
      } else {
        // Web implementation (sequential for compatibility)
        final totalUsers = await _getTotalUsers();
        final totalGames = await _getTotalGamesPlayed();
        final activeToday = await _getActiveUsersToday();
        final recentActivity = await _getRecentActivity();
        final topPerformers = await _getRecentPlayers();
        final gameStats = await getComprehensiveGameStatistics();

        return DashboardOverview(
          totalUsers: totalUsers,
          totalGamesPlayed: totalGames,
          activeUsersToday: activeToday,
          recentActivity: recentActivity,
          topPerformers: topPerformers,
          gameStatistics: gameStats,
        );
      }
    } catch (e, st) {
      AppLogger.error('dashboard.overview', e, st);
      return DashboardOverview.empty();
    }
  }

  // Get dashboard overview data as a real-time stream
  static Stream<DashboardOverview> getDashboardOverviewStream() {
    try {
      return Stream.periodic(const Duration(seconds: 5))
          .asyncMap((_) async {
            return await getDashboardOverview();
          })
          .distinct(
            (prev, next) =>
                prev.totalUsers == next.totalUsers &&
                prev.totalGamesPlayed == next.totalGamesPlayed &&
                prev.activeUsersToday == next.activeUsersToday &&
                prev.recentActivity.length == next.recentActivity.length &&
                prev.topPerformers.length == next.topPerformers.length,
          );
    } catch (e, st) {
      AppLogger.error('dashboard.overviewStream', e, st);
      return Stream.value(DashboardOverview.empty());
    }
  }

  // Get recent activity as a real-time stream
  static Stream<List<RecentActivity>> getRecentActivityStream({
    int limit = 10,
  }) {
    try {
      if (!_isFirebaseAvailable) {
        return Stream.value(<RecentActivity>[]);
      }

      return Stream.periodic(const Duration(seconds: 3))
          .asyncMap((_) async {
            return await _getRecentActivity(limit: limit);
          })
          .distinct((prev, next) {
            if (prev.length != next.length) return false;

            // Check if any activity has changed
            for (int i = 0; i < prev.length; i++) {
              if (i >= next.length) return false;
              final prevActivity = prev[i];
              final nextActivity = next[i];

              if (prevActivity.userId != nextActivity.userId ||
                  prevActivity.gameType != nextActivity.gameType ||
                  prevActivity.score != nextActivity.score ||
                  prevActivity.playedAt != nextActivity.playedAt) {
                return false;
              }
            }
            return true;
          });
    } catch (e, st) {
      AppLogger.error('dashboard.recentActivityStream', e, st);
      return Stream.value(<RecentActivity>[]);
    }
  }

  // Get recent activity for a specific game
  static Future<List<RecentActivity>> getRecentActivityForGame(
    GameType gameType, {
    int limit = 5,
  }) async {
    try {
      if (!_isFirebaseAvailable) {
        return <RecentActivity>[];
      }

      final snapshot = await _gameScoresCollection
          .where('gameType', isEqualTo: gameType.name)
          .orderBy('playedAt', descending: true)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        return <RecentActivity>[];
      }

      // Parse game scores
      final gameScores = <GameScore>[];
      for (final doc in snapshot.docs) {
        try {
          final gameScore = GameScore.fromMap(doc.data());
          gameScores.add(gameScore);
        } catch (e) {
          AppLogger.error('dashboard.parse_game_score_for_game', e, null);
        }
      }

      if (gameScores.isEmpty) {
        return <RecentActivity>[];
      }

      // Resolve user information for better display
      return await _resolveUserInformation(gameScores);
    } catch (e, st) {
      AppLogger.error('dashboard.getRecentActivityForGame', e, st);
      return <RecentActivity>[];
    }
  }

  // Get all players with their scores
  static Stream<List<PlayerDashboardData>> getAllPlayers({
    int limit = 100,
    String? sortBy,
    bool descending = true,
  }) {
    if (!_isFirebaseAvailable) {
      return Stream<List<PlayerDashboardData>>.value(
        const <PlayerDashboardData>[],
      );
    }

    try {
      Query<Map<String, dynamic>> query = _userScoresCollection;

      // Apply sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'overallScore':
            query = query.orderBy('overallScore', descending: descending);
            break;
          case 'totalGames':
            query = query.orderBy(
              'totalGamesPlayedOverall',
              descending: descending,
            );
            break;
          case 'lastPlayed':
            query = query.orderBy('updatedAt', descending: descending);
            break;
          default:
            query = query.orderBy('overallScore', descending: true);
        }
      } else {
        query = query.orderBy('overallScore', descending: true);
      }

      // Optimize limit for mobile performance
      final optimizedLimit = kIsWeb ? limit : (limit > 50 ? 50 : limit);
      query = query.limit(optimizedLimit);

      return query
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    final userScore = UserScore.fromMap(doc.data());
                    return PlayerDashboardData.fromUserScore(userScore);
                  } catch (e) {
                    AppLogger.error('dashboard.parse_user_score', e, null);
                    return null;
                  }
                })
                .where((player) => player != null)
                .cast<PlayerDashboardData>()
                .toList(growable: false);
          })
          .handleError((error, stackTrace) {
            AppLogger.error('dashboard.getAllPlayers', error, stackTrace);
            return <PlayerDashboardData>[];
          });
    } catch (e, st) {
      AppLogger.error('dashboard.getAllPlayers', e, st);
      return Stream<List<PlayerDashboardData>>.value(
        const <PlayerDashboardData>[],
      );
    }
  }

  // Get player details with recent scores
  static Future<PlayerDetailData?> getPlayerDetails(String userId) async {
    try {
      if (!_isFirebaseAvailable) return null;

      // Get user score profile
      final userScoreDoc = await _userScoresCollection.doc(userId).get();
      if (!userScoreDoc.exists) return null;

      final userScore = UserScore.fromMap(userScoreDoc.data()!);

      // Use concurrent operations on mobile for better performance
      if (!kIsWeb) {
        final results = await Future.wait([
          _getPlayerRecentScores(userId),
          _getPlayerPerformanceTrends(userId),
        ]);

        return PlayerDetailData(
          userScore: userScore,
          recentScores: results[0] as List<GameScore>,
          performanceTrends: results[1] as Map<GameType, List<int>>,
        );
      } else {
        // Web implementation (sequential for compatibility)
        final recentScores = await _getPlayerRecentScores(userId);
        final performanceTrends = await _getPlayerPerformanceTrends(userId);

        return PlayerDetailData(
          userScore: userScore,
          recentScores: recentScores,
          performanceTrends: performanceTrends,
        );
      }
    } catch (e, st) {
      AppLogger.error('dashboard.playerDetails', e, st);
      return null;
    }
  }

  // Get leaderboard for specific game
  static Stream<List<PlayerDashboardData>> getGameLeaderboard(
    GameType gameType, {
    int limit = 50,
  }) {
    if (!_isFirebaseAvailable) {
      return Stream<List<PlayerDashboardData>>.value(
        const <PlayerDashboardData>[],
      );
    }

    try {
      // Optimize limit for mobile performance
      final optimizedLimit = kIsWeb ? limit : (limit > 30 ? 30 : limit);

      // Determine sorting order based on game type
      final bool descending = _shouldSortDescending(gameType);

      return _userScoresCollection
          .orderBy('highScores.${gameType.name}', descending: descending)
          .limit(optimizedLimit)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    final userScore = UserScore.fromMap(doc.data());
                    return PlayerDashboardData.fromUserScore(userScore);
                  } catch (e) {
                    AppLogger.error(
                      'dashboard.parse_leaderboard_score',
                      e,
                      null,
                    );
                    return null;
                  }
                })
                .where((player) => player != null)
                .cast<PlayerDashboardData>()
                .toList(growable: false);
          })
          .handleError((error, stackTrace) {
            AppLogger.error('dashboard.getGameLeaderboard', error, stackTrace);
            return <PlayerDashboardData>[];
          });
    } catch (e, st) {
      AppLogger.error('dashboard.getGameLeaderboard', e, st);
      return Stream<List<PlayerDashboardData>>.value(
        const <PlayerDashboardData>[],
      );
    }
  }

  // Search players by name or ID
  static Stream<List<PlayerDashboardData>> searchPlayers(String query) {
    if (!_isFirebaseAvailable || query.trim().isEmpty) {
      return Stream<List<PlayerDashboardData>>.value(
        const <PlayerDashboardData>[],
      );
    }

    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a simple prefix search on userId
      // Optimize for mobile by reducing results
      final searchLimit = kIsWeb ? 20 : 15;

      return _userScoresCollection
          .orderBy('userId')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .limit(searchLimit)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    final userScore = UserScore.fromMap(doc.data());
                    return PlayerDashboardData.fromUserScore(userScore);
                  } catch (e) {
                    AppLogger.error('dashboard.parse_search_result', e, null);
                    return null;
                  }
                })
                .where((player) => player != null)
                .cast<PlayerDashboardData>()
                .toList(growable: false);
          })
          .handleError((error, stackTrace) {
            AppLogger.error('dashboard.searchPlayers', error, stackTrace);
            return <PlayerDashboardData>[];
          });
    } catch (e, st) {
      AppLogger.error('dashboard.searchPlayers', e, st);
      return Stream<List<PlayerDashboardData>>.value(
        const <PlayerDashboardData>[],
      );
    }
  }

  // Private helper methods

  // Determine if scores should be sorted in descending order for a game type
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

  static Future<int> _getTotalUsers() async {
    try {
      final snapshot = await _userScoresCollection.get();
      return snapshot.docs.length;
    } catch (e, st) {
      AppLogger.error('dashboard._getTotalUsers', e, st);
      return 0;
    }
  }

  static Future<int> _getTotalGamesPlayed() async {
    try {
      final snapshot = await _gameScoresCollection.get();
      return snapshot.docs.length;
    } catch (e, st) {
      AppLogger.error('dashboard._getTotalGamesPlayed', e, st);
      return 0;
    }
  }

  static Future<int> _getActiveUsersToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _gameScoresCollection
          .where(
            'playedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('playedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      // Get unique user IDs from today's games
      final uniqueUserIds = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        if (userId != null) {
          uniqueUserIds.add(userId);
        }
      }

      return uniqueUserIds.length;
    } catch (e, st) {
      AppLogger.error('dashboard._getActiveUsersToday', e, st);
      return 0;
    }
  }

  static Future<List<RecentActivity>> _getRecentActivity({
    int limit = 10,
  }) async {
    try {
      // Optimize limit for mobile
      final optimizedLimit = kIsWeb ? limit : (limit > 8 ? 8 : limit);

      // Prefer reading from recent_activity if present
      try {
        final recentSnap = await FirebaseFirestore.instance
            .collection('recent_activity')
            .orderBy('playedAt', descending: true)
            .limit(optimizedLimit)
            .get();

        if (recentSnap.docs.isNotEmpty) {
          return recentSnap.docs
              .map((doc) {
                final data = doc.data();
                try {
                  // Map simplified activity to RecentActivity
                  final gameType = GameType.values.firstWhere(
                    (e) => e.name == (data['gameType'] as String? ?? ''),
                    orElse: () => GameType.reactionTime,
                  );
                  final playedAt = (data['playedAt'] is Timestamp)
                      ? (data['playedAt'] as Timestamp).toDate()
                      : DateTime.now();
                  return RecentActivity(
                    userId: (data['userId'] as String?) ?? '',
                    userName: data['userName'] as String?,
                    userEmail: null,
                    userPhotoUrl: null,
                    gameType: gameType,
                    score: (data['score'] as num?)?.toInt() ?? 0,
                    playedAt: playedAt,
                    isHighScore: data['isHighScore'] as bool? ?? false,
                    gameData: null,
                  );
                } catch (e) {
                  return null;
                }
              })
              .where((e) => e != null)
              .cast<RecentActivity>()
              .toList();
        }
      } catch (_) {
        // ignore and fallback
      }

      final snapshot = await _gameScoresCollection
          .orderBy('playedAt', descending: true)
          .limit(optimizedLimit)
          .get();

      if (snapshot.docs.isEmpty) {
        return <RecentActivity>[];
      }

      // Parse game scores
      final gameScores = <GameScore>[];
      for (final doc in snapshot.docs) {
        try {
          final gameScore = GameScore.fromMap(doc.data());
          gameScores.add(gameScore);
        } catch (e) {
          AppLogger.error('dashboard.parse_game_score', e, null);
        }
      }

      if (gameScores.isEmpty) {
        return <RecentActivity>[];
      }

      // Resolve user information for better display
      final recentActivities = await _resolveUserInformation(gameScores);

      return recentActivities;
    } catch (e, st) {
      AppLogger.error('dashboard._getRecentActivity', e, st);
      return <RecentActivity>[];
    }
  }

  // Resolve user information for recent activities
  static Future<List<RecentActivity>> _resolveUserInformation(
    List<GameScore> gameScores,
  ) async {
    try {
      // Group by user ID to minimize Firestore calls
      final userIds = gameScores.map((score) => score.userId).toSet().toList();

      // Batch fetch user profiles
      final userProfiles = <String, Map<String, dynamic>>{};

      if (userIds.isNotEmpty) {
        try {
          // Get user profiles efficiently
          final userRefs = userIds.map((uid) => _userScoresCollection.doc(uid));

          // Get user profiles
          final userSnapshots = await Future.wait(
            userRefs.map((ref) => ref.get()),
          );

          for (int i = 0; i < userSnapshots.length; i++) {
            final snapshot = userSnapshots[i];
            if (snapshot.exists) {
              userProfiles[userIds[i]] = snapshot.data()!;
            }
          }
        } catch (e) {
          AppLogger.error('dashboard.resolve_users', e, null);
          // Continue without user profiles
        }
      }

      // Create recent activities with resolved user info
      return gameScores.map((gameScore) {
        final userProfile = userProfiles[gameScore.userId];
        final userName =
            gameScore.userName ??
            userProfile?['displayName'] as String? ??
            userProfile?['email'] as String?;
        final userEmail = userProfile?['email'] as String?;
        final userPhotoUrl = userProfile?['photoURL'] as String?;

        return RecentActivity(
          userId: gameScore.userId,
          userName: userName,
          userEmail: userEmail,
          userPhotoUrl: userPhotoUrl,
          gameType: gameScore.gameType,
          score: gameScore.score,
          playedAt: gameScore.playedAt,
          isHighScore: gameScore.isHighScore,
          gameData: gameScore.gameData?['context'] as String?,
        );
      }).toList();
    } catch (e, st) {
      AppLogger.error('dashboard.resolve_user_info', e, st);
      // Fallback to basic recent activities
      return gameScores
          .map((gameScore) => RecentActivity.fromGameScore(gameScore))
          .toList();
    }
  }

  // Recent players: order by last activity and map to PlayerDashboardData
  static Future<List<PlayerDashboardData>> _getRecentPlayers({
    int limit = 10,
  }) async {
    try {
      final optimizedLimit = kIsWeb ? limit : (limit > 8 ? 8 : limit);

      final snapshot = await _userScoresCollection
          .orderBy('updatedAt', descending: true)
          .limit(optimizedLimit)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              final userScore = UserScore.fromMap(doc.data());
              return PlayerDashboardData.fromUserScore(userScore);
            } catch (e) {
              AppLogger.error('dashboard.parse_recent_player', e, null);
              return null;
            }
          })
          .where((player) => player != null)
          .cast<PlayerDashboardData>()
          .toList(growable: false);
    } catch (e, st) {
      AppLogger.error('dashboard._getRecentPlayers', e, st);
      return <PlayerDashboardData>[];
    }
  }

  // Get comprehensive game statistics for all games using game_scores collection
  static Future<Map<GameType, GameStatistics>>
  getComprehensiveGameStatistics() async {
    try {
      if (!_isFirebaseAvailable) return {};

      final Map<GameType, GameStatistics> stats = {};

      // Get all game scores to calculate comprehensive statistics
      final allGameScores = await _gameScoresCollection.get();

      // Group scores by game type
      final Map<GameType, List<int>> gameScores = {};
      final Map<GameType, Set<String>> uniquePlayers = {};
      final Map<GameType, int> topScores = {};

      for (final doc in allGameScores.docs) {
        final data = doc.data();
        final gameTypeName = data['gameType'] as String?;
        final score = (data['score'] as num?)?.toInt() ?? 0;
        final userId = data['userId'] as String?;

        if (gameTypeName != null && score > 0 && userId != null) {
          final gameType = GameType.values.firstWhere(
            (e) => e.name == gameTypeName,
            orElse: () => GameType.reactionTime,
          );

          // Collect all scores for this game type
          gameScores.putIfAbsent(gameType, () => []).add(score);

          // Track unique players
          uniquePlayers.putIfAbsent(gameType, () => <String>{}).add(userId);

          // Track top score: for time-based games lower is better, otherwise higher is better
          if (!topScores.containsKey(gameType)) {
            topScores[gameType] = score;
          } else {
            final currentTop = topScores[gameType]!;
            final bool lowerIsBetter = _isLowerBetter(gameType);
            if ((lowerIsBetter && score < currentTop) ||
                (!lowerIsBetter && score > currentTop)) {
              topScores[gameType] = score;
            }
          }
        }
      }

      // Calculate statistics for each game type
      for (final gameType in GameType.values) {
        final scores = gameScores[gameType] ?? [];
        final players = uniquePlayers[gameType] ?? <String>{};

        if (scores.isNotEmpty) {
          final totalScore = scores.reduce((a, b) => a + b);
          double averageScore = totalScore / scores.length;

          // For time-based games (lower is better), average should reflect lower-is-better metric
          if (_isLowerBetter(gameType)) {
            // Keep arithmetic mean but ensure display uses ms; no inversion needed
            // We still round the mean as before
          }

          stats[gameType] = GameStatistics(
            gameType: gameType,
            topScore: topScores[gameType] ?? 0,
            averageScore: averageScore.round(),
            playerCount: players.length,
            totalGamesPlayed: scores.length, // Total game sessions
            lastUpdated: DateTime.now(),
          );
        }
      }

      return stats;
    } catch (e, st) {
      AppLogger.error('dashboard.getComprehensiveGameStatistics', e, st);
      return {};
    }
  }

  // For these games, lower scores are better (measured in milliseconds)
  static bool _isLowerBetter(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
      case GameType.aimTrainer:
        return true;
      default:
        return false;
    }
  }

  static Future<List<GameScore>> _getPlayerRecentScores(
    String userId, {
    int limit = 20,
  }) async {
    try {
      // Optimize limit for mobile
      final optimizedLimit = kIsWeb ? limit : (limit > 15 ? 15 : limit);

      final snapshot = await _gameScoresCollection
          .where('userId', isEqualTo: userId)
          .orderBy('playedAt', descending: true)
          .limit(optimizedLimit)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return GameScore.fromMap(doc.data());
            } catch (e) {
              AppLogger.error('dashboard.parse_player_score', e, null);
              return null;
            }
          })
          .where((score) => score != null)
          .cast<GameScore>()
          .toList(growable: false);
    } catch (e, st) {
      AppLogger.error('dashboard._getPlayerRecentScores', e, st);
      return <GameScore>[];
    }
  }

  static Future<Map<GameType, List<int>>> _getPlayerPerformanceTrends(
    String userId,
  ) async {
    try {
      final Map<GameType, List<int>> trends = {};

      // Process game types in smaller batches for mobile
      final gameTypes = GameType.values;
      final batchSize = kIsWeb
          ? gameTypes.length
          : 2; // Smaller batches on mobile

      for (int i = 0; i < gameTypes.length; i += batchSize) {
        final batch = gameTypes.skip(i).take(batchSize);

        final batchResults = await Future.wait(
          batch.map(
            (gameType) => _getPlayerPerformanceTrendForType(userId, gameType),
          ),
        );

        for (int j = 0; j < batch.length; j++) {
          final gameType = batch.elementAt(j);
          final trend = batchResults[j];
          if (trend.isNotEmpty) {
            trends[gameType] = trend;
          }
        }

        // Small delay between batches on mobile
        if (!kIsWeb && i + batchSize < gameTypes.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      return trends;
    } catch (e, st) {
      AppLogger.error('dashboard._getPlayerPerformanceTrends', e, st);
      return <GameType, List<int>>{};
    }
  }

  static Future<List<int>> _getPlayerPerformanceTrendForType(
    String userId,
    GameType gameType,
  ) async {
    try {
      final snapshot = await _gameScoresCollection
          .where('userId', isEqualTo: userId)
          .where('gameType', isEqualTo: gameType.name)
          .orderBy('playedAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              final gameScore = GameScore.fromMap(doc.data());
              return gameScore.score;
            } catch (e) {
              AppLogger.error('dashboard.parse_trend_score', e, null);
              return 0;
            }
          })
          .where((score) => score > 0)
          .toList(growable: false)
          .reversed
          .toList(growable: false);
    } catch (e, st) {
      AppLogger.error('dashboard._getPlayerPerformanceTrendForType', e, st);
      return <int>[];
    }
  }
}

// Dashboard data models
class DashboardOverview {
  final int totalUsers;
  final int totalGamesPlayed;
  final int activeUsersToday;
  final List<RecentActivity> recentActivity;
  final List<PlayerDashboardData> topPerformers;
  final Map<GameType, GameStatistics> gameStatistics;

  const DashboardOverview({
    required this.totalUsers,
    required this.totalGamesPlayed,
    required this.activeUsersToday,
    required this.recentActivity,
    required this.topPerformers,
    required this.gameStatistics,
  });

  factory DashboardOverview.empty() {
    return const DashboardOverview(
      totalUsers: 0,
      totalGamesPlayed: 0,
      activeUsersToday: 0,
      recentActivity: [],
      topPerformers: [],
      gameStatistics: {},
    );
  }
}

class PlayerDashboardData {
  final String userId;
  final String? userName;
  final int overallScore;
  final int totalGamesPlayed;
  final DateTime lastPlayedAt;
  final Map<GameType, int> highScores;
  final int rank;

  const PlayerDashboardData({
    required this.userId,
    this.userName,
    required this.overallScore,
    required this.totalGamesPlayed,
    required this.lastPlayedAt,
    required this.highScores,
    required this.rank,
  });

  factory PlayerDashboardData.fromUserScore(
    UserScore userScore, {
    int rank = 0,
  }) {
    return PlayerDashboardData(
      userId: userScore.userId,
      userName: userScore.userName,
      overallScore: userScore.overallScore,
      totalGamesPlayed: userScore.totalGamesPlayedOverall,
      lastPlayedAt: userScore.updatedAt,
      highScores: userScore.highScores,
      rank: rank,
    );
  }

  String get displayName =>
      (userName != null && userName!.isNotEmpty) ? userName! : 'Guest';

  int getHighScore(GameType gameType) => highScores[gameType] ?? 0;
}

class PlayerDetailData {
  final UserScore userScore;
  final List<GameScore> recentScores;
  final Map<GameType, List<int>> performanceTrends;

  const PlayerDetailData({
    required this.userScore,
    required this.recentScores,
    required this.performanceTrends,
  });
}

class RecentActivity {
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? userPhotoUrl;
  final GameType gameType;
  final int score;
  final DateTime playedAt;
  final bool isHighScore;
  final String? gameData; // Additional context like level, difficulty, etc.

  const RecentActivity({
    required this.userId,
    this.userName,
    this.userEmail,
    this.userPhotoUrl,
    required this.gameType,
    required this.score,
    required this.playedAt,
    required this.isHighScore,
    this.gameData,
  });

  factory RecentActivity.fromGameScore(GameScore gameScore) {
    return RecentActivity(
      userId: gameScore.userId,
      userName: gameScore.userName,
      userEmail: null, // Will be resolved separately
      userPhotoUrl: null, // Will be resolved separately
      gameType: gameScore.gameType,
      score: gameScore.score,
      playedAt: gameScore.playedAt,
      isHighScore: gameScore.isHighScore,
      gameData: gameScore.gameData?['context'] as String?,
    );
  }

  factory RecentActivity.fromMap(Map<String, dynamic> data) {
    return RecentActivity(
      userId: data['userId'] as String,
      userName: data['userName'] as String?,
      userEmail: data['userEmail'] as String?,
      userPhotoUrl: data['userPhotoUrl'] as String?,
      gameType: GameType.values.firstWhere(
        (e) => e.name == data['gameType'],
        orElse: () => GameType.reactionTime,
      ),
      score: data['score'] as int,
      playedAt: (data['playedAt'] as Timestamp).toDate(),
      isHighScore: data['isHighScore'] as bool? ?? false,
      gameData: data['gameData'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'gameType': gameType.name,
      'score': score,
      'playedAt': Timestamp.fromDate(playedAt),
      'isHighScore': isHighScore,
      'gameData': gameData,
    };
  }

  RecentActivity copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
    GameType? gameType,
    int? score,
    DateTime? playedAt,
    bool? isHighScore,
    String? gameData,
  }) {
    return RecentActivity(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      gameType: gameType ?? this.gameType,
      score: score ?? this.score,
      playedAt: playedAt ?? this.playedAt,
      isHighScore: isHighScore ?? this.isHighScore,
      gameData: gameData ?? this.gameData,
    );
  }

  String get displayName {
    if (userName != null && userName!.isNotEmpty) {
      return userName!;
    }
    if (userEmail != null && userEmail!.isNotEmpty) {
      return userEmail!.split('@').first;
    }
    return 'Guest';
  }

  String get shortUserId =>
      userId.length > 8 ? '${userId.substring(0, 8)}...' : userId;

  String get gameDisplayName => GameScore.getDisplayName(gameType);

  String get scoreDisplay => GameScore.getScoreDisplay(gameType, score);

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(playedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  bool get isGuest => userName == null || userName!.isEmpty;
}

class GameStatistics {
  final GameType gameType;
  final int topScore;
  final int averageScore;
  final int playerCount;
  final int totalGamesPlayed;
  final DateTime? lastUpdated;

  const GameStatistics({
    required this.gameType,
    required this.topScore,
    required this.averageScore,
    required this.playerCount,
    this.totalGamesPlayed = 0,
    this.lastUpdated,
  });

  String get gameName => GameScore.getDisplayName(gameType);
  String get topScoreDisplay => GameScore.getScoreDisplay(gameType, topScore);
  String get averageScoreDisplay =>
      GameScore.getScoreDisplay(gameType, averageScore);

  // Get a formatted string for the last updated time
  String get lastUpdatedDisplay {
    if (lastUpdated == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
