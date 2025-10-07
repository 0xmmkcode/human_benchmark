import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:human_benchmark/services/dashboard_service.dart';
import 'package:human_benchmark/services/admin_service.dart';
import 'package:human_benchmark/services/data_export_service.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/web/widgets/app_loading.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  bool _isLoading = true;
  bool _isAdmin = false;
  Map<GameType, GameStatistics> _stats = const {};
  DashboardOverview? _overview;
  List<PlayerDashboardData> _topPerformers = [];
  List<RecentActivity> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isAdmin = await AdminService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });

      if (isAdmin) {
        await _loadData();
      }
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        DashboardService.getComprehensiveGameStatistics(),
        DashboardService.getDashboardOverview(),
      ]);

      if (!mounted) return;

      setState(() {
        _stats = results[0] as Map<GameType, GameStatistics>;
        _overview = results[1] as DashboardOverview;
        _topPerformers = _overview?.topPerformers ?? [];
        _recentActivity = _overview?.recentActivity ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Admin Analytics',
                subtitle: 'Comprehensive game and user statistics',
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.block, size: 80, color: Colors.red[400]),
                    const SizedBox(height: 24),
                    const Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin privileges required to view analytics.',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: const PageHeader(
                title: 'Admin Analytics',
                subtitle: 'Comprehensive game and user statistics',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _isLoading ? null : _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _exportData,
                        icon: const Icon(Icons.download),
                        label: const Text('Export Data'),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Admin Access',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _isLoading
                  ? const Center(child: AppLoading())
                  : _buildAdminContent(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      await DataExportService.exportUserDataAsJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Widget _buildAdminContent() {
    if (_stats.isEmpty && _overview == null) {
      return _buildEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Statistics
        _buildOverviewStats(),
        const SizedBox(height: 24),

        // User Analytics
        _buildUserAnalytics(),
        const SizedBox(height: 24),

        // Activity Analytics
        _buildActivityAnalytics(),
        const SizedBox(height: 24),

        // Game Statistics
        _buildGameStatistics(),
      ],
    );
  }

  Widget _buildOverviewStats() {
    if (_overview == null) return const SizedBox.shrink();

    return Card(
      color: Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Platform Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Users',
                    _overview!.totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Games Played',
                    _overview!.totalGamesPlayed.toString(),
                    Icons.games,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active Today',
                    _overview!.activeUsersToday.toString(),
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active Games',
                    _stats.length.toString(),
                    Icons.sports_esports,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAnalytics() {
    return Card(
      color: Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt, color: Colors.indigo[600]),
                const SizedBox(width: 8),
                const Text(
                  'User Analytics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTopPerformersChart()),
                const SizedBox(width: 20),
                Expanded(child: _buildUserActivityChart()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityAnalytics() {
    return Card(
      color: Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.teal[600]),
                const SizedBox(width: 8),
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_recentActivity.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No recent activity'),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _recentActivity.length,
                  itemBuilder: (context, index) {
                    final activity = _recentActivity[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(
                          _getGameIcon(activity.gameType),
                          color: Colors.blue[700],
                        ),
                      ),
                      title: Text(activity.displayName),
                      subtitle: Text(
                        '${activity.gameDisplayName} - ${activity.scoreDisplay}',
                      ),
                      trailing: Text(activity.timeAgo),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStatistics() {
    // Show all game types, even those without data
    final allGameTypes = GameType.values;
    final cards = allGameTypes
        .map(
          (gameType) =>
              _GameStatsCard(gameType: gameType, stats: _stats[gameType]),
        )
        .toList();

    return Card(
      color: Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.deepOrange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Game Statistics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1100;
                final crossAxisCount = isWide ? 3 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.6 : 1.3,
                  children: cards,
                );
              },
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersChart() {
    if (_topPerformers.isEmpty) {
      return const Center(child: Text('No top performers data'));
    }

    final top5 = _topPerformers.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performers',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _topPerformers.isNotEmpty
                  ? _topPerformers.first.overallScore.toDouble()
                  : 100,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < top5.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            top5[index].displayName,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: top5.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: player.overallScore.toDouble(),
                      color: Colors.blue[600],
                      width: 20,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserActivityChart() {
    // Simple pie chart showing game distribution
    final gameCounts = <String, int>{};
    for (final activity in _recentActivity) {
      final gameName = activity.gameDisplayName;
      gameCounts[gameName] = (gameCounts[gameName] ?? 0) + 1;
    }

    if (gameCounts.isEmpty) {
      return const Center(child: Text('No activity data'));
    }

    final entries = gameCounts.entries.toList();
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Distribution',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: entries.asMap().entries.map((entry) {
                final index = entry.key;
                final gameEntry = entry.value;
                final percentage =
                    (gameEntry.value / _recentActivity.length * 100).round();
                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: gameEntry.value.toDouble(),
                  title: '$percentage%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          children: entries.asMap().entries.map((entry) {
            final index = entry.key;
            final gameEntry = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: colors[index % colors.length],
                  ),
                  const SizedBox(width: 4),
                  Text(gameEntry.key, style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getGameIcon(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return Icons.timer;
      case GameType.numberMemory:
        return Icons.memory;
      case GameType.decisionRisk:
        return Icons.speed;
      case GameType.personalityQuiz:
        return Icons.psychology;
      case GameType.aimTrainer:
        return Icons.gps_fixed;
      case GameType.verbalMemory:
        return Icons.record_voice_over;
      case GameType.visualMemory:
        return Icons.visibility;
      case GameType.sequenceMemory:
        return Icons.format_list_numbered;
      case GameType.chimpTest:
        return Icons.pets;
    }
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.insights, color: Colors.grey[500], size: 40),
          const SizedBox(height: 12),
          Text(
            'No analytics data available yet',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _GameStatsCard extends StatelessWidget {
  final GameType gameType;
  final GameStatistics? stats;

  const _GameStatsCard({required this.gameType, this.stats});

  @override
  Widget build(BuildContext context) {
    final gameName = _getGameDisplayName(gameType);
    final hasData = stats != null;

    return Card(
      color: Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gameName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasData ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasData ? Colors.blue[200]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    hasData ? 'Players: ${stats!.playerCount}' : 'No Data',
                    style: TextStyle(
                      color: hasData ? Colors.blue[700] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasData) ...[
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Top',
                      value: stats!.topScoreDisplay,
                      color: Colors.green,
                      icon: Icons.emoji_events,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Avg',
                      value: stats!.averageScoreDisplay,
                      color: Colors.indigo,
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _buildTrendSpots(stats!),
                        isCurved: true,
                        color: Colors.blue[600],
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue[100],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No data available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This game hasn\'t been played yet',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getGameDisplayName(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return 'Reaction Time';
      case GameType.numberMemory:
        return 'Number Memory';
      case GameType.decisionRisk:
        return 'Decision Risk';
      case GameType.personalityQuiz:
        return 'Personality Quiz';
      case GameType.aimTrainer:
        return 'Aim Trainer';
      case GameType.verbalMemory:
        return 'Verbal Memory';
      case GameType.visualMemory:
        return 'Visual Memory';
      case GameType.sequenceMemory:
        return 'Sequence Memory';
      case GameType.chimpTest:
        return 'Chimp Test';
    }
  }

  List<FlSpot> _buildTrendSpots(GameStatistics stats) {
    // Build a tiny synthetic trend using average and top for visual insight.
    final List<int> base = [
      (stats.averageScore * 0.9).round(),
      stats.averageScore,
      ((stats.averageScore + stats.topScore) / 2).round(),
      stats.topScore,
    ];
    return List<FlSpot>.generate(
      base.length,
      (i) => FlSpot(i.toDouble(), base[i].toDouble()),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color.withOpacity(0.9), fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
