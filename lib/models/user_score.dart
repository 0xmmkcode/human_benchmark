import 'package:cloud_firestore/cloud_firestore.dart';

enum GameType {
  reactionTime,
  decisionRisk,
  personalityQuiz,
  numberMemory,
  verbalMemory,
  visualMemory,
  typingSpeed,
  aimTrainer,
  sequenceMemory,
  chimpTest,
}

class UserScore {
  final String userId;
  final String? userName;
  final Map<GameType, int> highScores;
  final Map<GameType, int> totalGamesPlayed;
  final Map<GameType, DateTime> lastPlayedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserScore({
    required this.userId,
    this.userName,
    required this.highScores,
    required this.totalGamesPlayed,
    required this.lastPlayedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'userId': userId,
      'userName': userName,
      'highScores': highScores.map((key, value) => MapEntry(key.name, value)),
      'totalGamesPlayed': totalGamesPlayed.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'lastPlayedAt': lastPlayedAt.map(
        (key, value) => MapEntry(key.name, Timestamp.fromDate(value)),
      ),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserScore.fromMap(Map<String, Object?> data) {
    final String userId = (data['userId'] ?? '') as String;
    final String? userName = data['userName'] as String?;

    // Parse high scores
    final Map<GameType, int> highScores = {};
    final Map<String, dynamic>? scoresMap =
        data['highScores'] as Map<String, dynamic>?;
    if (scoresMap != null) {
      for (final entry in scoresMap.entries) {
        final gameType = GameType.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => GameType.reactionTime,
        );
        highScores[gameType] = (entry.value as num?)?.toInt() ?? 0;
      }
    }

    // Parse total games played
    final Map<GameType, int> totalGamesPlayed = {};
    final Map<String, dynamic>? gamesMap =
        data['totalGamesPlayed'] as Map<String, dynamic>?;
    if (gamesMap != null) {
      for (final entry in gamesMap.entries) {
        final gameType = GameType.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => GameType.reactionTime,
        );
        totalGamesPlayed[gameType] = (entry.value as num?)?.toInt() ?? 0;
      }
    }

    // Parse last played dates
    final Map<GameType, DateTime> lastPlayedAt = {};
    final Map<String, dynamic>? datesMap =
        data['lastPlayedAt'] as Map<String, dynamic>?;
    if (datesMap != null) {
      for (final entry in datesMap.entries) {
        final gameType = GameType.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => GameType.reactionTime,
        );
        if (entry.value is Timestamp) {
          lastPlayedAt[gameType] = (entry.value as Timestamp).toDate();
        }
      }
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

    return UserScore(
      userId: userId,
      userName: userName,
      highScores: highScores,
      totalGamesPlayed: totalGamesPlayed,
      lastPlayedAt: lastPlayedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helper methods
  int getHighScore(GameType gameType) => highScores[gameType] ?? 0;
  int getTotalGames(GameType gameType) => totalGamesPlayed[gameType] ?? 0;
  DateTime? getLastPlayed(GameType gameType) => lastPlayedAt[gameType];

  // Get overall score (sum of all high scores)
  int get overallScore {
    return highScores.values.fold(0, (sum, score) => sum + score);
  }

  // Get total games played across all games
  int get totalGamesPlayedOverall {
    return totalGamesPlayed.values.fold(0, (sum, games) => sum + games);
  }

  // Create a copy with updated scores
  UserScore copyWith({
    String? userId,
    String? userName,
    Map<GameType, int>? highScores,
    Map<GameType, int>? totalGamesPlayed,
    Map<GameType, DateTime>? lastPlayedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserScore(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      highScores: highScores ?? this.highScores,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
