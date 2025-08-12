import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:human_benchmark/models/user_score.dart';

class LeaderboardService {
  LeaderboardService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('leaderboard');

  static Future<void> submitHighScore(UserScore score) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await _collection
          .doc(score.userId)
          .set(score.toMap(), SetOptions(merge: true));
    } catch (_) {
      // Intentionally ignore failures to avoid breaking UX if Firebase is not configured
    }
  }

  static Stream<List<UserScore>> topScores({int limit = 10}) {
    if (Firebase.apps.isEmpty) {
      return Stream<List<UserScore>>.value(const <UserScore>[]);
    }
    return _collection.orderBy('highScore').limit(limit).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      return snapshot.docs
          .map((doc) => UserScore.fromMap(doc.data()))
          .toList(growable: false);
    });
  }
}
