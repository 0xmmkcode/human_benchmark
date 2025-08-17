import 'package:flutter/material.dart';
import 'package:human_benchmark/services/game_management_service.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:gap/gap.dart';

class GameAccessGuard extends StatefulWidget {
  final String gameId;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? blockedWidget;

  const GameAccessGuard({
    super.key,
    required this.gameId,
    required this.child,
    this.loadingWidget,
    this.blockedWidget,
  });

  @override
  State<GameAccessGuard> createState() => _GameAccessGuardState();
}

class _GameAccessGuardState extends State<GameAccessGuard> {
  bool _isLoading = true;
  bool _isAccessible = true;
  String? _status;
  String? _reason;
  DateTime? _blockedUntil;

  @override
  void initState() {
    super.initState();
    _checkGameAccess();
  }

  Future<void> _checkGameAccess() async {
    try {
      final statusInfo = await GameManagementService.getGameStatusInfo(
        widget.gameId,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (statusInfo != null) {
            _isAccessible = statusInfo['isAccessible'] ?? true;
            _status = statusInfo['status'];
            _reason = statusInfo['reason'];
            _blockedUntil = statusInfo['blockedUntil'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAccessible = false; // Default to blocked on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (!_isAccessible) {
      return widget.blockedWidget ?? _buildDefaultBlockedWidget();
    }

    return widget.child;
  }

  Widget _buildDefaultBlockedWidget() {
    return Scaffold(
      backgroundColor: WebTheme.grey50,
      appBar: AppBar(
        title: const Text('Game Unavailable'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
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
                  _getStatusIcon(_status),
                  size: 80,
                  color: _getStatusColor(_status),
                ),
                const Gap(24),
                Text(
                  _getStatusTitle(_status),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(16),
                Text(
                  _getStatusMessage(_status),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                if (_reason != null) ...[
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Reason:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Gap(8),
                        Text(
                          _reason!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
                if (_blockedUntil != null) ...[
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, color: Colors.blue[600], size: 20),
                        const Gap(8),
                        Text(
                          'Available until: ${_blockedUntil!.day}/${_blockedUntil!.month}/${_blockedUntil!.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Gap(32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WebTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'blocked':
        return Icons.block;
      case 'maintenance':
        return Icons.build;
      case 'hidden':
        return Icons.visibility_off;
      default:
        return Icons.error_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'blocked':
        return Colors.red[400]!;
      case 'maintenance':
        return Colors.blue[400]!;
      case 'hidden':
        return Colors.orange[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  String _getStatusTitle(String? status) {
    switch (status) {
      case 'blocked':
        return 'Game Blocked';
      case 'maintenance':
        return 'Under Maintenance';
      case 'hidden':
        return 'Game Hidden';
      default:
        return 'Game Unavailable';
    }
  }

  String _getStatusMessage(String? status) {
    switch (status) {
      case 'blocked':
        return 'This game has been blocked by administrators and is no longer accessible.';
      case 'maintenance':
        return 'This game is currently under maintenance and will be available again soon.';
      case 'hidden':
        return 'This game is currently hidden from the main menu but may still be accessible.';
      default:
        return 'This game is currently unavailable. Please try again later.';
    }
  }
}
