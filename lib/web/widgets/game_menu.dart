import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/services/game_management_service.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';

class GameMenu extends StatefulWidget {
  final Function(String) onGameSelected;
  final String? selectedGameId;
  final bool showIcons;
  final bool compact;

  const GameMenu({
    super.key,
    required this.onGameSelected,
    this.selectedGameId,
    this.showIcons = true,
    this.compact = false,
  });

  @override
  State<GameMenu> createState() => _GameMenuState();
}

class _GameMenuState extends State<GameMenu> {
  List<String> _visibleGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisibleGames();
  }

  Future<void> _loadVisibleGames() async {
    try {
      final games = await GameManagementService.getVisibleGames();
      if (mounted) {
        setState(() {
          _visibleGames = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getGameIcon(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return Icons.timer;
      case 'number_memory':
        return Icons.memory;
      case 'decision_making':
        return Icons.speed;
      case 'personality_quiz':
        return Icons.psychology;
      case 'aim_trainer':
        return Icons.gps_fixed;
      case 'verbal_memory':
        return Icons.record_voice_over;
      case 'visual_memory':
        return Icons.visibility;
        return Icons.keyboard;
      case 'sequence_memory':
        return Icons.format_list_numbered;
      case 'chimp_test':
        return Icons.pets;
      default:
        return Icons.games;
    }
  }

  String _getGameName(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return 'Reaction Time';
      case 'number_memory':
        return 'Number Memory';
      case 'decision_making':
        return 'Decision Making';
      case 'personality_quiz':
        return 'Personality Quiz';
      case 'aim_trainer':
        return 'Aim Trainer';
      case 'verbal_memory':
        return 'Verbal Memory';
      case 'visual_memory':
        return 'Visual Memory';
      case 'sequence_memory':
        return 'Sequence Memory';
      case 'chimp_test':
        return 'Chimp Test';
      default:
        return gameId
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : '',
            )
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_visibleGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.grey[400]),
            const Gap(16),
            Text(
              'No games available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const Gap(8),
            Text(
              'All games are currently unavailable',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (widget.compact) {
      return _buildCompactMenu();
    }

    return _buildFullMenu();
  }

  Widget _buildFullMenu() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _visibleGames.length,
      itemBuilder: (context, index) {
        final gameId = _visibleGames[index];
        final isSelected = gameId == widget.selectedGameId;

        return _buildGameCard(gameId, isSelected);
      },
    );
  }

  Widget _buildCompactMenu() {
    return Column(
      children: _visibleGames.map((gameId) {
        final isSelected = gameId == widget.selectedGameId;
        return _buildGameTile(gameId, isSelected);
      }).toList(),
    );
  }

  Widget _buildGameCard(String gameId, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onGameSelected(gameId),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? WebTheme.primaryBlue.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? WebTheme.primaryBlue : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.showIcons) ...[
              Icon(
                _getGameIcon(gameId),
                size: 48,
                color: isSelected ? WebTheme.primaryBlue : Colors.grey[600],
              ),
              const Gap(16),
            ],
            Text(
              _getGameName(gameId),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? WebTheme.primaryBlue : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: WebTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SELECTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameTile(String gameId, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? WebTheme.primaryBlue.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? WebTheme.primaryBlue : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => widget.onGameSelected(gameId),
        leading: widget.showIcons
            ? Icon(
                _getGameIcon(gameId),
                color: isSelected ? WebTheme.primaryBlue : Colors.grey[600],
              )
            : null,
        title: Text(
          _getGameName(gameId),
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? WebTheme.primaryBlue : Colors.grey[800],
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: WebTheme.primaryBlue)
            : null,
      ),
    );
  }
}
