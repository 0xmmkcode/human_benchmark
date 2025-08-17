import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/services/game_management_service.dart';
import 'package:human_benchmark/models/game_management.dart';
import 'package:human_benchmark/services/auth_service.dart';
// import 'package:human_benchmark/services/admin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:human_benchmark/services/app_logger.dart';

class AdminGameManagementPage extends StatefulWidget {
  const AdminGameManagementPage({super.key});

  @override
  State<AdminGameManagementPage> createState() =>
      _AdminGameManagementPageState();
}

class _AdminGameManagementPageState extends State<AdminGameManagementPage> {
  List<GameManagement> _games = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await GameManagementService.isUserAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }

      if (isAdmin) {
        await _loadGames();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to check admin status: $e';
        });
      }
    }
  }

  Future<void> _loadGames() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // First, try to get existing games
      var games = await GameManagementService.getAllGameManagement();
      
      // If no games exist, try to initialize them
      if (games.isEmpty) {
        try {
          // Try to initialize default games
          await GameManagementService.initializeDefaultGames();
          // Try to get games again
          games = await GameManagementService.getAllGameManagement();
        } catch (initError) {
          AppLogger.error('Failed to initialize default games', initError);
          // If initialization fails, create a basic set manually
          games = await _createBasicGames();
        }
      }
      
      // If still no games, create them manually
      if (games.isEmpty) {
        games = await _createBasicGames();
      }
      
      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
        });
      }
      
      // Log the results for debugging
      print('Loaded ${games.length} games: ${games.map((g) => '${g.gameName} (${g.status.name})').join(', ')}');
      
    } catch (e) {
      AppLogger.error('Failed to load games', e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load games: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Fallback method to create basic games if Firebase initialization fails
  Future<List<GameManagement>> _createBasicGames() async {
    final basicGames = [
      GameManagement(
        gameId: 'reaction_time',
        gameName: 'Reaction Time',
        status: GameStatus.active,
        updatedAt: DateTime.now(),
        updatedBy: 'system',
      ),
      GameManagement(
        gameId: 'number_memory',
        gameName: 'Number Memory',
        status: GameStatus.active,
        updatedAt: DateTime.now(),
        updatedBy: 'system',
      ),
      GameManagement(
        gameId: 'decision_making',
        gameName: 'Decision Making',
        status: GameStatus.active,
        updatedAt: DateTime.now(),
        updatedBy: 'system',
      ),
      GameManagement(
        gameId: 'personality_quiz',
        gameName: 'Personality Quiz',
        status: GameStatus.active,
        updatedAt: DateTime.now(),
        updatedBy: 'system',
      ),
    ];
    
    // Try to save these to Firebase
    try {
      for (final game in basicGames) {
        await GameManagementService.updateGameStatus(
          gameId: game.gameId,
          status: game.status,
          reason: null,
          blockedUntil: null,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to save basic games to Firebase', e);
    }
    
    return basicGames;
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
        await _loadGames();
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
                await _loadGames();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.grey50,
      appBar: AppBar(
        title: const Text(
          'Game Management',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadGames,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          final bool isAuthenticated = snapshot.data != null;

          if (!isAuthenticated) {
            return _buildSignInPrompt();
          }

          if (!_isAdmin) {
            return _buildNotAdminPrompt();
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return _buildErrorState();
          }

          return _buildGameManagementContent();
        },
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 80, color: WebTheme.primaryBlue),
              const Gap(24),
              Text(
                'Sign in required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              Text(
                'Please sign in to access game management.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WebTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final cred = await AuthService.signInWithGoogle();
                    if (mounted && cred != null) {
                      await _checkAdminStatus();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotAdminPrompt() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Colors.red[400],
              ),
              const Gap(24),
              Text(
                'Admin Access Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              Text(
                'You do not have admin privileges to access game management.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              Text(
                'If you are a developer, you can grant yourself admin access:',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Grant Admin Access'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WebTheme.primaryBlue,
                    side: BorderSide(color: WebTheme.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final success =
                          await GameManagementService.makeCurrentUserAdmin();
                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Admin access granted! Refreshing...',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await _checkAdminStatus();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to grant admin access'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const Gap(16),
          Text(
            'Error loading games',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const Gap(8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          ElevatedButton(onPressed: _loadGames, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildGameManagementContent() {
    return RefreshIndicator(
      onRefresh: _loadGames,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with real-time status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Game Access Control',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Manage which games are visible and accessible to users in real-time',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // Real-time status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            'Live Updates',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(32),

                // Quick stats
                _buildQuickStats(),
                const Gap(24),
                
                // Debug section for troubleshooting
                if (_games.isEmpty) _buildDebugSection(),
                if (_games.isEmpty) const Gap(24),
                
                // Quick action bar
                _buildQuickActionBar(),
                const Gap(24),

                if (_games.isEmpty) _buildEmptyState() else _buildGamesGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeGames = _games.where((g) => g.isActive).length;
    final blockedGames = _games.where((g) => g.isBlocked).length;
    final maintenanceGames = _games.where((g) => g.isMaintenance).length;
    final hiddenGames = _games.where((g) => g.isHidden).length;

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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.extension_off, size: 64, color: Colors.grey[400]),
          const Gap(12),
          Text(
            'No game records found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const Gap(8),
          Text(
            'Initialize default game controls to get started.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          ElevatedButton.icon(
            onPressed: () async {
              await GameManagementService.initializeDefaultGames();
              await _loadGames();
            },
            icon: const Icon(Icons.playlist_add),
            label: const Text('Initialize Defaults'),
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.1,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final game = _games[index];
        return _buildGameCard(game);
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
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

                  const Spacer(),

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

  Widget _buildDebugSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, size: 24, color: Colors.red[400]),
              const Gap(12),
              Text(
                'Debug Section',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const Gap(16),
          Text(
            'Current Game List (from Firebase):',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Gap(8),
          ..._games.map((game) => Text(
                '${game.gameId}: ${game.gameName} (${game.status.name})',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              )),
          const Gap(16),
                     Text(
             'Firebase Status:',
             style: TextStyle(fontSize: 14, color: Colors.grey[600]),
           ),
           const Gap(8),
          Text(
            'Is User Admin: $_isAdmin',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const Gap(8),
          Text(
            'Current User ID: ${AuthService.currentUser?.uid ?? 'N/A'}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const Gap(16),
           Row(
             children: [
               Expanded(
                 child: ElevatedButton.icon(
                   onPressed: () async {
                     print('Manual refresh triggered');
                     await _loadGames();
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: WebTheme.primaryBlue,
                     foregroundColor: Colors.white,
                   ),
                   icon: const Icon(Icons.refresh),
                   label: const Text('Manual Refresh'),
                 ),
               ),
               const Gap(16),
               Expanded(
                 child: ElevatedButton.icon(
                   onPressed: () async {
                     print('Force initialize games');
                     try {
                       await GameManagementService.initializeDefaultGames();
                       await _loadGames();
                     } catch (e) {
                       print('Force init failed: $e');
                     }
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.orange,
                     foregroundColor: Colors.white,
                   ),
                   icon: const Icon(Icons.playlist_add),
                   label: const Text('Force Init'),
                 ),
               ),
             ],
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
}
