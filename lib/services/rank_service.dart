import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/rank.dart';
import 'app_logger.dart';

class RankService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ranksCollection = 'ranks';

  // Get all ranks ordered by order field
  static Future<List<Rank>> getAllRanks() async {
    try {
      if (Firebase.apps.isEmpty) {
        AppLogger.log('Firebase not initialized, returning empty ranks list');
        return [];
      }

      AppLogger.event('ranks.getAllRanks');

      // Fetch without Firestore ordering to avoid type-mismatch issues on 'order'
      // We'll normalize and sort client-side for robustness
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(_ranksCollection)
          .get();

      final List<Rank> ranks = [];
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final Map<String, Object?> data = Map<String, Object?>.from(doc.data());
        // Ensure id field exists
        data['id'] ??= doc.id;
        // Normalize order to int and default to index+1 if missing/invalid
        final dynamic rawOrder = data['order'];
        if (rawOrder is num) {
          data['order'] = rawOrder.toInt();
        } else {
          data['order'] = i + 1;
        }
        ranks.add(Rank.fromMap(data));
      }
      // Sort client-side by normalized order
      ranks.sort((a, b) => a.order.compareTo(b.order));
      AppLogger.log('ranks.getAllRanks -> returning ${ranks.length} ranks');
      return ranks;
    } catch (e, st) {
      AppLogger.error('ranks.getAllRanks', e, st);
      return [];
    }
  }

  // Get all ranks as a stream
  static Stream<List<Rank>> getAllRanksStream() {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value([]);
      }

      AppLogger.event('ranks.getAllRanksStream');

      return _firestore.collection(_ranksCollection).snapshots().map((
        snapshot,
      ) {
        final List<Rank> ranks = [];
        for (int i = 0; i < snapshot.docs.length; i++) {
          final doc = snapshot.docs[i];
          final Map<String, Object?> data = Map<String, Object?>.from(
            doc.data(),
          );
          data['id'] ??= doc.id;
          final dynamic rawOrder = data['order'];
          if (rawOrder is num) {
            data['order'] = rawOrder.toInt();
          } else {
            data['order'] = i + 1;
          }
          ranks.add(Rank.fromMap(data));
        }
        ranks.sort((a, b) => a.order.compareTo(b.order));
        AppLogger.log('ranks.getAllRanksStream -> emit ${ranks.length} ranks');
        return ranks;
      });
    } catch (e, st) {
      AppLogger.error('ranks.getAllRanksStream', e, st);
      return Stream.value([]);
    }
  }

  // Get a specific rank by ID
  static Future<Rank?> getRankById(String rankId) async {
    try {
      if (Firebase.apps.isEmpty) return null;

      AppLogger.event('ranks.getRankById', {'rankId': rankId});

      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection(_ranksCollection)
          .doc(rankId)
          .get();

      if (!doc.exists) return null;

      return Rank.fromMap(doc.data()!);
    } catch (e, st) {
      AppLogger.error('ranks.getRankById', e, st);
      return null;
    }
  }

  // Get the rank that a user qualifies for based on their global score
  static Future<Rank?> getUserRank(int globalScore) async {
    try {
      if (Firebase.apps.isEmpty) return null;

      AppLogger.event('ranks.getUserRank', {'globalScore': globalScore});

      final List<Rank> ranks = await getAllRanks();

      // Find the highest rank the user qualifies for
      Rank? userRank;
      for (final rank in ranks) {
        if (rank.qualifiesForRank(globalScore)) {
          userRank = rank;
        }
      }

      return userRank;
    } catch (e, st) {
      AppLogger.error('ranks.getUserRank', e, st);
      return null;
    }
  }

  // Get the rank that a user qualifies for as a stream
  static Stream<Rank?> getUserRankStream(int globalScore) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(null);
      }

      AppLogger.event('ranks.getUserRankStream', {'globalScore': globalScore});

      return getAllRanksStream().map((ranks) {
        // Find the highest rank the user qualifies for
        Rank? userRank;
        for (final rank in ranks) {
          if (rank.qualifiesForRank(globalScore)) {
            userRank = rank;
          }
        }
        return userRank;
      });
    } catch (e, st) {
      AppLogger.error('ranks.getUserRankStream', e, st);
      return Stream.value(null);
    }
  }

  // Get rank progress information for a user
  static Future<Map<String, dynamic>?> getRankProgress(int globalScore) async {
    try {
      if (Firebase.apps.isEmpty) return null;

      AppLogger.event('ranks.getRankProgress', {'globalScore': globalScore});

      final List<Rank> ranks = await getAllRanks();

      // Find current rank and next rank
      Rank? currentRank;
      Rank? nextRank;

      for (int i = 0; i < ranks.length; i++) {
        final rank = ranks[i];
        if (rank.qualifiesForRank(globalScore)) {
          currentRank = rank;
          // Next rank is the one after current (if exists)
          if (i + 1 < ranks.length) {
            nextRank = ranks[i + 1];
          }
        }
      }

      if (currentRank == null) return null;

      final double progress = currentRank.calculateProgress(globalScore);
      final int pointsToNext = nextRank != null
          ? nextRank.minGlobalScore - globalScore
          : 0;

      return {
        'currentRank': currentRank,
        'nextRank': nextRank,
        'progress': progress,
        'pointsToNext': pointsToNext,
        'isMaxRank': nextRank == null,
      };
    } catch (e, st) {
      AppLogger.error('ranks.getRankProgress', e, st);
      return null;
    }
  }

  // Get rank progress as a stream
  static Stream<Map<String, dynamic>?> getRankProgressStream(int globalScore) {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(null);
      }

      AppLogger.event('ranks.getRankProgressStream', {
        'globalScore': globalScore,
      });

      return getAllRanksStream().map((ranks) {
        // Find current rank and next rank
        Rank? currentRank;
        Rank? nextRank;

        for (int i = 0; i < ranks.length; i++) {
          final rank = ranks[i];
          if (rank.qualifiesForRank(globalScore)) {
            currentRank = rank;
            // Next rank is the one after current (if exists)
            if (i + 1 < ranks.length) {
              nextRank = ranks[i + 1];
            }
          }
        }

        if (currentRank == null) return null;

        final double progress = currentRank.calculateProgress(globalScore);
        final int pointsToNext = nextRank != null
            ? nextRank.minGlobalScore - globalScore
            : 0;

        return {
          'currentRank': currentRank,
          'nextRank': nextRank,
          'progress': progress,
          'pointsToNext': pointsToNext,
          'isMaxRank': nextRank == null,
        };
      });
    } catch (e, st) {
      AppLogger.error('ranks.getRankProgressStream', e, st);
      return Stream.value(null);
    }
  }

  // Create a new rank (admin only)
  static Future<bool> createRank(Rank rank) async {
    try {
      if (Firebase.apps.isEmpty) return false;

      AppLogger.event('ranks.createRank', {'rankId': rank.id});

      await _firestore
          .collection(_ranksCollection)
          .doc(rank.id)
          .set(rank.toMap());

      AppLogger.log('Rank created successfully: ${rank.id}');
      return true;
    } catch (e, st) {
      AppLogger.error('ranks.createRank', e, st);
      return false;
    }
  }

  // Update an existing rank (admin only)
  static Future<bool> updateRank(String rankId, Rank rank) async {
    try {
      if (Firebase.apps.isEmpty) return false;

      AppLogger.event('ranks.updateRank', {'rankId': rankId});

      await _firestore
          .collection(_ranksCollection)
          .doc(rankId)
          .update(rank.toMap());

      AppLogger.log('Rank updated successfully: $rankId');
      return true;
    } catch (e, st) {
      AppLogger.error('ranks.updateRank', e, st);
      return false;
    }
  }

  // Delete a rank (admin only)
  static Future<bool> deleteRank(String rankId) async {
    try {
      if (Firebase.apps.isEmpty) return false;

      AppLogger.event('ranks.deleteRank', {'rankId': rankId});

      await _firestore.collection(_ranksCollection).doc(rankId).delete();

      AppLogger.log('Rank deleted successfully: $rankId');
      return true;
    } catch (e, st) {
      AppLogger.error('ranks.deleteRank', e, st);
      return false;
    }
  }

  // Initialize default ranks (admin only)
  static Future<bool> initializeDefaultRanks() async {
    try {
      if (Firebase.apps.isEmpty) return false;

      AppLogger.event('ranks.initializeDefaultRanks');

      final List<Rank> defaultRanks = [
        Rank(
          id: 'rookie',
          name: 'Rookie',
          description: 'Just getting started on your cognitive journey',
          minGlobalScore: 0,
          maxGlobalScore: 999,
          color: '#6B7280',
          icon: 'person',
          order: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Rank(
          id: 'apprentice',
          name: 'Apprentice',
          description: 'Developing your mental abilities',
          minGlobalScore: 1000,
          maxGlobalScore: 1999,
          color: '#10B981',
          icon: 'school',
          order: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Rank(
          id: 'adept',
          name: 'Adept',
          description: 'Showing consistent improvement',
          minGlobalScore: 2000,
          maxGlobalScore: 2999,
          color: '#3B82F6',
          icon: 'trending_up',
          order: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Rank(
          id: 'expert',
          name: 'Expert',
          description: 'Mastering multiple cognitive domains',
          minGlobalScore: 3000,
          maxGlobalScore: 3999,
          color: '#8B5CF6',
          icon: 'star',
          order: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Rank(
          id: 'master',
          name: 'Master',
          description: 'Exceptional cognitive performance',
          minGlobalScore: 4000,
          maxGlobalScore: 4999,
          color: '#F59E0B',
          icon: 'emoji_events',
          order: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Rank(
          id: 'grandmaster',
          name: 'Grandmaster',
          description: 'Elite level cognitive abilities',
          minGlobalScore: 5000,
          maxGlobalScore: 5999,
          color: '#EF4444',
          icon: 'military_tech',
          order: 6,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Rank(
          id: 'legend',
          name: 'Legend',
          description: 'Transcendent cognitive performance',
          minGlobalScore: 6000,
          maxGlobalScore: 999999,
          color: '#DC2626',
          icon: 'workspace_premium',
          order: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Batch write all ranks
      final WriteBatch batch = _firestore.batch();

      for (final rank in defaultRanks) {
        final docRef = _firestore.collection(_ranksCollection).doc(rank.id);
        batch.set(docRef, rank.toMap());
      }

      await batch.commit();

      AppLogger.log('Default ranks initialized successfully');
      return true;
    } catch (e, st) {
      AppLogger.error('ranks.initializeDefaultRanks', e, st);
      return false;
    }
  }
}
