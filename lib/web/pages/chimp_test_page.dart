import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              _buildPageHeader(),
              const Gap(32),
              Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: _buildGameContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 24),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Chimp Test',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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

          // Best Score
          if (_bestScore > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Best Score: $_bestScore',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          const Gap(32),

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Level and Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Level', '$_currentLevel'),
              _buildStatItem('Score', '$_currentScore'),
              _buildStatItem('Best', '$_bestScore'),
            ],
          ),
          const Gap(32),

          // Game Grid
          Container(
            width: 400,
            height: 400,
            child: GridView.builder(
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
                        color: isClicked ? Colors.green : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (isRevealed && hasNumber) ? number.toString() : '',
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
          ),
          const Gap(24),

          // Instructions
          Text(
            _revealed.any((r) => r)
                ? 'Memorize the numbers!'
                : 'Click the numbers in order: $_nextNumber',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Result Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isNewBest
                  ? Colors.amber.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isNewBest ? Colors.amber : Colors.blue,
                width: 3,
              ),
            ),
            child: Icon(
              isNewBest ? Icons.star : Icons.pets,
              size: 60,
              color: isNewBest ? Colors.amber : Colors.blue,
            ),
          ),
          const Gap(24),

          // Result Title
          Text(
            isNewBest ? 'New Best Score!' : 'Test Complete!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isNewBest ? Colors.amber[700]! : Colors.blue[700]!,
            ),
          ),
          const Gap(32),

          // Scores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResultItem('Score', '$_currentScore', Colors.blue),
              _buildResultItem('Best', '$_bestScore', Colors.amber),
              _buildResultItem('Level', '${_currentLevel - 1}', Colors.green),
            ],
          ),
          const Gap(32),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _resetGame,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Try Again'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text('Play Again'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
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
}

enum GameState { instructions, playing, finished }
