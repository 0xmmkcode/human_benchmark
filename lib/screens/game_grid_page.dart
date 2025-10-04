import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../services/game_management_service.dart';
import 'reaction_time_page.dart';
import 'number_memory_page.dart';
import 'decision_risk_page.dart';
import 'personality_quiz_page.dart';
import 'chimp_test_page.dart';
import 'about_page.dart';
import 'bug_report_page.dart';

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.games),
            const SizedBox(width: 8),
            Text(
              'Games',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BugReportPage()),
              );
            },
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Report a Bug',
          ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: GameManagementService.getVisibleGamesInOrderStream(),
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
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final visibleGames = snapshot.data ?? [];

          // Fallback games if no games are initialized yet
          final fallbackGames = visibleGames.isEmpty
              ? [
                  'reaction_time', // 1. Reaction Time - Core cognitive test
                  'number_memory', // 2. Number Memory - Memory (Basic)
                  'sequence_memory', // 3. Sequence Memory - Memory (Advanced)
                  'verbal_memory', // 4. Verbal Memory - Memory (Language)
                  'visual_memory', // 5. Visual Memory - Memory (Visual)
                  'chimp_test', // 6. Chimp Test - Memory (Complex)
                  'decision_risk', // 7. Decision Risk - Decision Making
                  'aim_trainer', // 8. Aim Trainer - Motor Skills
                  'personality_quiz', // 9. Personality Quiz - Assessment
                ]
              : visibleGames;

          if (fallbackGames.isEmpty) {
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
            child: fallbackGames.length == 1
                ? _buildSingleGameLayout(fallbackGames[0])
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: fallbackGames.length,
                    itemBuilder: (context, index) {
                      final gameId = fallbackGames[index];
                      return _buildGameCard(gameId);
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSingleGameLayout(String gameId) {
    final gameData = _getGameData(gameId);

    return GestureDetector(
      onTap: () => _navigateToGame(gameId),
      child: Container(
        width: double.infinity,
        height: 200,
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
                size: 120,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Left side - Icon and text
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(gameData.icon, size: 48, color: Colors.white),
                        const Gap(16),
                        Text(
                          gameData.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          gameData.subtitle,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const Gap(16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                size: 20,
                                color: Colors.white,
                              ),
                              const Gap(8),
                              Text(
                                'Tap to Play',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right side - Additional visual elements
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            gameData.icon,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const Gap(16),
                        Text(
                          'Available',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      case 'decision_risk':
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
      case 'chimp_test':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChimpTestPage()),
        );
        break;
      case 'aim_trainer':
        // TODO: Add AimTrainerPage when available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aim Trainer coming soon!'),
            backgroundColor: Colors.blue,
          ),
        );
        break;
      case 'verbal_memory':
        // TODO: Add VerbalMemoryPage when available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verbal Memory coming soon!'),
            backgroundColor: Colors.blue,
          ),
        );
        break;
      case 'visual_memory':
        // TODO: Add VisualMemoryPage when available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visual Memory coming soon!'),
            backgroundColor: Colors.blue,
          ),
        );
        break;
      case 'sequence_memory':
        // TODO: Add SequenceMemoryPage when available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sequence Memory coming soon!'),
            backgroundColor: Colors.blue,
          ),
        );
        break;
      default:
        // Handle unknown game
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game "$gameId" not implemented yet'),
            backgroundColor: Colors.orange,
          ),
        );
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
      case 'decision_risk':
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
      case 'chimp_test':
        return GameData(
          name: 'Chimp Test',
          subtitle: 'Test your memory',
          icon: Icons.pets,
          color: Color(0xFFF59E0B), // Amber
        );
      case 'aim_trainer':
        return GameData(
          name: 'Aim Trainer',
          subtitle: 'Test your precision',
          icon: Icons.gps_fixed,
          color: Color(0xFFEF4444), // Red
        );
      case 'verbal_memory':
        return GameData(
          name: 'Verbal Memory',
          subtitle: 'Remember words',
          icon: Icons.record_voice_over,
          color: Color(0xFF06B6D4), // Cyan
        );
      case 'visual_memory':
        return GameData(
          name: 'Visual Memory',
          subtitle: 'Remember patterns',
          icon: Icons.visibility,
          color: Color(0xFF84CC16), // Lime
        );
      case 'sequence_memory':
        return GameData(
          name: 'Sequence Memory',
          subtitle: 'Remember sequences',
          icon: Icons.format_list_numbered,
          color: Color(0xFFF97316), // Orange
        );
      default:
        return GameData(
          name: gameId
              .replaceAll('_', ' ')
              .split(' ')
              .map(
                (word) => word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                    : '',
              )
              .join(' '),
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
