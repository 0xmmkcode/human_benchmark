import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/personality_question.dart';
import '../models/personality_scale.dart';
import '../models/personality_result.dart';
import '../models/personality_aggregates.dart';

class PersonalityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all personality questions
  Future<List<PersonalityQuestion>> getQuestions() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('personality_questions')
          .where('active', isEqualTo: true)
          .orderBy('id')
          .get();

      return snapshot.docs
          .map(
            (doc) => PersonalityQuestion.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch questions: $e');
    }
  }

  // Get personality scale
  Future<PersonalityScale> getScale() async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('personality_scale')
          .doc('bigfive_v1')
          .get();

      if (!doc.exists) {
        throw Exception('Personality scale not found');
      }

      return PersonalityScale.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch scale: $e');
    }
  }

  // Save user's personality result
  Future<void> saveResult(PersonalityResult result) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('personalityResults')
          .doc(result.id)
          .set(result.toJson());

      // Update aggregates
      await _updateAggregates(result);
    } catch (e) {
      throw Exception('Failed to save result: $e');
    }
  }

  // Get user's latest result
  Future<PersonalityResult?> getLatestResult() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('personalityResults')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return PersonalityResult.fromJson(
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to fetch latest result: $e');
    }
  }

  // Get user's all results
  Future<List<PersonalityResult>> getUserResults() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return [];

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('personalityResults')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                PersonalityResult.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user results: $e');
    }
  }

  // Get aggregates
  Future<PersonalityAggregates> getAggregates() async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('aggregates')
          .doc('bigfive_v1')
          .get();

      if (!doc.exists) {
        throw Exception('Aggregates not found');
      }

      return PersonalityAggregates.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch aggregates: $e');
    }
  }

  // Update aggregates when new result is added
  Future<void> _updateAggregates(PersonalityResult result) async {
    try {
      final DocumentReference docRef = _firestore
          .collection('aggregates')
          .doc('bigfive_v1');

      await _firestore.runTransaction((transaction) async {
        final DocumentSnapshot doc = await transaction.get(docRef);

        if (!doc.exists) {
          // Create initial aggregates
          final initialAggregates = PersonalityAggregates(
            counts: Map.fromEntries(
              result.traitScores.keys.map((trait) => MapEntry(trait, 1)),
            ),
            avg: result.traitScores,
            responses: 1,
          );
          transaction.set(docRef, initialAggregates.toJson());
        } else {
          // Update existing aggregates
          final currentData = doc.data() as Map<String, dynamic>;
          final currentCounts = Map<String, int>.from(
            currentData['counts'] as Map,
          );
          final currentAvg = Map<String, double>.from(
            currentData['avg'] as Map,
          );
          final currentResponses = currentData['responses'] as int;

          // Update counts and averages
          final newCounts = Map<String, int>.from(currentCounts);
          final newAvg = Map<String, double>.from(currentAvg);

          result.traitScores.forEach((trait, score) {
            newCounts[trait] = (newCounts[trait] ?? 0) + 1;
            final currentTotal = (newAvg[trait] ?? 0) * (newCounts[trait]! - 1);
            newAvg[trait] = (currentTotal + score) / newCounts[trait]!;
          });

          final updatedAggregates = PersonalityAggregates(
            counts: newCounts,
            avg: newAvg,
            responses: currentResponses + 1,
          );

          transaction.update(docRef, updatedAggregates.toJson());
        }
      });
    } catch (e) {
      // Log error but don't fail the main operation
      print('Failed to update aggregates: $e');
    }
  }
}
