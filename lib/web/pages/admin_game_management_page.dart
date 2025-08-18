import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/services/game_management_service.dart';
import 'package:human_benchmark/models/game_management.dart';
import 'package:human_benchmark/services/auth_service.dart';
// import 'package:human_benchmark/services/admin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:human_benchmark/services/app_logger.dart';
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

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Management',
          style: TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Control game availability and visibility across the platform.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGameCardsGrid(List<GameManagement> games) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid based on screen width
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
                // Game icon based on type
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

                          // Current Status
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Status:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const Gap(4),
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(game.status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const Gap(8),
                                    Text(
                                      game.status.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(game.status),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

                          const Gap(8),

                          // Status Legend
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                'Accessible',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Gap(16),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                'Blocked',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
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
                      const Gap(12),
                    ],

                    // Blocked until display
                    if (game.blockedUntil != null) ...[
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
                      const Gap(12),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showGameDetailsDialog(game),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WebTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.settings, size: 18),
                            label: const Text('Advanced Settings'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionButton(
            'Add New Game',
            Icons.add_circle_outline,
            Colors.green,
            () async {
              // TODO: Implement add new game functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add new game functionality coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          _buildQuickActionButton(
            'Bulk Update',
            Icons.download_done,
            Colors.blue,
            () async {
              // TODO: Implement bulk update functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bulk update functionality coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          _buildQuickActionButton(
            'Export Data',
            Icons.download,
            Colors.purple,
            () async {
              // TODO: Implement export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export functionality coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(icon, size: 24),
          label: Text(label),
        ),
      ),
    );
  }

  // Debug section removed - no longer needed with StreamBuilder

  Widget _buildQuickStats() {
    return StreamBuilder<List<GameManagement>>(
      stream: GameManagementService.getAllGameManagementStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final games = snapshot.data!;
        final activeGames = games.where((g) => g.isActive).length;
        final blockedGames = games.where((g) => g.isBlocked).length;
        final hiddenGames = games.where((g) => g.isHidden).length;
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
      },
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

  IconData _getGameIcon(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return Icons.timer;
      case 'number_memory':
        return Icons.numbers;
      case 'decision_making':
        return Icons.psychology;
      case 'personality_quiz':
        return Icons.quiz;
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

  Future<void> _showGameDetailsDialog(GameManagement game) async {
    final TextEditingController reasonController = TextEditingController(
      text: game.reason ?? '',
    );
    DateTime? blockedUntil = game.blockedUntil;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Manage ${game.gameName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Status: ${game.status.name.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(game.status),
                  ),
                ),
                const Gap(16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    hintText: 'Enter reason for status change',
                  ),
                  maxLines: 3,
                ),
                const Gap(16),
                if (game.status == GameStatus.maintenance) ...[
                  ListTile(
                    title: const Text('Blocked Until'),
                    subtitle: Text(
                      blockedUntil != null
                          ? '${blockedUntil!.day}/${blockedUntil!.month}/${blockedUntil!.year}'
                          : 'No end date set',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate:
                            blockedUntil ??
                            DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          blockedUntil = picked;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await GameManagementService.updateGameStatus(
                  gameId: game.gameId,
                  status: game.status,
                  reason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : null,
                  blockedUntil: blockedUntil,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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

          // If no games, show debug section and try to create them
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
                    // Page header
                    _buildPageHeader(),
                    const Gap(32),

                    // Quick stats
                    _buildQuickStats(),
                    const Gap(24),

                    // Quick action bar
                    _buildQuickActionBar(),
                    const Gap(32),

                    // Game cards grid
                    _buildGameCardsGrid(games),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
