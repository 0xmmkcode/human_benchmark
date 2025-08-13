import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/decision_trial.dart';

class DecisionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DecisionTrial>> getTrials() async {
    final query = await _firestore
        .collection('decision_trials')
        .where('active', isEqualTo: true)
        .get();
    return query.docs
        .map((d) => DecisionTrial.fromJson(d.id, d.data()))
        .toList();
  }
}
