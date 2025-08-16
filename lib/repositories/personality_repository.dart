import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/personality_question.dart';
import '../models/personality_scale.dart';
import '../models/personality_result.dart';
import '../models/personality_aggregates.dart';
import '../services/app_logger.dart';

class PersonalityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all personality questions
  Future<List<PersonalityQuestion>> getQuestions() async {
    try {
      AppLogger.event('firestore.query', {
        'collection': 'personality_questions',
        'where': {'active': true},
        'orderBy': 'id',
      });
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
    } catch (e, st) {
      AppLogger.error('getQuestions', e, st);
      // Fallback for missing composite index on web: fetch without order and sort locally
      if (e is FirebaseException && e.code == 'failed-precondition') {
        try {
          AppLogger.event('firestore.query.fallback', {
            'collection': 'personality_questions',
            'where': {'active': true},
          });
          final QuerySnapshot fallback = await _firestore
              .collection('personality_questions')
              .where('active', isEqualTo: true)
              .get();
          final List<PersonalityQuestion> items = fallback.docs
              .map(
                (doc) => PersonalityQuestion.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
          items.sort((a, b) => a.id.compareTo(b.id));
          return items;
        } catch (inner, st2) {
          AppLogger.error('getQuestions.fallback', inner, st2);
          throw Exception('Failed to fetch questions (fallback): $inner');
        }
      }
      throw Exception('Failed to fetch questions: $e');
    }
  }

  // Get top personality results for a specific trait
  Future<List<PersonalityResult>> getTopResults({
    required String trait,
    int limit = 10,
  }) async {
    try {
      AppLogger.event('firestore.query', {
        'collection': 'personality_results',
        'orderBy': 'normalizedScores.$trait',
        'limit': limit,
      });
      
      final QuerySnapshot snapshot = await _firestore
          .collection('personality_results')
          .orderBy('normalizedScores.$trait', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PersonalityResult.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('getTopResults', e, st);
      // Fallback: get all results and sort locally
      try {
        final QuerySnapshot fallback = await _firestore
            .collection('personality_results')
            .limit(100)
            .get();
        
        final List<PersonalityResult> results = fallback.docs
            .map((doc) => PersonalityResult.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        
        // Sort by the specified trait score
        results.sort((a, b) => (b.normalizedScores[trait] ?? 0).compareTo(a.normalizedScores[trait] ?? 0));
        
        return results.take(limit).toList();
      } catch (inner, st2) {
        AppLogger.error('getTopResults.fallback', inner, st2);
        return [];
      }
    }
  }

  // Get personality scale
  Future<PersonalityScale> getScale() async {
    try {
      AppLogger.event('firestore.get', {'doc': 'personality_scale/bigfive_v1'});
      final DocumentSnapshot doc = await _firestore
          .collection('personality_scale')
          .doc('bigfive_v1')
          .get();

      if (!doc.exists) {
        // Fallback to a safe default scale to avoid breaking UX
        return _defaultScale();
      }

      final data = doc.data() as Map<String, dynamic>;

      // Be resilient to data shape differences
      final dynamic rawScale = data['scale'];
      final List<ScaleOption> scaleOptions;
      if (rawScale is List) {
        scaleOptions = rawScale
            .map<ScaleOption>((e) {
              if (e is Map<String, dynamic>) {
                final dynamic v = e['value'];
                final dynamic l = e['label'];
                final int value = v is int
                    ? v
                    : (v is num
                          ? v.toInt()
                          : (v is String ? int.tryParse(v) ?? 0 : 0));
                final String label = l?.toString() ?? value.toString();
                return ScaleOption(value: value, label: label);
              }
              if (e is num) {
                final int value = e.toInt();
                return ScaleOption(value: value, label: value.toString());
              }
              return const ScaleOption(value: 0, label: '');
            })
            .where((s) => s.value != 0 || s.label.isNotEmpty)
            .toList();
      } else {
        scaleOptions = _defaultScale().scale;
      }

      final List<String> traits = (data['traits'] is List)
          ? List<String>.from((data['traits'] as List).map((e) => e.toString()))
          : _defaultScale().traits;

      final dynamic qptRaw = data['questionsPerTrait'];
      final int questionsPerTrait = qptRaw is int
          ? qptRaw
          : (qptRaw is num
                ? qptRaw.toInt()
                : _defaultScale().questionsPerTrait);

      return PersonalityScale(
        scale: scaleOptions,
        traits: traits,
        questionsPerTrait: questionsPerTrait,
      );
    } catch (e, st) {
      AppLogger.error('getScale', e, st);
      // Fallback to default on format/permission errors to keep the quiz usable
      return _defaultScale();
    }
  }

  PersonalityScale _defaultScale() {
    return PersonalityScale(
      scale: const [
        ScaleOption(value: 1, label: 'Strongly disagree'),
        ScaleOption(value: 2, label: 'Disagree'),
        ScaleOption(value: 3, label: 'Neutral'),
        ScaleOption(value: 4, label: 'Agree'),
        ScaleOption(value: 5, label: 'Strongly agree'),
      ],
      traits: const [
        'Openness',
        'Conscientiousness',
        'Extraversion',
        'Agreeableness',
        'Neuroticism',
      ],
      questionsPerTrait: 10,
    );
  }

  // Save user's personality result
  Future<void> saveResult(PersonalityResult result) async {
    try {
      AppLogger.event('saveResult.start', {'resultId': result.id});
      final User? user = _auth.currentUser;
      if (user == null) {
        // If user isn't signed in, skip remote save silently.
        AppLogger.log('saveResult.skipped (anonymous)', {
          'resultId': result.id,
        });
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('personalityResults')
          .doc(result.id)
          .set(result.toJson());

      // Update aggregates
      await _updateAggregates(result);
      AppLogger.event('saveResult.success', {
        'resultId': result.id,
        'userId': user.uid,
      });
    } catch (e) {
      AppLogger.error('saveResult', e);
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
      AppLogger.event('firestore.get', {'doc': 'aggregates/bigfive_v1'});
      final DocumentSnapshot doc = await _firestore
          .collection('aggregates')
          .doc('bigfive_v1')
          .get();

      if (!doc.exists) {
        throw Exception('Aggregates not found');
      }

      return PersonalityAggregates.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e, st) {
      AppLogger.error('getAggregates', e, st);
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
      AppLogger.error('_updateAggregates', e);
    }
  }
}
