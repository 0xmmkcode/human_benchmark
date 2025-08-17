import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../services/game_management_service.dart';
import '../models/game_management.dart';
import 'reaction_time_page.dart';
import 'number_memory_page.dart';
import 'decision_risk_page.dart';
import 'personality_quiz_page.dart';

class GameGridPage extends ConsumerStatefulWidget {
  const GameGridPage({super.key});

  @override
  ConsumerState<GameGridPage> createState() => _GameGridPageState();
}

class _GameGridPageState extends ConsumerState<GameGridPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Games',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<String>>(
        future: GameManagementService.getVisibleGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const Gap(16),
                  Text(
                    'Failed to load games',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final visibleGames = snapshot.data ?? [];

          if (visibleGames.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.games, size: 64, color: Colors.grey.shade400),
                  const Gap(16),
                  Text(
                    'No games available',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'All games are currently unavailable',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: visibleGames.length,
              itemBuilder: (context, index) {
                final gameId = visibleGames[index];
                return _buildGameCard(gameId);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameCard(String gameId) {
    final gameData = _getGameData(gameId);

    return GestureDetector(
      onTap: () => _navigateToGame(gameId),
      child: Container(
        decoration: BoxDecoration(
          color: gameData.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gameData.color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              top: -20,
              right: -20,
              child: Icon(
                gameData.icon,
                size: 80,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(gameData.icon, size: 32, color: Colors.white),
                  const Spacer(),
                  Text(
                    gameData.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    gameData.subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Play button overlay
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToGame(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReactionTimePage()),
        );
        break;
      case 'number_memory':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NumberMemoryPage()),
        );
        break;
      case 'decision_making':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DecisionRiskPage()),
        );
        break;
      case 'personality_quiz':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PersonalityQuizPage()),
        );
        break;
      default:
        // Handle unknown game
        break;
    }
  }

  GameData _getGameData(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return GameData(
          name: 'Reaction Time',
          subtitle: 'Test your reflexes',
          icon: Icons.flash_on,
          color: Color(0xFF6366F1), // Indigo
        );
      case 'number_memory':
        return GameData(
          name: 'Number Memory',
          subtitle: 'Remember sequences',
          icon: Icons.memory,
          color: Color(0xFF8B5CF6), // Purple
        );
      case 'decision_making':
        return GameData(
          name: 'Decision Risk',
          subtitle: 'Make choices',
          icon: Icons.speed,
          color: Color(0xFFEC4899), // Pink
        );
      case 'personality_quiz':
        return GameData(
          name: 'Personality Quiz',
          subtitle: 'Discover yourself',
          icon: Icons.psychology,
          color: Color(0xFF10B981), // Emerald
        );
      default:
        return GameData(
          name: 'Unknown Game',
          subtitle: 'Game not found',
          icon: Icons.games,
          color: Color(0xFF6B7280), // Gray
        );
    }
  }
}

class GameData {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;

  GameData({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
