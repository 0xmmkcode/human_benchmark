import 'package:cloud_firestore/cloud_firestore.dart';

class UserScore {
  final String userId;
  final int highScoreMs;
  final DateTime lastPlayedAt;

  const UserScore({
    required this.userId,
    required this.highScoreMs,
    required this.lastPlayedAt,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'userId': userId,
      'highScore': highScoreMs,
      'lastPlayedAt': Timestamp.fromDate(lastPlayedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserScore.fromMap(Map<String, Object?> data) {
    final Object? userIdValue = data['userId'];
    final Object? highScoreValue = data['highScore'];
    final Object? lastPlayedValue = data['lastPlayedAt'];

    final String parsedUserId = (userIdValue ?? '') as String;
    final int parsedHighScore = (highScoreValue is int)
        ? highScoreValue
        : int.tryParse(highScoreValue?.toString() ?? '') ?? 0;

    DateTime parsedLastPlayed;
    if (lastPlayedValue is Timestamp) {
      parsedLastPlayed = lastPlayedValue.toDate();
    } else if (lastPlayedValue is DateTime) {
      parsedLastPlayed = lastPlayedValue;
    } else {
      parsedLastPlayed = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return UserScore(
      userId: parsedUserId,
      highScoreMs: parsedHighScore,
      lastPlayedAt: parsedLastPlayed,
    );
  }
}
