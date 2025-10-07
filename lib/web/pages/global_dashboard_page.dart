import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/services/dashboard_service.dart';
import 'package:human_benchmark/services/game_management_service.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/models/game_score.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/widgets/app_loading.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';

class GlobalDashboardPage extends StatefulWidget {
  const GlobalDashboardPage({super.key});

  @override
  State<GlobalDashboardPage> createState() => _GlobalDashboardPageState();
}

class _GlobalDashboardPageState extends State<GlobalDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Page Header
            PageHeader(
              title: 'Global Statistics',
              subtitle: 'View global statistics and leaderboards.',
            ),
            const Gap(24),
            Expanded(child: _buildDashboardContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return StreamBuilder<DashboardOverview>(
      stream: DashboardService.getDashboardOverviewStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoading());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const Gap(16),
                const Text(
                  'Failed to load global statistics',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const Gap(8),
                const Text(
                  'Please try again later',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final overview = snapshot.data ?? DashboardOverview.empty();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Row
              _buildStatisticsRow(overview),
              const Gap(24),

              // Two Cards Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top 10 Leaderboard Card
                  Expanded(child: _buildTopLeaderboardCard()),
                  const Gap(16),
                  // Recent Scores Card
                  Expanded(child: _buildRecentScoresCard()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsRow(DashboardOverview overview) {
    return FutureBuilder<Map<String, int>>(
      future: _getStatisticsData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Games',
                  '...',
                  Icons.games,
                  Colors.blue,
                ),
              ),
              const Gap(16),
              Expanded(
                child: _buildStatCard(
                  'Active Players',
                  '...',
                  Icons.people,
                  Colors.green,
                ),
              ),
              const Gap(16),
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  '...',
                  Icons.person,
                  Colors.orange,
                ),
              ),
            ],
          );
        }

        final data =
            snapshot.data ??
            {'totalGames': 0, 'activePlayers': 0, 'totalUsers': 0};

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Games',
                '${data['totalGames'] ?? 0}',
                Icons.games,
                Colors.blue,
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildStatCard(
                'Active Players',
                '${data['activePlayers'] ?? 0}',
                Icons.people,
                Colors.green,
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildStatCard(
                'Total Users',
                '${data['totalUsers'] ?? 0}',
                Icons.person,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _getStatisticsData() async {
    try {
      // Get total games from game management
      final games = await GameManagementService.getAllGameManagement();
      final totalGames = games.length;

      // Get total users and active players from dashboard overview
      final overview = await DashboardService.getDashboardOverview();

      return {
        'totalGames': totalGames,
        'activePlayers': overview.activeUsersToday,
        'totalUsers': overview.totalUsers,
      };
    } catch (e) {
      return {'totalGames': 0, 'activePlayers': 0, 'totalUsers': 0};
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const Gap(12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopLeaderboardCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: WebTheme.primaryBlue, size: 24),
              const Gap(12),
              Text(
                'Top 10 Leaderboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const Gap(16),
          StreamBuilder<List<PlayerDashboardData>>(
            stream: DashboardService.getAllPlayers(limit: 10),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: AppLoading());
              }

              if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Text(
                    'Failed to load leaderboard',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              final players = snapshot.data!;

              if (players.isEmpty) {
                return Center(
                  child: Text(
                    'No players yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return Column(
                children: players.asMap().entries.map((entry) {
                  final index = entry.key;
                  final player = entry.value;
                  final isTop3 = index < 3;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isTop3
                            ? WebTheme.primaryBlue
                            : Colors.grey[200]!,
                        width: isTop3 ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Rank
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isTop3
                                ? WebTheme.primaryBlue
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isTop3 ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const Gap(12),
                        // Player Name
                        Expanded(
                          child: Text(
                            player.userName ?? 'Anonymous',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        // Score
                        Text(
                          '${player.overallScore}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isTop3
                                ? WebTheme.primaryBlue
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScoresCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.green, size: 24),
              const Gap(12),
              Text(
                'Recent Scores',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const Gap(16),
          StreamBuilder<List<GameScore>>(
            stream: _getRecentScoresStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: AppLoading());
              }

              if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Text(
                    'Failed to load recent scores',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              final scores = snapshot.data!;

              if (scores.isEmpty) {
                return Center(
                  child: Text(
                    'No recent scores',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return Column(
                children: scores.take(10).map((score) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        // Game Icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getGameColor(
                              score.gameType.name,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getGameIcon(score.gameType.name),
                            size: 16,
                            color: _getGameColor(score.gameType.name),
                          ),
                        ),
                        const Gap(12),
                        // Game Name
                        Expanded(
                          child: Text(
                            _getGameDisplayName(score.gameType.name),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        // Score
                        Text(
                          '${score.score}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                        const Gap(8),
                        // Time
                        Text(
                          _formatTimeAgo(score.playedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<List<GameScore>> _getRecentScoresStream() {
    try {
      return Stream.fromFuture(ScoreService.getRecentActivities(limit: 20));
    } catch (e) {
      return Stream.value([]);
    }
  }

  IconData _getGameIcon(String gameType) {
    switch (gameType) {
      case 'reactionTime':
        return Icons.timer;
      case 'numberMemory':
        return Icons.numbers;
      case 'sequenceMemory':
        return Icons.format_list_numbered;
      case 'verbalMemory':
        return Icons.record_voice_over;
      case 'visualMemory':
        return Icons.visibility;
      case 'chimpTest':
        return Icons.pets;
      case 'decisionRisk':
        return Icons.speed;
      case 'aimTrainer':
        return Icons.gps_fixed;
      case 'personalityQuiz':
        return Icons.psychology;
      default:
        return Icons.games;
    }
  }

  Color _getGameColor(String gameType) {
    switch (gameType) {
      case 'reactionTime':
        return Colors.blue;
      case 'numberMemory':
        return Colors.teal;
      case 'sequenceMemory':
        return Colors.purple;
      case 'verbalMemory':
        return Colors.orange;
      case 'visualMemory':
        return Colors.green;
      case 'chimpTest':
        return Colors.brown;
      case 'decisionRisk':
        return Colors.red;
      case 'aimTrainer':
        return Colors.indigo;
      case 'personalityQuiz':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getGameDisplayName(String gameType) {
    switch (gameType) {
      case 'reactionTime':
        return 'Reaction Time';
      case 'numberMemory':
        return 'Number Memory';
      case 'sequenceMemory':
        return 'Sequence Memory';
      case 'verbalMemory':
        return 'Verbal Memory';
      case 'visualMemory':
        return 'Visual Memory';
      case 'chimpTest':
        return 'Chimp Test';
      case 'decisionRisk':
        return 'Decision Making';
      case 'aimTrainer':
        return 'Aim Trainer';
      case 'personalityQuiz':
        return 'Personality Quiz';
      default:
        return gameType;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
