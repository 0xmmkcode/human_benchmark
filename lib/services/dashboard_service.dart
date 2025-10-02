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
          _getRecentActivity(),
          _getTopPerformers(),
          _getGameStatistics(),
        ]);

        return DashboardOverview(
          totalUsers: results[0] as int,
          totalGamesPlayed: results[1] as int,
          recentActivity: results[2] as List<RecentActivity>,
          topPerformers: results[3] as List<PlayerDashboardData>,
          gameStatistics: results[4] as Map<GameType, GameStatistics>,
        );
      } else {
        // Web implementation (sequential for compatibility)
        final totalUsers = await _getTotalUsers();
        final totalGames = await _getTotalGamesPlayed();
        final recentActivity = await _getRecentActivity();
        final topPerformers = await _getTopPerformers();
        final gameStats = await _getGameStatistics();

        return DashboardOverview(
          totalUsers: totalUsers,
          totalGamesPlayed: totalGames,
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

  static Future<List<RecentActivity>> _getRecentActivity({
    int limit = 10,
  }) async {
    try {
      // Optimize limit for mobile
      final optimizedLimit = kIsWeb ? limit : (limit > 8 ? 8 : limit);

      final snapshot = await _gameScoresCollection
          .orderBy('playedAt', descending: true)
          .limit(optimizedLimit)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              final gameScore = GameScore.fromMap(doc.data());
              return RecentActivity.fromGameScore(gameScore);
            } catch (e) {
              AppLogger.error('dashboard.parse_recent_activity', e, null);
              return null;
            }
          })
          .where((activity) => activity != null)
          .cast<RecentActivity>()
          .toList(growable: false);
    } catch (e, st) {
      AppLogger.error('dashboard._getRecentActivity', e, st);
      return <RecentActivity>[];
    }
  }

  static Future<List<PlayerDashboardData>> _getTopPerformers({
    int limit = 10,
  }) async {
    try {
      // Optimize limit for mobile
      final optimizedLimit = kIsWeb ? limit : (limit > 8 ? 8 : limit);

      final snapshot = await _userScoresCollection
          .orderBy('overallScore', descending: true)
          .limit(optimizedLimit)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              final userScore = UserScore.fromMap(doc.data());
              return PlayerDashboardData.fromUserScore(userScore);
            } catch (e) {
              AppLogger.error('dashboard.parse_top_performer', e, null);
              return null;
            }
          })
          .where((player) => player != null)
          .cast<PlayerDashboardData>()
          .toList(growable: false);
    } catch (e, st) {
      AppLogger.error('dashboard._getTopPerformers', e, st);
      return <PlayerDashboardData>[];
    }
  }

  static Future<Map<GameType, GameStatistics>> _getGameStatistics() async {
    try {
      final Map<GameType, GameStatistics> stats = {};

      // Process game types in batches for mobile performance
      final gameTypes = GameType.values;
      final batchSize = kIsWeb
          ? gameTypes.length
          : 3; // Smaller batches on mobile

      for (int i = 0; i < gameTypes.length; i += batchSize) {
        final batch = gameTypes.skip(i).take(batchSize);

        final batchResults = await Future.wait(
          batch.map((gameType) => _getGameStatisticsForType(gameType)),
        );

        for (final result in batchResults) {
          if (result != null) {
            stats[result.gameType] = result;
          }
        }

        // Small delay between batches on mobile to prevent overwhelming
        if (!kIsWeb && i + batchSize < gameTypes.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      return stats;
    } catch (e, st) {
      AppLogger.error('dashboard._getGameStatistics', e, st);
      return <GameType, GameStatistics>{};
    }
  }

  static Future<GameStatistics?> _getGameStatisticsForType(
    GameType gameType,
  ) async {
    try {
      // Determine sorting order based on game type
      final bool descending = _shouldSortDescending(gameType);

      // Get top score for this game type
      final topScoreSnapshot = await _userScoresCollection
          .orderBy('highScores.${gameType.name}', descending: descending)
          .limit(1)
          .get();

      int topScore = 0;
      if (topScoreSnapshot.docs.isNotEmpty) {
        final data = topScoreSnapshot.docs.first.data();
        final highScores = data['highScores'] as Map<String, dynamic>?;
        if (highScores != null) {
          topScore = (highScores[gameType.name] as num?)?.toInt() ?? 0;
        }
      }

      // Get player count and calculate average score
      final allScoresSnapshot = await _userScoresCollection
          .where('highScores.${gameType.name}', isGreaterThan: 0)
          .get();

      int totalScore = 0;
      int playerCount = 0;

      for (final doc in allScoresSnapshot.docs) {
        final data = doc.data();
        final highScores = data['highScores'] as Map<String, dynamic>?;
        if (highScores != null) {
          final score = (highScores[gameType.name] as num?)?.toInt() ?? 0;
          if (score > 0) {
            totalScore += score;
            playerCount++;
          }
        }
      }

      final averageScore = playerCount > 0 ? totalScore / playerCount : 0;

      // Only return stats if we have data
      if (playerCount > 0) {
        return GameStatistics(
          gameType: gameType,
          topScore: topScore,
          averageScore: averageScore.round(),
          playerCount: playerCount,
          totalGamesPlayed: playerCount, // For now, same as player count
          lastUpdated: DateTime.now(),
        );
      }

      return null;
    } catch (e, st) {
      AppLogger.error('dashboard._getGameStatisticsForType', e, st);
      return null;
    }
  }

  // Get comprehensive game statistics for all games (more efficient)
  static Future<Map<GameType, GameStatistics>>
  getComprehensiveGameStatistics() async {
    try {
      if (!_isFirebaseAvailable) return {};

      final Map<GameType, GameStatistics> stats = {};

      // Get all user scores to calculate comprehensive statistics
      final allUserScores = await _userScoresCollection.get();

      // Group scores by game type
      final Map<GameType, List<int>> gameScores = {};
      final Map<GameType, int> topScores = {};

      for (final doc in allUserScores.docs) {
        final data = doc.data();
        final highScores = data['highScores'] as Map<String, dynamic>?;

        if (highScores != null) {
          for (final gameType in GameType.values) {
            final score = (highScores[gameType.name] as num?)?.toInt() ?? 0;
            if (score > 0) {
              gameScores.putIfAbsent(gameType, () => []).add(score);

              // Track top score
              final currentTop = topScores[gameType] ?? 0;
              if (score > currentTop) {
                topScores[gameType] = score;
              }
            }
          }
        }
      }

      // Calculate statistics for each game type
      for (final gameType in GameType.values) {
        final scores = gameScores[gameType] ?? [];
        if (scores.isNotEmpty) {
          final totalScore = scores.reduce((a, b) => a + b);
          final averageScore = totalScore / scores.length;

          stats[gameType] = GameStatistics(
            gameType: gameType,
            topScore: topScores[gameType] ?? 0,
            averageScore: averageScore.round(),
            playerCount: scores.length,
            totalGamesPlayed: scores.length, // For now, same as player count
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
  final List<RecentActivity> recentActivity;
  final List<PlayerDashboardData> topPerformers;
  final Map<GameType, GameStatistics> gameStatistics;

  const DashboardOverview({
    required this.totalUsers,
    required this.totalGamesPlayed,
    required this.recentActivity,
    required this.topPerformers,
    required this.gameStatistics,
  });

  factory DashboardOverview.empty() {
    return const DashboardOverview(
      totalUsers: 0,
      totalGamesPlayed: 0,
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

  String get displayName => userName ?? 'Player ${userId.substring(0, 6)}';

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
  final GameType gameType;
  final int score;
  final DateTime playedAt;
  final bool isHighScore;

  const RecentActivity({
    required this.userId,
    this.userName,
    required this.gameType,
    required this.score,
    required this.playedAt,
    required this.isHighScore,
  });

  factory RecentActivity.fromGameScore(GameScore gameScore) {
    return RecentActivity(
      userId: gameScore.userId,
      userName: gameScore.userName,
      gameType: gameScore.gameType,
      score: gameScore.score,
      playedAt: gameScore.playedAt,
      isHighScore: gameScore.isHighScore,
    );
  }

  String get displayName => userName ?? 'Player ${userId.substring(0, 6)}';
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
