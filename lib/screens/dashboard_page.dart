import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_score.dart';
import '../models/game_score.dart';
import '../services/dashboard_service.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildStatisticsPage(isSmallScreen),
    );
  }

  Widget _buildStatisticsPage(bool isSmallScreen) {
    return StreamBuilder<DashboardOverview>(
      stream: DashboardService.getDashboardOverviewStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                    'Failed to load statistics',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final overview = snapshot.data!;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Statistics Cards
              _buildMainStatsCards(overview, isSmallScreen),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Recent Activity and Players Cards
              _buildRecentActivityCard(overview.recentActivity, isSmallScreen),
              SizedBox(height: isSmallScreen ? 12 : 16),
              _buildRecentPlayersCard(overview.topPerformers, isSmallScreen),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Game Statistics
              _buildGameStatsSection(overview.gameStatistics, isSmallScreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainStatsCards(DashboardOverview overview, bool isSmallScreen) {
    return Column(
      children: [
        // First row - 2 cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Players',
                '${overview.totalUsers}',
                Icons.people,
                Colors.blue,
                'Registered users',
                isSmallScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: _buildStatCard(
                'Games Played',
                '${overview.totalGamesPlayed}',
                Icons.games,
                Colors.green,
                'Total games completed',
                isSmallScreen,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        // Second row - 2 cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Today',
                '${overview.activeUsersToday}',
                Icons.trending_up,
                Colors.orange,
                'Players active today',
                isSmallScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: _buildStatCard(
                'Avg Score',
                '${_calculateAverageScore(overview)}',
                Icons.star,
                Colors.purple,
                'Average player score',
                isSmallScreen,
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
    bool isSmallScreen,
  ) {
    return Container(
      height: isSmallScreen ? 100 : 120,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.02)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
                child: Icon(icon, color: color, size: isSmallScreen ? 18 : 22),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: color,
                  size: isSmallScreen ? 12 : 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 1 : 2),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 9 : 11,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(
    List<RecentActivity> activities,
    bool isSmallScreen,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                ),
                child: Icon(
                  Icons.history,
                  color: Colors.blue,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Text(
                  'Recent Activity',
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
                child: Text(
                  '${activities.length}',
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          if (activities.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox,
                    size: isSmallScreen ? 32 : 40,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'No recent activity',
                    style: GoogleFonts.montserrat(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ...activities
                .take(isSmallScreen ? 3 : 4)
                .map((activity) => _buildActivityItem(activity, isSmallScreen)),
        ],
      ),
    );
  }

  Widget _buildRecentPlayersCard(
    List<PlayerDashboardData> players,
    bool isSmallScreen,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                ),
                child: Icon(
                  Icons.people,
                  color: Colors.green,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Text(
                  'Top Players',
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
                child: Text(
                  '${players.length}',
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          if (players.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: isSmallScreen ? 32 : 40,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'No players yet',
                    style: GoogleFonts.montserrat(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ...players
                .take(isSmallScreen ? 3 : 4)
                .map((player) => _buildPlayerItem(player, isSmallScreen)),
        ],
      ),
    );
  }

  Widget _buildGameStatsSection(
    Map<GameType, GameStatistics> gameStats,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Statistics',
          style: GoogleFonts.montserrat(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmallScreen ? 1 : 2,
            childAspectRatio: isSmallScreen ? 2.5 : 1.1,
            crossAxisSpacing: isSmallScreen ? 8 : 12,
            mainAxisSpacing: isSmallScreen ? 8 : 12,
          ),
          itemCount: gameStats.length,
          itemBuilder: (context, index) {
            final gameType = gameStats.keys.elementAt(index);
            final stats = gameStats[gameType]!;
            return _buildGameStatCard(gameType, stats, isSmallScreen);
          },
        ),
      ],
    );
  }

  Widget _buildGameStatCard(
    GameType gameType,
    GameStatistics stats,
    bool isSmallScreen,
  ) {
    final color = _getGameColor(gameType);
    final icon = _getGameIcon(gameType);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.02)],
        ),
      ),
      child: isSmallScreen
          ? Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isSmallScreen ? 16 : 18,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        GameScore.getDisplayName(gameType),
                        style: GoogleFonts.montserrat(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        'Top: ${stats.topScoreDisplay}',
                        style: GoogleFonts.montserrat(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${stats.playerCount}',
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          isSmallScreen ? 8 : 10,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: isSmallScreen ? 16 : 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${stats.playerCount}',
                      style: GoogleFonts.montserrat(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  GameScore.getDisplayName(gameType),
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  'Top: ${stats.topScoreDisplay}',
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }

  Widget _buildPlayerItem(PlayerDashboardData player, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 16 : 18,
            backgroundColor: Colors.green.withValues(alpha: 0.15),
            child: Text(
              player.userName?.substring(0, 1).toUpperCase() ?? 'G',
              style: GoogleFonts.montserrat(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.userName ?? 'Guest',
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${player.overallScore} pts',
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.star, color: Colors.amber, size: isSmallScreen ? 14 : 16),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity activity, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
            decoration: BoxDecoration(
              color: _getGameColor(activity.gameType).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
            ),
            child: Icon(
              _getGameIcon(activity.gameType),
              color: _getGameColor(activity.gameType),
              size: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.displayName} scored ${activity.scoreDisplay}',
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'in ${activity.gameDisplayName}',
                  style: GoogleFonts.montserrat(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (activity.isHighScore)
            Icon(
              Icons.star,
              color: Colors.amber,
              size: isSmallScreen ? 12 : 14,
            ),
          SizedBox(width: isSmallScreen ? 2 : 4),
          Text(
            activity.timeAgo,
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 9 : 10,
              color: Colors.grey[500],
            ),
            overflow: TextOverflow.ellipsis,
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
