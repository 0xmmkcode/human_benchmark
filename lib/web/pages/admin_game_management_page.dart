import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';
import 'package:human_benchmark/services/game_management_service.dart';
import 'package:human_benchmark/models/game_management.dart';
import 'package:human_benchmark/services/admin_service.dart';

class AdminGameManagementPage extends StatefulWidget {
  const AdminGameManagementPage({super.key});

  @override
  State<AdminGameManagementPage> createState() =>
      _AdminGameManagementPageState();
}

class _AdminGameManagementPageState extends State<AdminGameManagementPage> {
  bool _isAdmin = false;
  bool _isLoadingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await AdminService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
        _isLoadingAdmin = false;
      });
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isLoadingAdmin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAdmin) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red[400]),
              const Gap(16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const Gap(8),
              Text(
                'You need admin privileges to access this page',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<GameManagement>>(
        stream: GameManagementService.getAllGameManagementStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[400]),
                  const Gap(16),
                  Text(
                    'Error loading games: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final games = snapshot.data ?? [];

          if (games.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeader(
                      title: 'Game Management',
                      subtitle:
                          'Control game availability and visibility across the platform.',
                    ),
                    const Gap(32),
                    _buildQuickStats(games),
                    const Gap(24),
                    _buildGameManagementGrid(games),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(List<GameManagement> games) {
    final activeGames = games.where((g) => g.isActive).length;
    final hiddenGames = games.where((g) => g.isHidden).length;
    final blockedGames = games.where((g) => g.isBlocked).length;
    final maintenanceGames = games.where((g) => g.isMaintenance).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active Games',
            activeGames.toString(),
            Icons.check_circle,
            Colors.green,
            'Visible and playable',
          ),
        ),
        const Gap(16),
        Expanded(
          child: _buildStatCard(
            'Hidden Games',
            hiddenGames.toString(),
            Icons.visibility_off,
            Colors.orange,
            'Hidden from menu',
          ),
        ),
        const Gap(16),
        Expanded(
          child: _buildStatCard(
            'Blocked Games',
            blockedGames.toString(),
            Icons.block,
            Colors.red,
            'Completely blocked',
          ),
        ),
        const Gap(16),
        Expanded(
          child: _buildStatCard(
            'Maintenance',
            maintenanceGames.toString(),
            Icons.build,
            Colors.purple,
            'Temporarily unavailable',
          ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
          const Gap(4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGameManagementGrid(List<GameManagement> games) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        double childAspectRatio = 0.6;

        if (constraints.maxWidth < 800) {
          crossAxisCount = 2;
          childAspectRatio = 0.7;
        }
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
          childAspectRatio = 0.8;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            return _buildGameCard(games[index]);
          },
        );
      },
    );
  }

  Widget _buildGameCard(GameManagement game) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(game.status).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with game name and status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getStatusColor(game.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getGameIcon(game.gameId),
                  size: 32,
                  color: _getStatusColor(game.status),
                ),
                const Gap(12),
                Text(
                  game.gameName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(game.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    game.status.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status description
                    Text(
                      _getStatusDescription(game.status),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Gap(16),

                    // Game Access Switch
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Game Access:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Switch(
                                value: game.isAccessible,
                                onChanged: (value) {
                                  final newStatus = value
                                      ? GameStatus.active
                                      : GameStatus.blocked;
                                  _updateGameStatus(game, newStatus);
                                },
                                activeColor: WebTheme.primaryBlue,
                                activeTrackColor: WebTheme.primaryBlue
                                    .withOpacity(0.3),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: game.isAccessible
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Gap(8),
                              Text(
                                game.isAccessible
                                    ? 'Accessible to users'
                                    : 'Blocked from users',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: game.isAccessible
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(16),

                    // Status Management Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tune,
                                size: 16,
                                color: Colors.green[600],
                              ),
                              const Gap(8),
                              Text(
                                'Status Management',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),

                          // Status Options
                          Text(
                            'Available Statuses:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Gap(8),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: GameStatus.values.map((status) {
                              final isCurrentStatus = status == game.status;
                              final isAccessible =
                                  status == GameStatus.active ||
                                  status == GameStatus.hidden;

                              return InkWell(
                                onTap: () => _updateGameStatus(game, status),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrentStatus
                                        ? _getStatusColor(status)
                                        : isAccessible
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCurrentStatus
                                          ? _getStatusColor(status)
                                          : Colors.grey[300]!,
                                      width: isCurrentStatus ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentStatus
                                          ? Colors.white
                                          : isAccessible
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const Gap(16),

                    // Game Details Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.blue[600],
                              ),
                              const Gap(8),
                              Text(
                                'Game Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),

                          // Game ID
                          Row(
                            children: [
                              Text(
                                'ID: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                game.gameId,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),

                          const Gap(4),

                          // Updated At
                          Row(
                            children: [
                              Text(
                                'Updated: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${game.updatedAt.day}/${game.updatedAt.month}/${game.updatedAt.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),

                          const Gap(4),

                          // Updated By
                          Row(
                            children: [
                              Text(
                                'By: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                game.updatedBy,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Reason display
                    if (game.reason != null) ...[
                      const Gap(12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.note,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const Gap(8),
                                Text(
                                  'Reason:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              game.reason!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Blocked until display
                    if (game.blockedUntil != null) ...[
                      const Gap(12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.orange[600],
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                'Blocked until: ${game.blockedUntil!.day}/${game.blockedUntil!.month}/${game.blockedUntil!.year}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.games, size: 64, color: Colors.grey[400]),
          const Gap(16),
          Text(
            'No games found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const Gap(8),
          Text(
            'Games will appear here once they are added to the system',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await GameManagementService.initializeDefaultGames();
              } catch (e) {
                print('Failed to initialize games: $e');
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Initialize Default Games'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGameStatus(
    GameManagement game,
    GameStatus newStatus,
  ) async {
    try {
      final success = await GameManagementService.updateGameStatus(
        gameId: game.gameId,
        status: newStatus,
        reason: game.reason,
        blockedUntil: game.blockedUntil,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${game.gameName} status updated to ${newStatus.name}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update game status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  IconData _getGameIcon(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return Icons.timer;
      case 'number_memory':
        return Icons.numbers;
      case 'sequence_memory':
        return Icons.format_list_numbered;
      case 'verbal_memory':
        return Icons.record_voice_over;
      case 'visual_memory':
        return Icons.visibility;
      case 'chimp_test':
        return Icons.pets;
      case 'decision_risk':
        return Icons.speed;
      case 'aim_trainer':
        return Icons.gps_fixed;
      case 'personality_quiz':
        return Icons.psychology;
      default:
        return Icons.games;
    }
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.active:
        return Colors.green;
      case GameStatus.hidden:
        return Colors.orange;
      case GameStatus.blocked:
        return Colors.red;
      case GameStatus.maintenance:
        return Colors.blue;
    }
  }

  String _getStatusDescription(GameStatus status) {
    switch (status) {
      case GameStatus.active:
        return 'Game is visible and playable';
      case GameStatus.hidden:
        return 'Game is hidden from menu but accessible via direct URL';
      case GameStatus.blocked:
        return 'Game is completely blocked and inaccessible';
      case GameStatus.maintenance:
        return 'Game is temporarily unavailable';
    }
  }
}
