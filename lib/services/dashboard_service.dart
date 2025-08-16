import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

  // Get dashboard overview data
  static Future<DashboardOverview> getDashboardOverview() async {
    try {
      if (Firebase.apps.isEmpty) {
        return DashboardOverview.empty();
      }

      // Get total users
      final totalUsers = await _getTotalUsers();

      // Get total games played
      final totalGames = await _getTotalGamesPlayed();

      // Get recent activity
      final recentActivity = await _getRecentActivity();

      // Get top performers
      final topPerformers = await _getTopPerformers();

      // Get game statistics
      final gameStats = await _getGameStatistics();

      return DashboardOverview(
        totalUsers: totalUsers,
        totalGamesPlayed: totalGames,
        recentActivity: recentActivity,
        topPerformers: topPerformers,
        gameStatistics: gameStats,
      );
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
    if (Firebase.apps.isEmpty) {
      return Stream<List<PlayerDashboardData>>.value(
        const <PlayerDashboardData>[],
      );
    }

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

    query = query.limit(limit);

    return query.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      return snapshot.docs
          .map((doc) {
            final userScore = UserScore.fromMap(doc.data());
            return PlayerDashboardData.fromUserScore(userScore);
          })
          .toList(growable: false);
    });
  }

  // Get player details with recent scores
  static Future<PlayerDetailData?> getPlayerDetails(String userId) async {
    try {
      if (Firebase.apps.isEmpty) return null;

      // Get user score profile
      final userScoreDoc = await _userScoresCollection.doc(userId).get();
      if (!userScoreDoc.exists) return null;

      final userScore = UserScore.fromMap(userScoreDoc.data()!);

      // Get recent game scores
      final recentScores = await _getPlayerRecentScores(userId);

      // Get performance trends
      final performanceTrends = await _getPlayerPerformanceTrends(userId);

      return PlayerDetailData(
        userScore: userScore,
        recentScores: recentScores,
        performanceTrends: performanceTrends,
      );
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
    if (Firebase.apps.isEmpty) {
      return Stream<List<PlayerDashboardData>>.value(
        const <PlayerDashboardData>[],
      );
    }

    return _userScoresCollection
        .orderBy('highScores.${gameType.name}', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map((doc) {
                final userScore = UserScore.fromMap(doc.data());
                return PlayerDashboardData.fromUserScore(userScore);
              })
              .toList(growable: false);
        });
  }

  // Search players by name or ID
  static Stream<List<PlayerDashboardData>> searchPlayers(String query) {
    if (Firebase.apps.isEmpty) {
      return Stream<List<PlayerDashboardData>>.value(
        const <PlayerDashboardData>[],
      );
    }

    // Note: Firestore doesn't support full-text search natively
    // This is a simple prefix search on userId
    return _userScoresCollection
        .orderBy('userId')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .limit(20)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map((doc) {
                final userScore = UserScore.fromMap(doc.data());
                return PlayerDashboardData.fromUserScore(userScore);
              })
              .toList(growable: false);
        });
  }

  // Private helper methods
  static Future<int> _getTotalUsers() async {
    final snapshot = await _userScoresCollection.get();
    return snapshot.docs.length;
  }

  static Future<int> _getTotalGamesPlayed() async {
    final snapshot = await _gameScoresCollection.get();
    return snapshot.docs.length;
  }

  static Future<List<RecentActivity>> _getRecentActivity({
    int limit = 10,
  }) async {
    final snapshot = await _gameScoresCollection
        .orderBy('playedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) {
          final gameScore = GameScore.fromMap(doc.data());
          return RecentActivity.fromGameScore(gameScore);
        })
        .toList(growable: false);
  }

  static Future<List<PlayerDashboardData>> _getTopPerformers({
    int limit = 10,
  }) async {
    final snapshot = await _userScoresCollection
        .orderBy('overallScore', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) {
          final userScore = UserScore.fromMap(doc.data());
          return PlayerDashboardData.fromUserScore(userScore);
        })
        .toList(growable: false);
  }

  static Future<Map<GameType, GameStatistics>> _getGameStatistics() async {
    final Map<GameType, GameStatistics> stats = {};

    for (final gameType in GameType.values) {
      final snapshot = await _userScoresCollection
          .orderBy('highScores.${gameType.name}', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final topScore =
            snapshot.docs.first.data()['highScores.${gameType.name}'] as int? ??
            0;

        // Get average score for this game
        final allScores = await _userScoresCollection
            .where('highScores.${gameType.name}', isGreaterThan: 0)
            .get();

        int totalScore = 0;
        int playerCount = 0;

        for (final doc in allScores.docs) {
          final score = doc.data()['highScores.${gameType.name}'] as int? ?? 0;
          if (score > 0) {
            totalScore += score;
            playerCount++;
          }
        }

        final averageScore = playerCount > 0 ? totalScore / playerCount : 0;

        stats[gameType] = GameStatistics(
          gameType: gameType,
          topScore: topScore,
          averageScore: averageScore.round(),
          playerCount: playerCount,
        );
      }
    }

    return stats;
  }

  static Future<List<GameScore>> _getPlayerRecentScores(
    String userId, {
    int limit = 20,
  }) async {
    final snapshot = await _gameScoresCollection
        .where('userId', isEqualTo: userId)
        .orderBy('playedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => GameScore.fromMap(doc.data()))
        .toList(growable: false);
  }

  static Future<Map<GameType, List<int>>> _getPlayerPerformanceTrends(
    String userId,
  ) async {
    final Map<GameType, List<int>> trends = {};

    for (final gameType in GameType.values) {
      final snapshot = await _gameScoresCollection
          .where('userId', isEqualTo: userId)
          .where('gameType', isEqualTo: gameType.name)
          .orderBy('playedAt', descending: true)
          .limit(10)
          .get();

      final scores = snapshot.docs
          .map((doc) {
            final gameScore = GameScore.fromMap(doc.data());
            return gameScore.score;
          })
          .toList(growable: false);

      if (scores.isNotEmpty) {
        trends[gameType] = scores.reversed.toList(growable: false);
      }
    }

    return trends;
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

  const GameStatistics({
    required this.gameType,
    required this.topScore,
    required this.averageScore,
    required this.playerCount,
  });

  String get gameName => GameScore.getDisplayName(gameType);
  String get topScoreDisplay => GameScore.getScoreDisplay(gameType, topScore);
  String get averageScoreDisplay =>
      GameScore.getScoreDisplay(gameType, averageScore);
}
