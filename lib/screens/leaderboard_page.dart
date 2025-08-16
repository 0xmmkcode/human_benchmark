import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/models/game_score.dart';
import 'package:human_benchmark/widgets/reaction_time_leaderboard.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  final List<GameType> _gameTypes = [
    GameType.reactionTime,
    GameType.numberMemory,
    GameType.personalityQuiz,
    GameType.decisionRisk,
  ];

  final List<String> _gameTypeNames = [
    'Reaction Time',
    'Number Memory',
    'Personality Quiz',
    'Decision Making',
  ];

  final List<IconData> _gameTypeIcons = [
    Icons.timer,
    Icons.memory,
    Icons.psychology,
    Icons.speed,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _gameTypes.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Leaderboards',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey[800],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue[600],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue[600],
          tabs: _gameTypes.asMap().entries.map((entry) {
            final index = entry.key;
            final gameType = entry.value;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_gameTypeIcons[index], size: 20),
                  const Gap(8),
                  Text(_gameTypeNames[index]),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _gameTypes.map((gameType) {
          return _buildLeaderboardTab(gameType);
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderboardTab(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return const ReactionTimeLeaderboard(
          showTitle: false,
          maxItems: 20,
          showLocalScores: true,
        );
      case GameType.numberMemory:
        return _buildNumberMemoryLeaderboard();
      case GameType.personalityQuiz:
        return _buildPersonalityLeaderboard();
      case GameType.decisionRisk:
        return _buildDecisionMakingLeaderboard();
      default:
        return const Center(child: Text('Leaderboard not available'));
    }
  }

  Widget _buildNumberMemoryLeaderboard() {
    return FutureBuilder<List<GameScore>>(
      future: ScoreService.getTopScores(
        gameType: GameType.numberMemory,
        limit: 20,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const Gap(16),
                Text(
                  'Failed to load leaderboard',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final scores = snapshot.data ?? [];
        if (scores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const Gap(16),
                Text(
                  'No scores yet',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const Gap(8),
                Text(
                  'Be the first to play!',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scores.length,
          itemBuilder: (context, index) {
            final score = scores[index];
            final rank = index + 1;
            final isTop3 = rank <= 3;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTop3 ? Colors.amber[300]! : Colors.grey[200]!,
                  width: isTop3 ? 2 : 1,
                ),
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
                    color: isTop3 ? Colors.amber[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      rank.toString(),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isTop3 ? Colors.amber[800] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                title: Text(
                  score.userName ?? 'Anonymous',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  'Level: ${score.gameData?['finalLevel'] ?? 'N/A'} • Total Score: ${score.score}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Text(
                  '${score.score} pts',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPersonalityLeaderboard() {
    return FutureBuilder<List<GameScore>>(
      future: ScoreService.getTopScores(
        gameType: GameType.personalityQuiz,
        limit: 20,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const Gap(16),
                Text(
                  'Failed to load leaderboard',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final scores = snapshot.data ?? [];
        if (scores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const Gap(16),
                Text(
                  'No scores yet',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const Gap(8),
                Text(
                  'Be the first to take the quiz!',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scores.length,
          itemBuilder: (context, index) {
            final score = scores[index];
            final rank = index + 1;
            final isTop3 = rank <= 3;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTop3 ? Colors.amber[300]! : Colors.grey[200]!,
                  width: isTop3 ? 2 : 1,
                ),
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
                    color: isTop3 ? Colors.amber[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      rank.toString(),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isTop3 ? Colors.amber[800] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                title: Text(
                  score.userName ?? 'Anonymous',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  'Personality Score: ${score.score}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Text(
                  '${score.score} pts',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDecisionMakingLeaderboard() {
    return FutureBuilder<List<GameScore>>(
      future: ScoreService.getTopScores(
        gameType: GameType.decisionRisk,
        limit: 20,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const Gap(16),
                Text(
                  'Failed to load leaderboard',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final scores = snapshot.data ?? [];
        if (scores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const Gap(16),
                Text(
                  'No scores yet',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const Gap(8),
                Text(
                  'Be the first to play!',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scores.length,
          itemBuilder: (context, index) {
            final score = scores[index];
            final rank = index + 1;
            final isTop3 = rank <= 3;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTop3 ? Colors.amber[300]! : Colors.grey[200]!,
                  width: isTop3 ? 2 : 1,
                ),
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
                    color: isTop3 ? Colors.amber[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      rank.toString(),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isTop3 ? Colors.amber[800] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                title: Text(
                  score.userName ?? 'Anonymous',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  'Decision Score: ${score.score}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Text(
                  '${score.score} pts',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
