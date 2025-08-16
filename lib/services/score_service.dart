import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_score.dart';
import '../models/game_score.dart';
import 'app_logger.dart';

class ScoreService {
  ScoreService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static CollectionReference<Map<String, dynamic>> get _userScoresCollection =>
      _firestore.collection('user_scores');

  static CollectionReference<Map<String, dynamic>> get _gameScoresCollection =>
      _firestore.collection('game_scores');

  // Submit a game score and update user's high score
  static Future<void> submitGameScore({
    required GameType gameType,
    required int score,
    Map<String, dynamic>? gameData,
    String? userName,
  }) async {
    try {
      if (Firebase.apps.isEmpty) return;

      final String userId = await _getUserId();
      if (userId.isEmpty) return;

      // Check if this is a high score
      final bool isHighScore = await _isHighScore(userId, gameType, score);

      // Create game score record
      final GameScore gameScore = GameScore.create(
        userId: userId,
        userName: userName,
        gameType: gameType,
        score: score,
        gameData: gameData,
        isHighScore: isHighScore,
      );

      // Save game score
      await _gameScoresCollection.doc(gameScore.id).set(gameScore.toMap());

      // Update user's high score and stats
      await _updateUserScore(userId, userName, gameType, score, isHighScore);

      AppLogger.event('score.submitted', {
        'userId': userId,
        'gameType': gameType.name,
        'score': score,
        'isHighScore': isHighScore,
      });
    } catch (e, st) {
      AppLogger.error('score.submit', e, st);
      rethrow;
    }
  }

  // Get user's current score for a specific game
  static Future<int> getUserHighScore(GameType gameType) async {
    try {
      if (Firebase.apps.isEmpty) return 0;

      final String userId = await _getUserId();
      if (userId.isEmpty) return 0;

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _userScoresCollection.doc(userId).get();

      if (!doc.exists) return 0;

      final UserScore userScore = UserScore.fromMap(doc.data()!);
      return userScore.getHighScore(gameType);
    } catch (e, st) {
      AppLogger.error('score.getHighScore', e, st);
      return 0;
    }
  }

  // Get user's complete score profile
  static Future<UserScore?> getUserScoreProfile() async {
    try {
      if (Firebase.apps.isEmpty) return null;

      final String userId = await _getUserId();
      if (userId.isEmpty) return null;

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _userScoresCollection.doc(userId).get();

      if (!doc.exists) return null;

      return UserScore.fromMap(doc.data()!);
    } catch (e, st) {
      AppLogger.error('score.getUserProfile', e, st);
      return null;
    }
  }

  // Get recent game scores for a user
  static Stream<List<GameScore>> getUserRecentScores({
    GameType? gameType,
    int limit = 20,
  }) {
    if (Firebase.apps.isEmpty) {
      return Stream<List<GameScore>>.value(const <GameScore>[]);
    }

    Query<Map<String, dynamic>> query = _gameScoresCollection
        .where('userId', isEqualTo: _getUserId())
        .orderBy('playedAt', descending: true)
        .limit(limit);

    if (gameType != null) {
      query = query.where('gameType', isEqualTo: gameType.name);
    }

    return query.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      return snapshot.docs
          .map((doc) => GameScore.fromMap(doc.data()))
          .toList(growable: false);
    });
  }

  // Get leaderboard for a specific game
  static Stream<List<UserScore>> getGameLeaderboard(
    GameType gameType, {
    int limit = 10,
  }) {
    if (Firebase.apps.isEmpty) {
      return Stream<List<UserScore>>.value(const <UserScore>[]);
    }

    AppLogger.event('leaderboard.game', {
      'gameType': gameType.name,
      'limit': limit,
    });

    return _userScoresCollection
        .orderBy('highScores.${gameType.name}', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map((doc) => UserScore.fromMap(doc.data()))
              .toList(growable: false);
        });
  }

  // Get overall leaderboard (sum of all scores)
  static Stream<List<UserScore>> getOverallLeaderboard({int limit = 10}) {
    if (Firebase.apps.isEmpty) {
      return Stream<List<UserScore>>.value(const <UserScore>[]);
    }

    AppLogger.event('leaderboard.overall', {'limit': limit});

    // Note: This is a simplified approach. For production, consider using
    // a computed field or Cloud Functions for better performance
    return _userScoresCollection
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<UserScore> scores = snapshot.docs
              .map((doc) => UserScore.fromMap(doc.data()))
              .toList(growable: false);

          // Sort by overall score
          scores.sort((a, b) => b.overallScore.compareTo(a.overallScore));
          return scores.take(limit).toList(growable: false);
        });
  }

  // Get user's ranking in a specific game
  static Future<int> getUserRanking(GameType gameType) async {
    try {
      if (Firebase.apps.isEmpty) return 0;

      final String userId = await _getUserId();
      if (userId.isEmpty) return 0;

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _userScoresCollection
              .orderBy('highScores.${gameType.name}', descending: true)
              .get();

      final int userIndex = snapshot.docs.indexWhere(
        (doc) => doc.data()['userId'] == userId,
      );

      return userIndex >= 0 ? userIndex + 1 : 0;
    } catch (e, st) {
      AppLogger.error('score.getUserRanking', e, st);
      return 0;
    }
  }

  // Private helper methods
  static Future<String> _getUserId() async {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      return FirebaseAuth.instance.currentUser!.uid;
    }

    // Fallback to anonymous ID from SharedPreferences
    // This would need to be implemented based on your current user ID system
    return '';
  }

  static Future<bool> _isHighScore(
    String userId,
    GameType gameType,
    int score,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _userScoresCollection.doc(userId).get();

      if (!doc.exists) return true; // First score is always a high score

      final UserScore userScore = UserScore.fromMap(doc.data()!);
      final int currentHighScore = userScore.getHighScore(gameType);

      return score > currentHighScore;
    } catch (e, st) {
      AppLogger.error('score.isHighScore', e, st);
      return false;
    }
  }

  static Future<void> _updateUserScore(
    String userId,
    String? userName,
    GameType gameType,
    int score,
    bool isHighScore,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _userScoresCollection.doc(userId).get();

      UserScore userScore;

      if (!doc.exists) {
        // Create new user score profile
        userScore = UserScore(
          userId: userId,
          userName: userName,
          highScores: {gameType: score},
          totalGamesPlayed: {gameType: 1},
          lastPlayedAt: {gameType: DateTime.now()},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // Update existing user score profile
        userScore = UserScore.fromMap(doc.data()!);

        final Map<GameType, int> newHighScores = Map.from(userScore.highScores);
        final Map<GameType, int> newTotalGames = Map.from(
          userScore.totalGamesPlayed,
        );
        final Map<GameType, DateTime> newLastPlayed = Map.from(
          userScore.lastPlayedAt,
        );

        // Update high score if this is better
        if (isHighScore) {
          newHighScores[gameType] = score;
        }

        // Increment total games played
        newTotalGames[gameType] = (newTotalGames[gameType] ?? 0) + 1;

        // Update last played date
        newLastPlayed[gameType] = DateTime.now();

        userScore = userScore.copyWith(
          userName: userName ?? userScore.userName,
          highScores: newHighScores,
          totalGamesPlayed: newTotalGames,
          lastPlayedAt: newLastPlayed,
          updatedAt: DateTime.now(),
        );
      }

      // Calculate and store overall score
      final overallScore = userScore.overallScore;
      final totalGamesPlayedOverall = userScore.totalGamesPlayedOverall;
      
      // Update with calculated fields
      final updatedData = userScore.toMap();
      updatedData['overallScore'] = overallScore;
      updatedData['totalGamesPlayedOverall'] = totalGamesPlayedOverall;
      
      await _userScoresCollection.doc(userId).set(updatedData);
    } catch (e, st) {
      AppLogger.error('score.updateUserScore', e, st);
      rethrow;
    }
  }
}
