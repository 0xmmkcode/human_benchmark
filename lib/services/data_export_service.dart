import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_logger.dart';

class DataExportService {
  DataExportService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Export user data as JSON
  static Future<String> exportUserDataAsJson() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      
      // Get user scores
      final userScoreDoc = await _firestore
          .collection('user_scores')
          .doc(userId)
          .get();
      
      // Get game scores
      final gameScoresQuery = await _firestore
          .collection('game_scores')
          .where('userId', isEqualTo: userId)
          .orderBy('playedAt', descending: true)
          .get();

      // Get personality results if they exist
      final personalityResultsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('personalityResults')
          .get();

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userInfo': {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'emailVerified': user.emailVerified,
          'creationTime': user.metadata.creationTime?.toIso8601String(),
          'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
        },
        'userScores': userScoreDoc.exists ? userScoreDoc.data() : null,
        'gameScores': gameScoresQuery.docs.map((doc) => doc.data()).toList(),
        'personalityResults': personalityResultsQuery.docs.map((doc) => doc.data()).toList(),
      };

      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e, st) {
      AppLogger.error('data_export.json', e, st);
      rethrow;
    }
  }

  // Export user data as CSV
  static Future<String> exportUserDataAsCsv() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      
      // Get game scores
      final gameScoresQuery = await _firestore
          .collection('game_scores')
          .where('userId', isEqualTo: userId)
          .orderBy('playedAt', descending: true)
          .get();

      final csvData = StringBuffer();
      
      // Add header
      csvData.writeln('Game Type,Score,Played At,Is High Score,Game Data');
      
      // Add data rows
      for (final doc in gameScoresQuery.docs) {
        final data = doc.data();
        final gameType = data['gameType'] ?? '';
        final score = data['score'] ?? '';
        final playedAt = data['playedAt'] is Timestamp 
            ? (data['playedAt'] as Timestamp).toDate().toIso8601String()
            : '';
        final isHighScore = data['isHighScore'] ?? false;
        final gameData = data['gameData'] != null 
            ? json.encode(data['gameData']).replaceAll(',', ';')
            : '';
        
        csvData.writeln('$gameType,$score,$playedAt,$isHighScore,$gameData');
      }

      return csvData.toString();
    } catch (e, st) {
      AppLogger.error('data_export.csv', e, st);
      rethrow;
    }
  }

  // Get user statistics for display
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      
      // Get game scores
      final gameScoresQuery = await _firestore
          .collection('game_scores')
          .where('userId', isEqualTo: userId)
          .get();

      final scores = gameScoresQuery.docs.map((doc) => doc.data()).toList();
      
      // Calculate statistics
      final totalGames = scores.length;
      final highScores = scores.where((score) => score['isHighScore'] == true).length;
      final averageScore = scores.isNotEmpty 
          ? scores.map((score) => score['score'] as int).reduce((a, b) => a + b) / scores.length
          : 0;

      // Group by game type
      final gameTypeStats = <String, Map<String, dynamic>>{};
      for (final score in scores) {
        final gameType = score['gameType'] as String;
        if (!gameTypeStats.containsKey(gameType)) {
          gameTypeStats[gameType] = {
            'count': 0,
            'totalScore': 0,
            'highScores': 0,
            'bestScore': 0,
          };
        }
        
        final stats = gameTypeStats[gameType]!;
        stats['count'] = (stats['count'] as int) + 1;
        stats['totalScore'] = (stats['totalScore'] as int) + (score['score'] as int);
        if (score['isHighScore'] == true) {
          stats['highScores'] = (stats['highScores'] as int) + 1;
        }
        if ((score['score'] as int) > (stats['bestScore'] as int)) {
          stats['bestScore'] = score['score'];
        }
      }

      return {
        'totalGames': totalGames,
        'highScores': highScores,
        'averageScore': averageScore.round(),
        'gameTypeStats': gameTypeStats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e, st) {
      AppLogger.error('data_export.statistics', e, st);
      rethrow;
    }
  }
}
