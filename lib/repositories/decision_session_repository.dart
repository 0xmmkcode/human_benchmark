import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/decision_trial.dart';

class DecisionSessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveSession({
    required List<DecisionResponse> responses,
    required int totalTrials,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return; // skip when not signed in

    final int total = responses.length;
    final int risky = responses.where((r) => r.choseRisky).length;
    final int timeMs = responses
        .map((r) => r.responseTime.inMilliseconds)
        .fold<int>(0, (a, b) => a + b);
    final int avgMs = total == 0 ? 0 : (timeMs / total).round();
    final double totalScore = responses.fold<double>(
      0,
      (a, r) => a + (r.score),
    );
    final int riskPct = total == 0 ? 0 : ((risky / total) * 100).round();

    final sessionData = {
      'userId': user.uid,
      'createdAt': DateTime.now().toIso8601String(),
      'totalTrials': totalTrials,
      'totalResponses': total,
      'riskyChoices': risky,
      'riskPercentage': riskPct,
      'avgDecisionMs': avgMs,
      'totalScore': totalScore,
      'responses': responses
          .map(
            (r) => {
              'trialId': r.trialId,
              'chosenLabel': r.chosenLabel,
              'choseRisky': r.choseRisky,
              'responseMs': r.responseTime.inMilliseconds,
              'timedOut': r.timedOut,
              'score': r.score,
            },
          )
          .toList(),
    };

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('decisionSessions')
        .doc();
    await docRef.set(sessionData);
  }
}
