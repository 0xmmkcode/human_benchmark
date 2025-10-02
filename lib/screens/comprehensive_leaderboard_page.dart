import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/models/game_score.dart';
import 'package:human_benchmark/models/user_profile.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/services/user_profile_service.dart';

class ComprehensiveLeaderboardPage extends ConsumerStatefulWidget {
  const ComprehensiveLeaderboardPage({super.key});

  @override
  ConsumerState<ComprehensiveLeaderboardPage> createState() =>
      _ComprehensiveLeaderboardPageState();
}

class _ComprehensiveLeaderboardPageState
    extends ConsumerState<ComprehensiveLeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: GameType.values.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade600,
          tabs: [
            const Tab(text: 'Overall'),
            ...GameType.values.map(
              (gameType) => Tab(text: _getShortGameName(gameType)),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverallLeaderboard(),
          ...GameType.values.map((gameType) => _buildGameLeaderboard(gameType)),
        ],
      ),
    );
  }

  Widget _buildOverallLeaderboard() {
    return StreamBuilder<List<UserProfile>>(
      stream: UserProfileService.getOverallLeaderboard(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load leaderboard',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final profiles = snapshot.data ?? [];

        if (profiles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No scores yet',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to play and set a record!',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            final rank = index + 1;

            return _buildLeaderboardItem(
              rank: rank,
              userProfile: profile,
              showOverallScore: true,
            );
          },
        );
      },
    );
  }

  Widget _buildGameLeaderboard(GameType gameType) {
    return StreamBuilder<List<UserProfile>>(
      stream: UserProfileService.getGameLeaderboard(gameType, limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load leaderboard',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final profiles = snapshot.data ?? [];

        if (profiles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getGameIcon(gameType),
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No scores yet for ${GameScore.getDisplayName(gameType)}',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to play and set a record!',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            final rank = index + 1;

            return _buildLeaderboardItem(
              rank: rank,
              userProfile: profile,
              gameType: gameType,
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    UserScore? userScore,
    UserProfile? userProfile,
    GameType? gameType,
    bool showOverallScore = false,
  }) {
    // Determine which data source to use
    final bool useProfile = userProfile != null;
    final String displayName = useProfile
        ? (userProfile!.displayName ?? 'Anonymous Player')
        : (userScore?.userName ?? 'Anonymous Player');

    final int score = gameType != null
        ? (useProfile
              ? userProfile!.getHighScore(gameType)
              : userScore!.getHighScore(gameType))
        : (useProfile ? userProfile!.overallScore : userScore!.overallScore);

    final scoreDisplay = gameType != null
        ? GameScore.getScoreDisplay(gameType, score)
        : score.toString();

    final int totalGames = gameType != null
        ? (useProfile
              ? userProfile!.getTotalGames(gameType)
              : userScore!.getTotalGames(gameType))
        : (useProfile
              ? userProfile!.totalGamesPlayed
              : userScore!.totalGamesPlayedOverall);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getRankColor(rank),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          gameType != null
              ? '${GameScore.getDisplayName(gameType)} • $totalGames games'
              : '$totalGames total games',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              scoreDisplay,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _getGameColor(gameType),
              ),
            ),
            if (showOverallScore && gameType != null)
              Text(
                'Overall: ${useProfile ? userProfile!.overallScore : userScore!.overallScore}',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600; // Gold
      case 2:
        return Colors.grey.shade400; // Silver
      case 3:
        return Colors.orange.shade600; // Bronze
      default:
        return Colors.blue.shade600;
    }
  }

  Color _getGameColor(GameType? gameType) {
    if (gameType == null) return Colors.amber.shade600;

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
        return Colors.red.shade600;
      case GameType.aimTrainer:
        return Colors.pink.shade600;
      case GameType.sequenceMemory:
        return Colors.cyan.shade600;
      case GameType.chimpTest:
        return Colors.amber.shade600;
    }
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
        return Icons.keyboard;
      case GameType.aimTrainer:
        return Icons.gps_fixed;
      case GameType.sequenceMemory:
        return Icons.format_list_numbered;
      case GameType.chimpTest:
        return Icons.psychology;
    }
  }

  String _getShortGameName(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return 'Reaction';
      case GameType.decisionRisk:
        return 'Decision';
      case GameType.personalityQuiz:
        return 'Personality';
      case GameType.numberMemory:
        return 'Numbers';
      case GameType.verbalMemory:
        return 'Verbal';
      case GameType.visualMemory:
        return 'Visual';
      case GameType.aimTrainer:
        return 'Aim';
      case GameType.sequenceMemory:
        return 'Sequence';
      case GameType.chimpTest:
        return 'Chimp';
    }
  }
}
