import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';
import 'package:human_benchmark/web/widgets/auth_required_wrapper.dart';
import 'package:human_benchmark/web/components/web_ad_banner.dart';

import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/user_profile_service.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/services/app_logger.dart';

class WebChimpTestPage extends StatefulWidget {
  const WebChimpTestPage({super.key});

  @override
  State<WebChimpTestPage> createState() => _WebChimpTestPageState();
}

class _WebChimpTestPageState extends State<WebChimpTestPage> {
  // Game state
  GameState _gameState = GameState.instructions;
  int _currentLevel = 1;
  int _currentScore = 0;
  int _bestScore = 0;
  int _highestLevel = 0;

  // Grid and numbers
  final int _gridSize = 8; // 8x8 grid
  List<int> _numbers = [];
  List<int> _positions = [];
  List<bool> _revealed = [];
  List<bool> _clicked = [];
  int _nextNumber = 1;

  // Timing
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        final scores = await UserProfileService.getUserRecentScores(
          GameType.chimpTest,
        );
        if (scores.isNotEmpty) {
          setState(() {
            _bestScore = scores.map((s) => s.score).reduce(max);
            _highestLevel = scores
                .map((s) => (s.gameData?['level'] as num?)?.toInt() ?? 0)
                .fold(0, (prev, v) => v > prev ? v : prev);
          });
        }
      }
    } catch (e) {
      AppLogger.log('Failed to load best score: $e');
    }
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _currentLevel = 1;
      _currentScore = 0;
    });
    _startLevel();
  }

  void _startLevel() {
    final numbersCount = min(4 + _currentLevel - 1, 10); // Start with 4, max 10
    final random = Random();

    // Reset state
    _numbers.clear();
    _positions.clear();
    _revealed = List.filled(_gridSize * _gridSize, false);
    _clicked = List.filled(_gridSize * _gridSize, false);
    _nextNumber = 1;

    // Generate random positions for numbers
    final availablePositions = List.generate(_gridSize * _gridSize, (i) => i);
    availablePositions.shuffle(random);

    for (int i = 0; i < numbersCount; i++) {
      _numbers.add(i + 1);
      _positions.add(availablePositions[i]);
      _revealed[availablePositions[i]] = true;
    }

    setState(() {});

    // Show numbers for 3 seconds, then hide them
    _gameTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _revealed = List.filled(_gridSize * _gridSize, false);
      });
    });
  }

  void _onGridTap(int index) {
    if (_gameState != GameState.playing || _revealed.any((r) => r)) return;

    final numberIndex = _positions.indexOf(index);
    if (numberIndex == -1) {
      // Wrong tap - game over
      _gameOver();
      return;
    }

    final number = _numbers[numberIndex];
    if (number != _nextNumber) {
      // Wrong order - game over
      _gameOver();
      return;
    }

    setState(() {
      _clicked[index] = true;
      _nextNumber++;
    });

    // Check if level completed
    if (_nextNumber > _numbers.length) {
      _levelCompleted();
    }
  }

  void _levelCompleted() {
    setState(() {
      _currentScore = _currentLevel;
      _currentLevel++;
    });

    // Short delay before next level
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startLevel();
      }
    });
  }

  void _gameOver() {
    _gameTimer?.cancel();
    setState(() {
      _gameState = GameState.finished;
      if (_currentScore > _bestScore) {
        _bestScore = _currentScore;
      }
    });
    _saveScore();
  }

  Future<void> _saveScore() async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        await UserProfileService.submitGameScore(
          gameType: GameType.chimpTest,
          score: _currentScore,
          gameData: {'level': _currentLevel - 1},
        );
      }
    } catch (e) {
      AppLogger.log('Failed to save score: $e');
    }
  }

  void _resetGame() {
    _gameTimer?.cancel();
    setState(() {
      _gameState = GameState.instructions;
      _currentLevel = 1;
      _currentScore = 0;
      _nextNumber = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthRequiredWrapper(
      title: 'Chimp Test',
      subtitle:
          'Sign in to play the Chimp Test and save your scores to track your progress.',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PageHeader(
                title: 'Chimp Test',
                subtitle:
                    'Test your working memory with this challenging sequence game.',
              ),
              const Gap(32),
              Container(
                child: _buildGameContent(),
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    switch (_gameState) {
      case GameState.instructions:
        return _buildInstructions();
      case GameState.playing:
        return _buildGame();
      case GameState.finished:
        return _buildResults();
    }
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Game Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: const Icon(Icons.pets, size: 60, color: Colors.amber),
          ),
          const Gap(32),

          // Title and Description
          const Text(
            'Chimp Test',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Gap(16),
          const Text(
            'Test your working memory like a chimpanzee!\nNumbers will appear briefly, then you must click them in order.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          // AdSense Banner before game start
          WebAdBanner(height: 100, position: 'before_game'),
          const Gap(32),
          // Stats before starting

          // Start Button
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Start Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show only current level while playing
          /* Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreCard(
                icon: Icons.trending_up,
                label: 'Level',
                value: '$_currentLevel',
                color: Colors.blue,
                isHighlighted: true,
              ),
            ],
          ),
          const Gap(24),*/
          /*Container(
            height: 250,
            width: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreCard(
                        icon: Icons.trending_up,
                        label: 'Level',
                        value: '$_currentLevel',
                        color: Colors.blue,
                        isHighlighted: true,
                        isSmall: true,
                      ),
                    ),
                    Gap(20),
                    Expanded(
                      child: _buildScoreCard(
                        icon: Icons.score,
                        label: 'Score',
                        value: '$_currentScore',
                        color: Colors.amber,
                        isHighlighted: false,
                        isSmall: true,
                      ),
                    ),
                  ],
                ),
                Gap(20),
                // Restart Game Button (match score card theme)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _currentLevel = 1;
                        _currentScore = 0;
                        _gameState = GameState.playing;
                        _startLevel();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.withOpacity(0.15),
                            Colors.red.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh,
                            color: Colors.red.withOpacity(0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Restart',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),*/
          const Gap(24),
          // Game Grid - responsive to avoid overflow
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Level $_currentLevel',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double maxSide = 400;
                  final double side =
                      [
                            maxSide,
                            constraints.maxWidth,
                            constraints.maxHeight -
                                180, // leave space for text/buttons
                          ]
                          .where((v) => v.isFinite && v > 0)
                          .reduce((a, b) => a < b ? a : b);
                  final double gridSide = side.clamp(220, maxSide);

                  return SizedBox(
                    width: gridSide,
                    height: gridSide,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridSize,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: _gridSize * _gridSize,
                      itemBuilder: (context, index) {
                        final numberIndex = _positions.indexOf(index);
                        final hasNumber = numberIndex != -1;
                        final number = hasNumber ? _numbers[numberIndex] : 0;
                        final isRevealed = _revealed[index];
                        final isClicked = _clicked[index];

                        return GestureDetector(
                          onTap: () => _onGridTap(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isClicked
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : (hasNumber
                                        ? Colors.amber.withValues(alpha: 0.8)
                                        : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isClicked
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (isRevealed && hasNumber)
                                    ? number.toString()
                                    : '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              Gap(20),
              Text(
                _revealed.any((r) => r)
                    ? 'Memorize the numbers!'
                    : 'Click the numbers in order: $_nextNumber',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              // Controls under the instruction message
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pillButton(
                    icon: Icons.refresh,
                    label: 'Restart',
                    color: Colors.red,
                    onTap: () {
                      setState(() {
                        _currentLevel = 1;
                        _currentScore = 0;
                        _gameState = GameState.playing;
                        _startLevel();
                      });
                    },
                  ),
                  _pillButton(
                    icon: Icons.stop_circle_outlined,
                    label: 'End',
                    color: Colors.grey,
                    onTap: () {
                      setState(() {
                        _gameTimer?.cancel();
                        _gameState = GameState.finished;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),

          // Instructions
        ],
      ),
    );
  }

  Widget _buildResults() {
    final isNewBest = _currentScore == _bestScore && _currentScore > 0;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Final stats: last score and best score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreCard(
                icon: Icons.score,
                label: 'Last Score',
                value: '$_currentScore',
                color: Colors.blue,
                isHighlighted: false,
              ),
              const SizedBox(width: 16),
              _buildScoreCard(
                icon: Icons.emoji_events,
                label: 'Best Score',
                value: '$_bestScore',
                color: Colors.amber,
                isHighlighted: false,
              ),
            ],
          ),
          const Gap(24),

          // Action Buttons
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.lerp(color, Colors.black, 0.3)!,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildScoreCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Level Card
        _buildScoreCard(
          icon: Icons.trending_up,
          label: 'Level',
          value: '$_currentLevel',
          color: Colors.blue,
          isHighlighted: true,
        ),

        // Score Card
        _buildScoreCard(
          icon: Icons.star,
          label: 'Score',
          value: '$_currentScore',
          color: Colors.amber,
          isHighlighted: false,
        ),

        // Best Card
        _buildScoreCard(
          icon: Icons.emoji_events,
          label: 'Best',
          value: '$_bestScore',
          color: Colors.purple,
          isHighlighted: false,
        ),
      ],
    );
  }

  Widget _buildScoreCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isHighlighted,
    bool isSmall = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHighlighted
              ? [color.withOpacity(0.15), color.withOpacity(0.08)]
              : [color.withOpacity(0.08), color.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Icon with background
          if (!isSmall) ...[
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const Gap(16),
          ],

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
          ),
          const Gap(6),

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color.withOpacity(0.9)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum GameState { instructions, playing, finished }
