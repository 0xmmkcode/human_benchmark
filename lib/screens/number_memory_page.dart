import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/services/local_storage_service.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/models/game_score.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class NumberMemoryPage extends StatefulWidget {
  const NumberMemoryPage({super.key});

  @override
  State<NumberMemoryPage> createState() => _NumberMemoryPageState();
}

class _NumberMemoryPageState extends State<NumberMemoryPage>
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
    try {
      final bestScore = await LocalStorageService.getBestTime();
      if (mounted) {
        setState(() {
          _bestScore = bestScore ?? 0;
        });
      }
    } catch (e) {
      print('Failed to load best score: $e');
    }
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
      await LocalStorageService.saveBestTime(_bestScore);

      // Submit to Firebase if user is authenticated
      if (AuthService.currentUser != null) {
        try {
          await ScoreService.submitGameScore(
            gameType: GameType.numberMemory,
            score: _bestScore,
            gameData: {
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
            gameType: GameType.numberMemory,
            score: _currentScore,
            gameData: {
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
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final bool isAuthenticated = snapshot.data != null;
        if (!isAuthenticated) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in required',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please sign in to play Number Memory and save your scores.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Sign in with Google'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final cred = await AuthService.signInWithGoogle();
                            if (mounted && cred != null) {
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Authenticated user - show the game
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              'Number Memory',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.grey[800],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Score Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreCard(
                        'Level',
                        '$_currentLevel',
                        Icons.trending_up,
                      ),
                      _buildScoreCard('Score', '$_currentScore', Icons.star),
                      _buildScoreCard(
                        'Best',
                        '$_bestScore',
                        Icons.emoji_events,
                      ),
                    ],
                  ),
                  const Gap(32),

                  // Game Area
                  Expanded(child: _buildGameArea()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[600], size: 24),
          const Gap(8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
          const Gap(4),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
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
      padding: const EdgeInsets.all(24),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.memory, size: 80, color: Colors.blue[600]),
          const Gap(24),
          Text(
            'Ready to test your memory?',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          Text(
            'You\'ll see a number for a few seconds.\nThen type it back from memory.\n\nEach level completed adds to your total score!\nThe game continues until you make a mistake.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Start Game',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowingState() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Remember this number:',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const Gap(24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue[600]!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue[600]!.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              _currentNumber,
              style: GoogleFonts.montserrat(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
          ),
          const Gap(24),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const Gap(16),
          Text(
            'Memorizing...',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputState() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Type the number you remember:',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: Colors.grey[600],
            ),
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
            style: GoogleFonts.montserrat(
              fontSize: 24,
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
                borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
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
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Submit Answer',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            size: 80,
            color: _isCorrect ? Colors.green : Colors.red,
          ),
          const Gap(24),
          Text(
            _message,
            style: GoogleFonts.montserrat(
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
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.green[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              'Total Score: $_currentScore',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.green[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              'Next level in 2 seconds...',
              style: GoogleFonts.montserrat(
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
              child: Text(
                'Next Level Now',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            Text(
              'Game Over!',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              'Your final score: $_currentScore',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const Gap(8),
            Text(
              'Level reached: $_currentLevel',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const Gap(8),
            Text(
              'Best score: $_bestScore',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum GameState { ready, showing, input, result }
