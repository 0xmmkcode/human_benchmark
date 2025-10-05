import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/services/dashboard_service.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/utils/web_utils.dart';
import 'package:human_benchmark/web/widgets/app_loading.dart';

class GlobalDashboardPage extends StatefulWidget {
  const GlobalDashboardPage({super.key});

  @override
  State<GlobalDashboardPage> createState() => _GlobalDashboardPageState();
}

class _GlobalDashboardPageState extends State<GlobalDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.grey50,
      appBar: AppBar(
        title: const Text(
          'Global Dashboard',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: WebTheme.primaryBlue,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: WebTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Top Players'),
            Tab(text: 'Game Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTopPlayersTab(),
          _buildGameStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<DashboardOverview>(
      future: DashboardService.getDashboardOverview(),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      WebTheme.primaryBlue.withOpacity(0.1),
                      WebTheme.primaryBlueLight.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.public, size: 48, color: WebTheme.primaryBlue),
                    const Gap(16),
                    Text(
                      'Welcome to the Global Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: WebTheme.primaryBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(8),
                    Text(
                      'Discover how players worldwide are performing in cognitive tests',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Gap(32),

              // Key Statistics
              Text(
                'Key Statistics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Gap(16),

              // Statistics Grid
              Row(
                children: [
                  Expanded(
                    child: WebUtils.buildStatCard(
                      title: 'Total Players',
                      value: '${overview.totalUsers}',
                      icon: Icons.people,
                      color: WebTheme.primaryBlue,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: WebUtils.buildStatCard(
                      title: 'Games Played',
                      value: '${overview.totalGamesPlayed}',
                      icon: Icons.games,
                      color: Colors.green[600]!,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: WebUtils.buildStatCard(
                      title: 'Active Today',
                      value: '${overview.recentActivity.length}',
                      icon: Icons.trending_up,
                      color: Colors.orange[600]!,
                    ),
                  ),
                ],
              ),
              const Gap(32),

              // Recent Activity
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Gap(16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    if (overview.recentActivity.isEmpty)
                      const Text(
                        'No recent activity to display',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ...overview.recentActivity
                          .take(5)
                          .map(
                            (activity) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: WebTheme.primaryBlue,
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Text(
                                      '${activity.displayName} scored ${activity.score} in ${activity.gameType.name}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopPlayersTab() {
    return StreamBuilder<List<PlayerDashboardData>>(
      stream: DashboardService.getAllPlayers(limit: 20),
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
                  'Failed to load top players',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final players = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Players Worldwide',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Gap(16),

              if (players.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No players found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...players.asMap().entries.map((entry) {
                  final index = entry.key;
                  final player = entry.value;
                  final isTop3 = index < 3;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTop3
                            ? WebTheme.primaryBlue.withOpacity(0.3)
                            : Colors.grey[200]!,
                        width: isTop3 ? 2 : 1,
                      ),
                      boxShadow: isTop3
                          ? [
                              BoxShadow(
                                color: WebTheme.primaryBlue.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Rank
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isTop3
                                ? WebTheme.primaryBlue
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isTop3 ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const Gap(16),

                        // Player Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.userName ?? 'Anonymous Player',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const Gap(4),
                              Text(
                                'Overall Score: ${player.overallScore}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stats
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${player.totalGamesPlayed} games',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Gap(4),
                            Text(
                              WebUtils.formatDate(player.lastPlayedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameStatisticsTab() {
    return FutureBuilder<DashboardOverview>(
      future: DashboardService.getDashboardOverview(),
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
                  'Failed to load game statistics',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final overview = snapshot.data ?? DashboardOverview.empty();
        final gameStats = overview.gameStatistics;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Game Performance Statistics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Gap(16),

              // Game Stats Grid
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  if (gameStats.containsKey(GameType.reactionTime))
                    _buildGameStatCard(
                      'Reaction Time',
                      gameStats[GameType.reactionTime]!,
                      Icons.timer,
                      WebTheme.primaryBlue,
                    ),
                  if (gameStats.containsKey(GameType.personalityQuiz))
                    _buildGameStatCard(
                      'Personality Quiz',
                      gameStats[GameType.personalityQuiz]!,
                      Icons.psychology,
                      Colors.purple[600]!,
                    ),
                  if (gameStats.containsKey(GameType.decisionRisk))
                    _buildGameStatCard(
                      'Decision Making',
                      gameStats[GameType.decisionRisk]!,
                      Icons.speed,
                      Colors.orange[600]!,
                    ),
                  if (gameStats.containsKey(GameType.numberMemory))
                    _buildGameStatCard(
                      'Number Memory',
                      gameStats[GameType.numberMemory]!,
                      Icons.memory,
                      Colors.teal[600]!,
                    ),
                ],
              ),

              const Gap(32),

              // Additional Insights
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPlatformStat(
                            'Web Players',
                            '${(overview.totalUsers * 0.6).round()}',
                            Icons.computer,
                            WebTheme.primaryBlue,
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: _buildPlatformStat(
                            'Mobile Players',
                            '${(overview.totalUsers * 0.4).round()}',
                            Icons.phone_android,
                            Colors.green[600]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameStatCard(
    String gameName,
    GameStatistics gameStats,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Gap(12),
              Text(
                gameName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const Gap(16),
          _buildStatRow('Games Played', '${gameStats.playerCount}'),
          _buildStatRow('Average Score', '${gameStats.averageScore}'),
          _buildStatRow('Best Score', '${gameStats.topScore}'),
          _buildStatRow('Active Players', '${gameStats.playerCount}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformStat(
    String label,
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
          Icon(icon, color: color, size: 32),
          const Gap(8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(4),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
