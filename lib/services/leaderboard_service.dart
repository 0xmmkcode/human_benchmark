import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/services/app_logger.dart';

class LeaderboardService {
  LeaderboardService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('leaderboard');

  static Future<void> submitHighScore(UserScore score) async {
    try {
      if (Firebase.apps.isEmpty) return;
      AppLogger.event('leaderboard.submit', {
        'userId': score.userId,
        'overallScore': score.overallScore,
      });
      await _collection
          .doc(score.userId)
          .set(score.toMap(), SetOptions(merge: true));
    } catch (e, st) {
      // Intentionally ignore failures to avoid breaking UX if Firebase is not configured
      AppLogger.error('leaderboard.submit', e, st);
    }
  }

  static Stream<List<UserScore>> topScores({int limit = 10}) {
    if (Firebase.apps.isEmpty) {
      return Stream<List<UserScore>>.value(const <UserScore>[]);
    }
    AppLogger.event('leaderboard.topScores', {'limit': limit});
    return _collection
        .orderBy('overallScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map((doc) => UserScore.fromMap(doc.data()))
              .toList(growable: false);
        });
  }
}
