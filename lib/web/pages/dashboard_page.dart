import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/models/game_score.dart';
import 'package:human_benchmark/services/dashboard_service.dart';
import 'package:human_benchmark/widgets/score_display.dart';
import 'package:human_benchmark/screens/comprehensive_leaderboard_page.dart';

class WebDashboardPage extends StatefulWidget {
  const WebDashboardPage({super.key});

  @override
  State<WebDashboardPage> createState() => _WebDashboardPageState();
}

class _WebDashboardPageState extends State<WebDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'overallScore';
  bool _sortDescending = true;
  String _searchQuery = '';

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
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
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade600,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Players'),
            Tab(text: 'Games'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPlayersTab(),
          _buildGamesTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<DashboardOverview>(
      future: DashboardService.getDashboardOverview(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                const Gap(16),
                const Text(
                  'Failed to load dashboard',
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Players',
                      '${overview.totalUsers}',
                      Icons.people,
                      Colors.blue.shade600,
                    ),
                  ),
                  const Gap(24),
                  Expanded(
                    child: _buildStatCard(
                      'Games Played',
                      '${overview.totalGamesPlayed}',
                      Icons.games,
                      Colors.green.shade600,
                    ),
                  ),
                ],
              ),
              const Gap(40),

              // Top Performers
              Text(
                'Top Performers',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Gap(24),
              ...overview.topPerformers.take(5).map((player) => _buildPlayerCard(player)),
              const Gap(40),

              // Recent Activity
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Gap(24),
              ...overview.recentActivity.take(5).map((activity) => _buildActivityCard(activity)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayersTab() {
    return Column(
      children: [
        // Search and Sort Controls
        Container(
          padding: const EdgeInsets.all(32),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search players...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const Gap(24),
              
              // Sort Controls
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: InputDecoration(
                        labelText: 'Sort by',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'overallScore', child: Text('Overall Score')),
                        DropdownMenuItem(value: 'totalGames', child: Text('Total Games')),
                        DropdownMenuItem(value: 'lastPlayed', child: Text('Last Played')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value ?? 'overallScore';
                        });
                      },
                    ),
                  ),
                  const Gap(16),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _sortDescending = !_sortDescending;
                      });
                    },
                    icon: Icon(
                      _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.blue.shade600,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Players List
        Expanded(
          child: StreamBuilder<List<PlayerDashboardData>>(
            stream: _searchQuery.isNotEmpty
                ? DashboardService.searchPlayers(_searchQuery)
                : DashboardService.getAllPlayers(
                    sortBy: _sortBy,
                    descending: _sortDescending,
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
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      const Gap(16),
                      const Text(
                        'Failed to load players',
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

              if (players.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                      const Gap(16),
                      Text(
                        _searchQuery.isNotEmpty ? 'No players found' : 'No players yet',
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

              return ListView.builder(
                padding: const EdgeInsets.all(32),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return _buildPlayerCard(player, showRank: true);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGamesTab() {
    return FutureBuilder<DashboardOverview>(
      future: DashboardService.getDashboardOverview(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final overview = snapshot.data ?? DashboardOverview.empty();
        final gameStats = overview.gameStatistics;

        if (gameStats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.games_outlined, size: 64, color: Colors.grey.shade400),
                const Gap(16),
                const Text(
                  'No game statistics yet',
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

        return ListView.builder(
          padding: const EdgeInsets.all(32),
          itemCount: gameStats.length,
          itemBuilder: (context, index) {
            final gameType = gameStats.keys.elementAt(index);
            final stats = gameStats[gameType]!;
            return _buildGameStatsCard(stats);
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const Gap(20),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerDashboardData player, {bool showRank = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: showRank
            ? Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getRankColor(player.rank),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    '${player.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              )
            : CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person, size: 30, color: Colors.blue.shade600),
              ),
        title: Text(
          player.displayName,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '${player.totalGamesPlayed} games • Last played: ${_formatDate(player.lastPlayedAt)}',
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
              '${player.overallScore}',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.blue.shade600,
              ),
            ),
            Text(
              'Overall',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        onTap: () => _showPlayerDetails(player),
      ),
    );
  }

  Widget _buildActivityCard(RecentActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activity.isHighScore ? Colors.amber.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getGameIcon(activity.gameType),
            color: _getGameColor(activity.gameType),
            size: 24,
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.displayName} scored ${GameScore.getScoreDisplay(activity.gameType, activity.score)}',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'in ${GameScore.getDisplayName(activity.gameType)}',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (activity.isHighScore)
            Icon(Icons.star, color: Colors.amber.shade600, size: 20),
          const Gap(12),
          Text(
            _formatDate(activity.playedAt),
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

  Widget _buildGameStatsCard(GameStatistics stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getGameIcon(stats.gameType),
                color: _getGameColor(stats.gameType),
                size: 32,
              ),
              const Gap(16),
              Text(
                stats.gameName,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: _buildGameStatItem('Top Score', stats.topScoreDisplay),
              ),
              Expanded(
                child: _buildGameStatItem('Average', stats.averageScoreDisplay),
              ),
              Expanded(
                child: _buildGameStatItem('Players', '${stats.playerCount}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showPlayerDetails(PlayerDashboardData player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebPlayerDetailPage(playerId: player.userId),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Web Player Detail Page
class WebPlayerDetailPage extends StatelessWidget {
  final String playerId;

  const WebPlayerDetailPage({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Player Details',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<PlayerDetailData?>(
        future: DashboardService.getPlayerDetails(playerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                  const Gap(16),
                  const Text(
                    'Failed to load player details',
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

          final playerData = snapshot.data!;
          final userScore = playerData.userScore;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player Profile Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.person, size: 50, color: Colors.blue.shade600),
                      ),
                      const Gap(24),
                      Text(
                        userScore.userName ?? 'Player ${userScore.userId.substring(0, 6)}',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const Gap(12),
                      Text(
                        'Member since ${_formatDate(userScore.createdAt)}',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(32),

                // Score Display
                ScoreDisplay(
                  userScore: userScore,
                  onViewLeaderboard: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ComprehensiveLeaderboardPage(),
                      ),
                    );
                  },
                ),
                const Gap(32),

                // Recent Scores
                Text(
                  'Recent Scores',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Gap(24),
                ...playerData.recentScores.take(10).map((score) => _buildRecentScoreCard(score)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentScoreCard(GameScore score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: score.isHighScore ? Colors.amber.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getGameIcon(score.gameType),
            color: _getGameColor(score.gameType),
            size: 24,
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GameScore.getDisplayName(score.gameType),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  GameScore.getScoreDisplay(score.gameType, score.score),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (score.isHighScore)
            Icon(Icons.star, color: Colors.amber.shade600, size: 20),
          const Gap(12),
          Text(
            _formatDate(score.playedAt),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
