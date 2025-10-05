import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/services/dashboard_service.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/utils/web_utils.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';

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
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Page Header
            PageHeader(
              title: 'Global Dashboard',
              subtitle: 'View global statistics and trends.',
            ),
            const Gap(24),
            Expanded(
              child: StreamBuilder<DashboardOverview>(
                stream: DashboardService.getDashboardOverviewStream(),
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
                            color: Colors.grey[400],
                          ),
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
                                value: '${overview.activeUsersToday}',
                                icon: Icons.trending_up,
                                color: Colors.orange[600]!,
                              ),
                            ),
                          ],
                        ),
                        const Gap(32),
                        // Recent Players and Activity Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recent Players
                            Expanded(
                              child: _buildRecentPlayersCard(
                                overview.topPerformers,
                              ),
                            ),
                            const Gap(24),
                            // Recent Activity (moved to right side)
                            Expanded(
                              child: _buildRecentActivityCard(
                                overview.recentActivity,
                              ),
                            ),
                          ],
                        ),
                        // Game-Specific Recent Activity
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPlayersCard(List<PlayerDashboardData> players) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
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
                'Recent Players',
                style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 12,
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
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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

  Widget _buildRecentActivityCard(List<RecentActivity> activities) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
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
                style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 12,
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
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '${player.overallScore} pts',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
          Icon(Icons.circle, size: 8, color: WebTheme.primaryBlue),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.displayName} scored ${activity.score}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'in ${activity.gameType.name}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (activity.isHighScore)
            Icon(Icons.star, color: Colors.amber, size: 16),
          const Gap(8),
          Text(
            activity.timeAgo,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
