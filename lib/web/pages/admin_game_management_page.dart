import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../services/admin_service.dart';
import '../../services/game_management_service.dart';
import '../../models/game_management.dart';
import '../theme/web_theme.dart';
import '../utils/web_utils.dart';

class AdminGameManagementPage extends ConsumerStatefulWidget {
  const AdminGameManagementPage({super.key});

  @override
  ConsumerState<AdminGameManagementPage> createState() =>
      _AdminGameManagementPageState();
}

class _AdminGameManagementPageState
    extends ConsumerState<AdminGameManagementPage> {
  bool _isLoading = true;
  bool _isAdmin = false;
  List<GameManagement> _games = [];
  Map<String, bool> _pendingChanges = {};
  bool _hasUnsavedChanges = false;

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
      });

      if (isAdmin) {
        await _loadGames();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
    }
  }

  Future<void> _loadGames() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final games = await GameManagementService.getAllGameSettings();
      setState(() {
        _games = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load games: $e');
    }
  }

  void _toggleGameStatus(String gameId, bool newStatus) {
    setState(() {
      _pendingChanges[gameId] = newStatus;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (_pendingChanges.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final success = await GameManagementService.bulkUpdateGameStatuses(
        _pendingChanges,
      );

      if (success) {
        await _loadGames(); // Reload to get updated data
        setState(() {
          _pendingChanges.clear();
          _hasUnsavedChanges = false;
        });
        _showSuccessSnackBar('Game settings updated successfully');
      } else {
        _showErrorSnackBar('Failed to update game settings');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating games: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will reset all games to their default enabled state. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        final success = await GameManagementService.resetToDefaults();

        if (success) {
          await _loadGames();
          _showSuccessSnackBar('Games reset to defaults successfully');
        } else {
          _showErrorSnackBar('Failed to reset games');
        }
      } catch (e) {
        _showErrorSnackBar('Error resetting games: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: WebTheme.grey50,
        appBar: AppBar(
          title: const Text('Game Management'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              Gap(16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Gap(8),
              Text(
                'You need administrator privileges to access this page.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

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
          if (_hasUnsavedChanges)
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: WebTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          const Gap(8),
          ElevatedButton.icon(
            onPressed: _resetToDefaults,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('Reset to Defaults'),
          ),
          const Gap(16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                        Row(
                          children: [
                            Icon(
                              Icons.games,
                              size: 32,
                              color: WebTheme.primaryBlue,
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Game Management',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    'Enable or disable games to control their visibility on the website. Disabled games will be completely hidden from navigation and inaccessible to users.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Gap(16),
                        Row(
                          children: [
                            _buildStatCard(
                              'Total Games',
                              '${_games.length}',
                              Icons.games,
                              WebTheme.primaryBlue,
                            ),
                            const Gap(16),
                            _buildStatCard(
                              'Enabled',
                              '${_games.where((g) => g.isEnabled).length}',
                              Icons.check_circle,
                              Colors.green[600]!,
                            ),
                            const Gap(16),
                            _buildStatCard(
                              'Disabled',
                              '${_games.where((g) => !g.isEnabled).length}',
                              Icons.cancel,
                              Colors.red[600]!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  Text(
                    'Game Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Gap(16),
                  // Expanded settings/content area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Games Grid
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: _games
                                .map((game) => _buildGameCard(game))
                                .toList(),
                          ),
                          const Gap(32),
                          // Instructions
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
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
                                    Icon(Icons.info, color: Colors.blue[600]),
                                    const Gap(8),
                                    Text(
                                      'How it works',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(12),
                                Text(
                                  '• Disabled games will be completely hidden from navigation\n'
                                  '• Users cannot access disabled games - they will be blocked\n'
                                  '• Changes take effect immediately after saving\n'
                                  '• You can reset all games to their default enabled state using the "Reset to Defaults" button',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const Gap(8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Gap(4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(GameManagement game) {
    final isPendingChange = _pendingChanges.containsKey(game.gameId);
    final currentStatus = isPendingChange
        ? _pendingChanges[game.gameId]!
        : game.isEnabled;
    final hasChanged = isPendingChange && currentStatus != game.isEnabled;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasChanged ? WebTheme.primaryBlue : Colors.grey[200]!,
          width: hasChanged ? 2 : 1,
        ),
        boxShadow: hasChanged
            ? [
                BoxShadow(
                  color: WebTheme.primaryBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasChanged
                  ? WebTheme.primaryBlue.withOpacity(0.1)
                  : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  WebUtils.getIconFromString(game.icon),
                  color: currentStatus
                      ? WebTheme.primaryBlue
                      : Colors.grey[400],
                  size: 24,
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.gameName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: currentStatus
                              ? Colors.grey[800]
                              : Colors.grey[500],
                        ),
                      ),
                      Text(
                        game.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasChanged)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: WebTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Modified',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Switch(
                      value: currentStatus,
                      onChanged: (value) =>
                          _toggleGameStatus(game.gameId, value),
                      activeColor: WebTheme.primaryBlue,
                    ),
                  ],
                ),

                // Status Text
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: currentStatus ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentStatus ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      color: currentStatus
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Gap(12),

                // Game Info
                _buildInfoRow('ID', game.gameId),
                _buildInfoRow('Type', game.gameType),
                if (game.updatedAt != null)
                  _buildInfoRow(
                    'Last Updated',
                    WebUtils.formatDate(game.updatedAt!),
                  ),
                if (game.updatedBy != null)
                  _buildInfoRow('Updated By', game.updatedBy!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
