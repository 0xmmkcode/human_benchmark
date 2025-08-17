import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/services/game_management_service.dart';
import 'package:human_benchmark/models/game_management.dart';
import 'package:human_benchmark/services/auth_service.dart';
// import 'package:human_benchmark/services/admin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

      var games = await GameManagementService.getAllGameManagement();
      if (games.isEmpty) {
        // Bootstrap default records if none exist yet
        await GameManagementService.initializeDefaultGames();
        games = await GameManagementService.getAllGameManagement();
      }
      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load games: $e';
          _isLoading = false;
        });
      }
    }
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
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
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
                  'Manage which games are visible and accessible to users',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const Gap(32),
                if (_games.isEmpty) _buildEmptyState() else _buildGamesGrid(),
              ],
            ),
          ),
        ),
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
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(game.status).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(game.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Column(
              children: [
                Text(
                  game.gameName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(game.status),
                    borderRadius: BorderRadius.circular(12),
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusDescription(game.status),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  if (game.reason != null) ...[
                    const Gap(8),
                    Text(
                      'Reason: ${game.reason}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (game.blockedUntil != null) ...[
                    const Gap(8),
                    Text(
                      'Until: ${game.blockedUntil!.day}/${game.blockedUntil!.month}/${game.blockedUntil!.year}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showGameDetailsDialog(game),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WebTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Manage'),
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
}
