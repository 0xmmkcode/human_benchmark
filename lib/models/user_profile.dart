import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game_score.dart';
import 'user_score.dart';

class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final DateTime? birthday;
  final String? country;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Game statistics
  final Map<GameType, GameStats> gameStats;
  final Map<GameType, List<GameScore>> recentScores;

  // Overall stats
  final int totalGamesPlayed;
  final int overallScore;
  final DateTime? lastGamePlayed;

  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.birthday,
    this.country,
    required this.createdAt,
    required this.updatedAt,
    required this.gameStats,
    required this.recentScores,
    required this.totalGamesPlayed,
    required this.overallScore,
    this.lastGamePlayed,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'country': country,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'gameStats': gameStats.map(
        (key, value) => MapEntry(key.name, value.toMap()),
      ),
      'recentScores': recentScores.map(
        (key, value) =>
            MapEntry(key.name, value.map((score) => score.toMap()).toList()),
      ),
      'totalGamesPlayed': totalGamesPlayed,
      'overallScore': overallScore,
      'lastGamePlayed': lastGamePlayed != null
          ? Timestamp.fromDate(lastGamePlayed!)
          : null,
    };
  }

  factory UserProfile.fromMap(Map<String, Object?> data) {
    final String uid = (data['uid'] ?? '') as String;
    final String? email = data['email'] as String?;
    final String? displayName = data['displayName'] as String?;
    final String? photoURL = data['photoURL'] as String?;
    final String? country = data['country'] as String?;

    // Parse birthday
    DateTime? birthday;
    if (data['birthday'] is Timestamp) {
      birthday = (data['birthday'] as Timestamp).toDate();
    }

    // Parse timestamps
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime updatedAt = DateTime.now();
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    }

    // Parse game stats
    final Map<GameType, GameStats> gameStats = {};
    final Map<String, dynamic>? statsMap =
        data['gameStats'] as Map<String, dynamic>?;
    if (statsMap != null) {
      for (final entry in statsMap.entries) {
        final gameType = GameType.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => GameType.reactionTime,
        );
        if (entry.value is Map<String, dynamic>) {
          gameStats[gameType] = GameStats.fromMap(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    }

    // Parse recent scores
    final Map<GameType, List<GameScore>> recentScores = {};
    final Map<String, dynamic>? scoresMap =
        data['recentScores'] as Map<String, dynamic>?;
    if (scoresMap != null) {
      for (final entry in scoresMap.entries) {
        final gameType = GameType.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => GameType.reactionTime,
        );
        if (entry.value is List) {
          final scoresList = (entry.value as List)
              .map((scoreData) {
                if (scoreData is Map<String, dynamic>) {
                  return GameScore.fromMap(scoreData);
                }
                return null;
              })
              .whereType<GameScore>()
              .toList();
          recentScores[gameType] = scoresList;
        }
      }
    }

    final int totalGamesPlayed =
        (data['totalGamesPlayed'] as num?)?.toInt() ?? 0;
    final int overallScore = (data['overallScore'] as num?)?.toInt() ?? 0;

    DateTime? lastGamePlayed;
    if (data['lastGamePlayed'] is Timestamp) {
      lastGamePlayed = (data['lastGamePlayed'] as Timestamp).toDate();
    }

    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      birthday: birthday,
      country: country,
      createdAt: createdAt,
      updatedAt: updatedAt,
      gameStats: gameStats,
      recentScores: recentScores,
      totalGamesPlayed: totalGamesPlayed,
      overallScore: overallScore,
      lastGamePlayed: lastGamePlayed,
    );
  }

  // Create from Firebase User
  factory UserProfile.fromFirebaseUser(User user) {
    return UserProfile(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      birthday: null,
      country: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      gameStats: {},
      recentScores: {},
      totalGamesPlayed: 0,
      overallScore: 0,
      lastGamePlayed: null,
    );
  }

  // Helper methods
  GameStats getGameStats(GameType gameType) =>
      gameStats[gameType] ?? GameStats.empty();
  List<GameScore> getRecentScores(GameType gameType) =>
      recentScores[gameType] ?? [];

  int getHighScore(GameType gameType) => getGameStats(gameType).highScore;
  int getTotalGames(GameType gameType) => getGameStats(gameType).totalGames;
  double getAverageScore(GameType gameType) =>
      getGameStats(gameType).averageScore;

  // Create a copy with updates
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? birthday,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<GameType, GameStats>? gameStats,
    Map<GameType, List<GameScore>>? recentScores,
    int? totalGamesPlayed,
    int? overallScore,
    DateTime? lastGamePlayed,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      birthday: birthday ?? this.birthday,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gameStats: gameStats ?? this.gameStats,
      recentScores: recentScores ?? this.recentScores,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      overallScore: overallScore ?? this.overallScore,
      lastGamePlayed: lastGamePlayed ?? this.lastGamePlayed,
    );
  }

  // Update game stats for a specific game
  UserProfile updateGameStats(GameType gameType, GameStats newStats) {
    final updatedGameStats = Map<GameType, GameStats>.from(gameStats);
    updatedGameStats[gameType] = newStats;

    return copyWith(gameStats: updatedGameStats, updatedAt: DateTime.now());
  }

  // Add a new game score
  UserProfile addGameScore(GameType gameType, GameScore score) {
    final updatedRecentScores = Map<GameType, List<GameScore>>.from(
      recentScores,
    );
    final currentScores = List<GameScore>.from(recentScores[gameType] ?? []);

    // Add new score and keep only the most recent 10
    currentScores.insert(0, score);
    if (currentScores.length > 10) {
      currentScores.removeRange(10, currentScores.length);
    }

    updatedRecentScores[gameType] = currentScores;

    return copyWith(
      recentScores: updatedRecentScores,
      lastGamePlayed: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class GameStats {
  final int highScore;
  final int totalGames;
  final double averageScore;
  final DateTime? lastPlayed;
  final DateTime? firstPlayed;

  const GameStats({
    required this.highScore,
    required this.totalGames,
    required this.averageScore,
    this.lastPlayed,
    this.firstPlayed,
  });

  const GameStats.empty()
    : highScore = 0,
      totalGames = 0,
      averageScore = 0.0,
      lastPlayed = null,
      firstPlayed = null;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'highScore': highScore,
      'totalGames': totalGames,
      'averageScore': averageScore,
      'lastPlayed': lastPlayed != null ? Timestamp.fromDate(lastPlayed!) : null,
      'firstPlayed': firstPlayed != null
          ? Timestamp.fromDate(firstPlayed!)
          : null,
    };
  }

  factory GameStats.fromMap(Map<String, dynamic> data) {
    final int highScore = (data['highScore'] as num?)?.toInt() ?? 0;
    final int totalGames = (data['totalGames'] as num?)?.toInt() ?? 0;
    final double averageScore =
        (data['averageScore'] as num?)?.toDouble() ?? 0.0;

    DateTime? lastPlayed;
    if (data['lastPlayed'] is Timestamp) {
      lastPlayed = (data['lastPlayed'] as Timestamp).toDate();
    }

    DateTime? firstPlayed;
    if (data['firstPlayed'] is Timestamp) {
      firstPlayed = (data['firstPlayed'] as Timestamp).toDate();
    }

    return GameStats(
      highScore: highScore,
      totalGames: totalGames,
      averageScore: averageScore,
      lastPlayed: lastPlayed,
      firstPlayed: firstPlayed,
    );
  }

  // Update stats with a new score
  GameStats updateWithScore(int newScore) {
    final newTotalGames = totalGames + 1;
    final newAverageScore =
        ((averageScore * totalGames) + newScore) / newTotalGames;
    final newHighScore = _shouldSortDescending()
        ? (newScore > highScore ? newScore : highScore)
        : (newScore < highScore || highScore == 0 ? newScore : highScore);

    return GameStats(
      highScore: newHighScore,
      totalGames: newTotalGames,
      averageScore: newAverageScore,
      lastPlayed: DateTime.now(),
      firstPlayed: firstPlayed ?? DateTime.now(),
    );
  }

  // Determine if scores should be sorted in descending order for this game type
  bool _shouldSortDescending() {
    // This would need to be passed from the caller or determined differently
    // For now, assuming higher scores are better (most games)
    return true;
  }

  // Create a copy with updates
  GameStats copyWith({
    int? highScore,
    int? totalGames,
    double? averageScore,
    DateTime? lastPlayed,
    DateTime? firstPlayed,
  }) {
    return GameStats(
      highScore: highScore ?? this.highScore,
      totalGames: totalGames ?? this.totalGames,
      averageScore: averageScore ?? this.averageScore,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      firstPlayed: firstPlayed ?? this.firstPlayed,
    );
  }
}
