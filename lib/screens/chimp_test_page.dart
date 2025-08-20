import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/user_profile_service.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/services/app_logger.dart';

class ChimpTestPage extends StatefulWidget {
  const ChimpTestPage({super.key});

  @override
  State<ChimpTestPage> createState() => _ChimpTestPageState();
}

class _ChimpTestPageState extends State<ChimpTestPage> {
  // Game state
  GameState _gameState = GameState.instructions;
  int _currentLevel = 1;
  int _currentScore = 0;
  int _bestScore = 0;

  // Grid and numbers
  final int _gridSize = 6; // 6x6 grid for mobile
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
    final numbersCount = min(
      3 + _currentLevel - 1,
      8,
    ); // Start with 3, max 8 for mobile
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

    // Show numbers for 2.5 seconds, then hide them
    _gameTimer = Timer(const Duration(milliseconds: 2500), () {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPageHeader(),
              const SizedBox(height: 24),
              Expanded(child: _buildGameContent()),
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
            fontSize: 24,
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
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Game Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Icon(Icons.pets, size: 40, color: Colors.amber),
            ),
            const SizedBox(height: 24),

            // Title and Description
            const Text(
              'Chimp Test',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Test your working memory like a chimpanzee!\nNumbers will appear briefly, then you must tap them in order.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Best Score
            if (_bestScore > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Best Score: $_bestScore',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    return Column(
      children: [
        // Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Level', '$_currentLevel'),
              _buildStatItem('Score', '$_currentScore'),
              _buildStatItem('Best', '$_bestScore'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Game Grid
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridSize,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
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
                            borderRadius: BorderRadius.circular(8),
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
                                fontSize: 16,
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
                const SizedBox(height: 16),

                // Instructions
                Text(
                  _revealed.any((r) => r)
                      ? 'Memorize the numbers!'
                      : 'Tap the numbers in order: $_nextNumber',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final isNewBest = _currentScore == _bestScore && _currentScore > 0;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Result Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isNewBest
                    ? Colors.amber.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isNewBest ? Colors.amber : Colors.blue,
                  width: 2,
                ),
              ),
              child: Icon(
                isNewBest ? Icons.star : Icons.pets,
                size: 40,
                color: isNewBest ? Colors.amber : Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            // Result Title
            Text(
              isNewBest ? 'New Best Score!' : 'Test Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isNewBest ? Colors.amber[700]! : Colors.blue[700]!,
              ),
            ),
            const SizedBox(height: 24),

            // Scores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResultItem('Score', '$_currentScore', Colors.blue),
                _buildResultItem('Best', '$_bestScore', Colors.amber),
                _buildResultItem('Level', '${_currentLevel - 1}', Colors.green),
              ],
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Play Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _resetGame,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.lerp(color, Colors.black, 0.3)!,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}

enum GameState { instructions, playing, finished }
