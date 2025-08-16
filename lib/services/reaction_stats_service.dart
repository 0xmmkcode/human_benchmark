import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/services/score_service.dart';

class ReactionStatsService {
  ReactionStatsService._();

  static const String _keyBestMs = 'rt_best_ms';
  static const String _keyTests = 'rt_tests_taken';
  static const String _keyAvgMs = 'rt_avg_ms';

  /// Loads locally stored stats. Returns a tuple-like map.
  static Future<Map<String, int?>> loadLocalStats() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int? best = prefs.getInt(_keyBestMs);
    // Migrate legacy key if present
    if (best == null) {
      final int? legacy = prefs.getInt('highScore');
      if (legacy != null) {
        best = legacy;
        await prefs.setInt(_keyBestMs, legacy);
      }
    }
    final int? tests = prefs.getInt(_keyTests);
    final int? avg = prefs.getInt(_keyAvgMs);
    return <String, int?>{'bestMs': best, 'testsTaken': tests, 'avgMs': avg};
  }

  /// Records a new reaction time result. If signed-in, also persists to Firestore (best effort).
  /// Returns updated stats map: {bestMs, testsTaken, avgMs}.
  static Future<Map<String, int>> recordResult(int reactionTimeMs) async {
    if (reactionTimeMs <= 0) {
      // Ignore invalid values (e.g., -1 for too early)
      final Map<String, int?> current = await loadLocalStats();
      return <String, int>{
        'bestMs': (current['bestMs'] ?? 0),
        'testsTaken': (current['testsTaken'] ?? 0),
        'avgMs': (current['avgMs'] ?? 0),
      };
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int currentBest = prefs.getInt(_keyBestMs) ?? 0;
    final int currentTests = prefs.getInt(_keyTests) ?? 0;
    final int currentAvg = prefs.getInt(_keyAvgMs) ?? 0;

    final int newTests = currentTests + 1;
    final int newAvg =
        ((currentAvg * currentTests) + reactionTimeMs) ~/
        (newTests == 0 ? 1 : newTests);
    final int newBest = (currentBest == 0)
        ? reactionTimeMs
        : (reactionTimeMs < currentBest ? reactionTimeMs : currentBest);

    await prefs.setInt(_keyBestMs, newBest);
    await prefs.setInt(_keyTests, newTests);
    await prefs.setInt(_keyAvgMs, newAvg);

    // Best effort remote sync if Firebase is available and user is signed in
    try {
      if (Firebase.apps.isNotEmpty) {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Use the new ScoreService to submit the game score
          await ScoreService.submitGameScore(
            gameType: GameType.reactionTime,
            score: newBest,
            gameData: {
              'testsTaken': newTests,
              'averageMs': newAvg,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            },
          );
        }
      }
    } catch (_) {
      // Ignore failures
    }

    return <String, int>{
      'bestMs': newBest,
      'testsTaken': newTests,
      'avgMs': newAvg,
    };
  }
}
