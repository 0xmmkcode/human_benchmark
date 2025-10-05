import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/models/game_score.dart';
import 'package:human_benchmark/services/dashboard_service.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';
import 'package:human_benchmark/web/widgets/app_loading.dart';

class WebDashboardPage extends StatefulWidget {
  const WebDashboardPage({super.key});

  @override
  State<WebDashboardPage> createState() => _WebDashboardPageState();
}

class _WebDashboardPageState extends State<WebDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.grey50,
      body: Column(
        children: [
          // Page Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: PageHeader(
              title: 'Statistics',
              subtitle: 'Monitor game statistics and player activity.',
            ),
          ),
          Expanded(child: _buildStatisticsPage()),
        ],
      ),
    );
  }

  Widget _buildStatisticsPage() {
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
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const Gap(16),
                Text(
                  'Failed to load statistics',
                  style: WebTheme.headingMedium.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const Gap(8),
                Text(
                  'Please try again later',
                  style: WebTheme.bodyMedium.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final overview = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Statistics Cards
              _buildMainStatsCards(overview),
              const Gap(32),

              // Recent Activity and Players Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Activity
                  Expanded(
                    child: _buildRecentActivityCard(overview.recentActivity),
                  ),
                  const Gap(24),
                  // Recent Players
                  Expanded(
                    child: _buildRecentPlayersCard(overview.topPerformers),
                  ),
                ],
              ),
              const Gap(32),

              // Game Statistics
              _buildGameStatsSection(overview.gameStatistics),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainStatsCards(DashboardOverview overview) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Players',
                '${overview.totalUsers}',
                Icons.people,
                Colors.blue,
                'Registered users',
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildStatCard(
                'Games Played',
                '${overview.totalGamesPlayed}',
                Icons.games,
                Colors.green,
                'Total games completed',
              ),
            ),
          ],
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Today',
                '${overview.activeUsersToday}',
                Icons.trending_up,
                Colors.orange,
                'Players active today',
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildStatCard(
                'Avg Score',
                '${_calculateAverageScore(overview)}',
                Icons.star,
                Colors.purple,
                'Average player score',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: color.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
          const Gap(16),
          Text(
            value,
            style: WebTheme.headingLarge.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(8),
          Text(
            title,
            style: WebTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const Gap(4),
          Text(
            subtitle,
            style: WebTheme.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(List<RecentActivity> activities) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: WebTheme.primaryBlue, size: 24),
              const Gap(12),
              Text(
                'Recent Activity',
                style: WebTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WebTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${activities.length}',
                  style: WebTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: WebTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          if (activities.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                  const Gap(12),
                  Text(
                    'No recent activity',
                    style: WebTheme.bodyLarge.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ...activities
                .take(5)
                .map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildRecentPlayersCard(List<PlayerDashboardData> players) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.green, size: 24),
              const Gap(12),
              Text(
                'Top Players',
                style: WebTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${players.length}',
                  style: WebTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          if (players.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                  const Gap(12),
                  Text(
                    'No players yet',
                    style: WebTheme.bodyLarge.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ...players.take(5).map((player) => _buildPlayerItem(player)),
        ],
      ),
    );
  }

  Widget _buildGameStatsSection(Map<GameType, GameStatistics> gameStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Statistics',
          style: WebTheme.headingMedium.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const Gap(16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: gameStats.length,
          itemBuilder: (context, index) {
            final gameType = gameStats.keys.elementAt(index);
            final stats = gameStats[gameType]!;
            return _buildGameStatCard(gameType, stats);
          },
        ),
      ],
    );
  }

  Widget _buildGameStatCard(GameType gameType, GameStatistics stats) {
    final color = _getGameColor(gameType);
    final icon = _getGameIcon(gameType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                '${stats.playerCount}',
                style: WebTheme.headingMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            GameScore.getDisplayName(gameType),
            style: WebTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const Gap(4),
          Text(
            'Top: ${stats.topScoreDisplay}',
            style: WebTheme.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerItem(PlayerDashboardData player) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            child: Text(
              player.userName?.substring(0, 1).toUpperCase() ?? 'G',
              style: WebTheme.bodyLarge.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.userName ?? 'Guest',
                  style: WebTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '${player.overallScore} pts',
                  style: WebTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.star, color: Colors.amber, size: 18),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            _getGameIcon(activity.gameType),
            color: _getGameColor(activity.gameType),
            size: 20,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.displayName} scored ${activity.scoreDisplay}',
                  style: WebTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'in ${activity.gameDisplayName}',
                  style: WebTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (activity.isHighScore)
            Icon(Icons.star, color: Colors.amber, size: 16),
          const Gap(8),
          Text(
            activity.timeAgo,
            style: WebTheme.bodySmall.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  int _calculateAverageScore(DashboardOverview overview) {
    if (overview.topPerformers.isEmpty) return 0;
    final total = overview.topPerformers.fold(
      0,
      (sum, player) => sum + player.overallScore,
    );
    return (total / overview.topPerformers.length).round();
  }

  Color _getGameColor(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return Colors.blue;
      case GameType.decisionRisk:
        return Colors.purple;
      case GameType.personalityQuiz:
        return Colors.pink;
      case GameType.numberMemory:
        return Colors.green;
      case GameType.verbalMemory:
        return Colors.orange;
      case GameType.visualMemory:
        return Colors.teal;
      case GameType.aimTrainer:
        return Colors.red;
      case GameType.sequenceMemory:
        return Colors.indigo;
      case GameType.chimpTest:
        return Colors.amber;
    }
  }

  IconData _getGameIcon(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return Icons.speed;
      case GameType.decisionRisk:
        return Icons.psychology;
      case GameType.personalityQuiz:
        return Icons.quiz;
      case GameType.numberMemory:
        return Icons.numbers;
      case GameType.verbalMemory:
        return Icons.text_fields;
      case GameType.visualMemory:
        return Icons.visibility;
      case GameType.aimTrainer:
        return Icons.gps_fixed;
      case GameType.sequenceMemory:
        return Icons.view_list;
      case GameType.chimpTest:
        return Icons.pets;
    }
  }
}
