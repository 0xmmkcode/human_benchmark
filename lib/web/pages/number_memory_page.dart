import 'package:flutter/material.dart';
import 'package:human_benchmark/web/widgets/app_loading.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';
import 'package:human_benchmark/web/widgets/auth_required_wrapper.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/web/components/web_ad_banner.dart';
import 'dart:math';

class WebNumberMemoryPage extends StatefulWidget {
  const WebNumberMemoryPage({super.key});

  @override
  State<WebNumberMemoryPage> createState() => _WebNumberMemoryPageState();
}

class _WebNumberMemoryPageState extends State<WebNumberMemoryPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  GameState _gameState = GameState.ready;
  int _currentLevel = 1;
  int _currentScore = 0;
  int _bestScore = 0;
  String _currentNumber = '';
  String _userInput = '';

  bool _isCorrect = false;
  String _message = '';

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadBestScore();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    // Load best score from local storage or Firebase
    // For now, we'll use a placeholder
    setState(() {
      _bestScore = 0;
    });
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.showing;
      _currentLevel = 1;
      _currentScore = 0;
      _message = '';
      _isCorrect = false;
    });
    _generateNumber();
    _showNumber();
  }

  void _generateNumber() {
    final random = Random();
    final digits =
        _currentLevel + 2; // Start with 3 digits, increase by 1 each level
    _currentNumber = '';

    for (int i = 0; i < digits; i++) {
      _currentNumber += random.nextInt(10).toString();
    }
  }

  void _showNumber() async {
    await Future.delayed(Duration(milliseconds: 500));

    if (mounted && _gameState == GameState.showing) {
      setState(() {
        _gameState = GameState.input;
      });

      // Focus on input field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputFocusNode.requestFocus();
      });
    }
  }

  void _checkAnswer() {
    if (_userInput.trim() == _currentNumber) {
      setState(() {
        _isCorrect = true;
        _currentScore += _currentLevel; // Add the level score to current total
        _message = 'Correct! Well done!';
        _gameState = GameState.result;
      });

      if (_currentScore > _bestScore) {
        setState(() {
          _bestScore = _currentScore;
        });
        // Save best score
        _saveBestScore();
      }

      // Auto-proceed to next level after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _gameState == GameState.result && _isCorrect) {
          _nextLevel();
        }
      });
    } else {
      setState(() {
        _isCorrect = false;
        _message = 'Wrong! The number was $_currentNumber';
        _gameState = GameState.result;
      });
      // Save final game results when user loses
      _saveGameResults();
    }

    _scaleController.forward();
  }

  Future<void> _saveBestScore() async {
    try {
      // Submit to Firebase if user is authenticated
      if (AuthService.currentUser != null) {
        try {
          await ScoreService.submitGameScore(
            gameType: 'number_memory',
            score: _bestScore,
            additionalData: {
              'level': _currentLevel,
              'totalScore': _currentScore,
              'bestScore': _bestScore,
              'gameCompleted': false, // Still playing
            },
          );
        } catch (e) {
          print('Failed to save score to Firebase: $e');
        }
      }
    } catch (e) {
      print('Failed to save best score: $e');
    }
  }

  Future<void> _saveGameResults() async {
    try {
      // Submit final game results to Firebase if user is authenticated
      if (AuthService.currentUser != null) {
        try {
          await ScoreService.submitGameScore(
            gameType: 'number_memory',
            score: _currentScore,
            additionalData: {
              'level': _currentLevel,
              'totalScore': _currentScore,
              'bestScore': _bestScore,
              'gameCompleted': true, // Game ended
              'finalLevel': _currentLevel,
            },
          );
        } catch (e) {
          print('Failed to save final game results to Firebase: $e');
        }
      }
    } catch (e) {
      print('Failed to save game results: $e');
    }
  }

  void _nextLevel() {
    setState(() {
      _gameState = GameState.showing;
      _currentLevel++;
      _message = '';
      _isCorrect = false;
      _userInput = '';
      // Don't reset _currentScore here - it should accumulate
    });
    _inputController.clear();
    _generateNumber();
    _showNumber();
  }

  void _restartGame() {
    setState(() {
      _gameState = GameState.ready;
      _currentLevel = 1;
      _currentScore = 0;
      _message = '';
      _isCorrect = false;
      _userInput = '';
    });
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AuthRequiredWrapper(
      title: 'Number Memory Test',
      subtitle:
          'Sign in to play Number Memory and save your scores to track your progress.',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                PageHeader(
                  title: 'Number Memory Test',
                  subtitle: 'Remember the number sequence and type it back',
                ),
                Gap(40),

                // Score Display (equal widths)
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreCard(
                        'Level',
                        '$_currentLevel',
                        Icons.trending_up,
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _buildScoreCard(
                        'Score',
                        '$_currentScore',
                        Icons.star,
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _buildScoreCard(
                        'Best',
                        '$_bestScore',
                        Icons.emoji_events,
                      ),
                    ),
                  ],
                ),
                const Gap(25),

                // AdSense Banner between score cards and game
                WebAdBanner(height: 100, position: 'score_game'),
                const Gap(25),

                // Game Area
                Center(child: _buildGameArea()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: WebTheme.primaryBlue, size: 32),
          const Gap(8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: WebTheme.primaryBlue,
            ),
          ),
          const Gap(4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    switch (_gameState) {
      case GameState.ready:
        return _buildReadyState();
      case GameState.showing:
        return _buildShowingState();
      case GameState.input:
        return _buildInputState();
      case GameState.result:
        return _buildResultState();
    }
  }

  Widget _buildReadyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.memory, size: 80, color: WebTheme.primaryBlue),
          const Gap(24),
          Text(
            'Ready to test your memory?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          Text(
            'You\'ll see a number for a few seconds.\nThen type it back from memory.\n\nEach level completed adds to your total score!\nThe game continues until you make a mistake.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Game',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Remember this number:',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: WebTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: WebTheme.primaryBlue.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              _currentNumber,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: WebTheme.primaryBlue,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Gap(24),
          const AppLoading(width: 36, height: 36),
          const Gap(16),
          Text(
            'Memorizing...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Type the number you remember:',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          TextField(
            controller: _inputController,
            focusNode: _inputFocusNode,
            onChanged: (value) {
              setState(() {
                _userInput = value;
              });
            },
            onSubmitted: (_) => _checkAnswer(),
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Enter number...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: WebTheme.primaryBlue, width: 2),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          const Gap(24),
          ElevatedButton(
            onPressed: _userInput.isNotEmpty ? _checkAnswer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Submit Answer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            size: 80,
            color: _isCorrect ? Colors.green : Colors.red,
          ),
          const Gap(24),
          Text(
            _message,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isCorrect ? Colors.green : Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          if (_isCorrect) ...[
            Text(
              'Level $_currentLevel completed!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              'Total Score: $_currentScore',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              'Next level in 2 seconds...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: _nextLevel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next Level Now',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            Text(
              'Game Over!',
              style: TextStyle(
                fontSize: 20,
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              'Your final score: $_currentScore',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const Gap(8),
            Text(
              'Level reached: $_currentLevel',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const Gap(8),
            Text(
              'Best score: $_bestScore',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: WebTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum GameState { ready, showing, input, result }
