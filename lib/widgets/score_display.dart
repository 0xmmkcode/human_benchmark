import 'package:flutter/material.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/models/game_score.dart';

class ScoreDisplay extends StatelessWidget {
  final UserScore? userScore;
  final GameType? currentGame;
  final VoidCallback? onViewLeaderboard;

  const ScoreDisplay({
    super.key,
    this.userScore,
    this.currentGame,
    this.onViewLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    if (userScore == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Your Scores',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              if (onViewLeaderboard != null)
                TextButton(
                  onPressed: onViewLeaderboard,
                  child: Text(
                    'View Leaderboard',
                    style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Current game score (if specified)
          if (currentGame != null) ...[
            _buildGameScoreRow(
              currentGame!,
              userScore!.getHighScore(currentGame!),
              userScore!.getTotalGames(currentGame!),
              isHighlighted: true,
            ),
            const Divider(height: 24),
          ],

          // Overall stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Overall Score',
                  '${userScore!.overallScore}',
                  Icons.star,
                  Colors.amber.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Games Played',
                  '${userScore!.totalGamesPlayedOverall}',
                  Icons.games,
                  Colors.green.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recent high scores
          Text(
            'Recent High Scores',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          // Show top 3 recent scores
          ...userScore!.highScores.entries
              .where((entry) => entry.value > 0)
              .take(3)
              .map(
                (entry) => _buildGameScoreRow(
                  entry.key,
                  entry.value,
                  userScore!.getTotalGames(entry.key),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildGameScoreRow(
    GameType gameType,
    int score,
    int gamesPlayed, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isHighlighted ? Border.all(color: Colors.blue.shade200) : null,
      ),
      child: Row(
        children: [
          Icon(
            _getGameIcon(gameType),
            size: 20,
            color: _getGameColor(gameType),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GameScore.getDisplayName(gameType),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  '$gamesPlayed games played',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            GameScore.getScoreDisplay(gameType, score),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getGameColor(gameType),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getGameIcon(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return Icons.timer;
      case GameType.decisionRisk:
        return Icons.psychology;
      case GameType.personalityQuiz:
        return Icons.person;
      case GameType.numberMemory:
        return Icons.numbers;
      case GameType.verbalMemory:
        return Icons.text_fields;
      case GameType.visualMemory:
        return Icons.visibility;
      case GameType.typingSpeed:
        return Icons.keyboard;
      case GameType.aimTrainer:
        return Icons.gps_fixed;
      case GameType.sequenceMemory:
        return Icons.format_list_numbered;
      case GameType.chimpTest:
        return Icons.psychology;
    }
  }

  Color _getGameColor(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return Colors.blue.shade600;
      case GameType.decisionRisk:
        return Colors.purple.shade600;
      case GameType.personalityQuiz:
        return Colors.indigo.shade600;
      case GameType.numberMemory:
        return Colors.green.shade600;
      case GameType.verbalMemory:
        return Colors.orange.shade600;
      case GameType.visualMemory:
        return Colors.teal.shade600;
      case GameType.typingSpeed:
        return Colors.red.shade600;
      case GameType.aimTrainer:
        return Colors.pink.shade600;
      case GameType.sequenceMemory:
        return Colors.cyan.shade600;
      case GameType.chimpTest:
        return Colors.amber.shade600;
    }
  }
}
