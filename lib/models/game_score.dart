import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_score.dart';

class GameScore {
  final String id;
  final String userId;
  final String? userName;
  final GameType gameType;
  final int score;
  final Map<String, dynamic>? gameData; // Additional game-specific data
  final DateTime playedAt;
  final bool isHighScore;

  const GameScore({
    required this.id,
    required this.userId,
    this.userName,
    required this.gameType,
    required this.score,
    this.gameData,
    required this.playedAt,
    required this.isHighScore,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'userId': userId,
      'userName': userName,
      'gameType': gameType.name,
      'score': score,
      'gameData': gameData,
      'playedAt': Timestamp.fromDate(playedAt),
      'isHighScore': isHighScore,
    };
  }

  factory GameScore.fromMap(Map<String, Object?> data) {
    final String id = (data['id'] ?? '') as String;
    final String userId = (data['userId'] ?? '') as String;
    final String? userName = data['userName'] as String?;

    final String gameTypeName = (data['gameType'] ?? 'reactionTime') as String;
    final GameType gameType = GameType.values.firstWhere(
      (e) => e.name == gameTypeName,
      orElse: () => GameType.reactionTime,
    );

    final int score = (data['score'] as num?)?.toInt() ?? 0;
    final Map<String, dynamic>? gameData =
        data['gameData'] as Map<String, dynamic>?;

    DateTime playedAt = DateTime.now();
    if (data['playedAt'] is Timestamp) {
      playedAt = (data['playedAt'] as Timestamp).toDate();
    }

    final bool isHighScore = data['isHighScore'] as bool? ?? false;

    return GameScore(
      id: id,
      userId: userId,
      userName: userName,
      gameType: gameType,
      score: score,
      gameData: gameData,
      playedAt: playedAt,
      isHighScore: isHighScore,
    );
  }

  // Create a new game score
  factory GameScore.create({
    required String userId,
    String? userName,
    required GameType gameType,
    required int score,
    Map<String, dynamic>? gameData,
    bool isHighScore = false,
  }) {
    return GameScore(
      id: '${DateTime.now().millisecondsSinceEpoch}_${userId}_${gameType.name}',
      userId: userId,
      userName: userName,
      gameType: gameType,
      score: score,
      gameData: gameData,
      playedAt: DateTime.now(),
      isHighScore: isHighScore,
    );
  }

  // Copy with updates
  GameScore copyWith({
    String? id,
    String? userId,
    String? userName,
    GameType? gameType,
    int? score,
    Map<String, dynamic>? gameData,
    DateTime? playedAt,
    bool? isHighScore,
  }) {
    return GameScore(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      gameType: gameType ?? this.gameType,
      score: score ?? this.score,
      gameData: gameData ?? this.gameData,
      playedAt: playedAt ?? this.playedAt,
      isHighScore: isHighScore ?? this.isHighScore,
    );
  }

  // Get game type display name
  static String getDisplayName(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return 'Reaction Time';
      case GameType.decisionRisk:
        return 'Decision Risk';
      case GameType.personalityQuiz:
        return 'Personality Quiz';
      case GameType.numberMemory:
        return 'Number Memory';
      case GameType.verbalMemory:
        return 'Verbal Memory';
      case GameType.visualMemory:
        return 'Visual Memory';
      case GameType.typingSpeed:
        return 'Typing Speed';
      case GameType.aimTrainer:
        return 'Aim Trainer';
      case GameType.sequenceMemory:
        return 'Sequence Memory';
      case GameType.chimpTest:
        return 'Chimp Test';
    }
  }

  // Get score display (with units)
  static String getScoreDisplay(GameType gameType, int score) {
    switch (gameType) {
      case GameType.reactionTime:
        return '${score}ms';
      case GameType.decisionRisk:
        return score.toStringAsFixed(1);
      case GameType.personalityQuiz:
        return '${score}%';
      case GameType.numberMemory:
        return score.toString();
      case GameType.verbalMemory:
        return score.toString();
      case GameType.visualMemory:
        return score.toString();
      case GameType.typingSpeed:
        return '${score} WPM';
      case GameType.aimTrainer:
        return '${score}ms';
      case GameType.sequenceMemory:
        return score.toString();
      case GameType.chimpTest:
        return score.toString();
    }
  }
}
