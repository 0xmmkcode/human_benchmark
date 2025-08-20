import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/services/local_storage_service.dart';

import 'dart:math';
import 'dart:async';

class WebTypingSpeedPage extends StatefulWidget {
  const WebTypingSpeedPage({super.key});

  @override
  State<WebTypingSpeedPage> createState() => _WebTypingSpeedPageState();
}

class _WebTypingSpeedPageState extends State<WebTypingSpeedPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  GameState _gameState = GameState.ready;
  int _currentWPM = 0;
  int _bestWPM = 0;
  int _accuracy = 100;
  int _totalWords = 0;
  int _correctWords = 0;
  int _timeElapsed = 0;
  int _textsCompleted = 0;

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final Stopwatch _stopwatch = Stopwatch();

  // Sample texts for typing test
  static const List<String> _sampleTexts = [
    "The quick brown fox jumps over the lazy dog. This pangram contains every letter of the alphabet at least once.",
    "All work and no play makes Jack a dull boy. Variety is the spice of life, and learning new skills keeps our minds sharp.",
    "Success is not final, failure is not fatal: it is the courage to continue that counts. Every expert was once a beginner.",
    "The only way to do great work is to love what you do. If you haven't found it yet, keep looking and don't settle.",
    "Life is what happens when you're busy making other plans. The future belongs to those who believe in the beauty of their dreams.",
    "In the middle of difficulty lies opportunity. The greatest glory in living lies not in never falling, but in rising every time we fall.",
    "Education is the most powerful weapon which you can use to change the world. Knowledge is power, and learning is a lifelong journey.",
    "The journey of a thousand miles begins with one step. Small progress is still progress, and consistency is the key to success.",
    "Creativity is intelligence having fun. Innovation distinguishes between a leader and a follower. Think different, act bold.",
    "Happiness is not something ready made. It comes from your own actions. Choose to be happy, and spread joy to others.",
  ];

  String _currentText = '';
  String _userInput = '';
  int _currentTextIndex = 0;

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
    _selectRandomText();
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
          _bestWPM = bestScore ?? 0;
        });
      }
    } catch (e) {
      print('Failed to load best score: $e');
    }
  }

  void _selectRandomText() {
    final random = Random();
    _currentTextIndex = random.nextInt(_sampleTexts.length);
    _currentText = _sampleTexts[_currentTextIndex];
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.typing;
      _currentWPM = 0;
      _accuracy = 100;
      _totalWords = 0;
      _correctWords = 0;
      _timeElapsed = 0;
      _userInput = '';
      _inputController.clear();
    });

    _selectRandomText();
    _stopwatch.start();

    // Focus on input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });

    // Start timer to update WPM
    _startTimer();
  }

  void _startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameState == GameState.typing && mounted) {
        setState(() {
          _timeElapsed = _stopwatch.elapsed.inSeconds;
          _calculateWPM();
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _calculateWPM() {
    if (_timeElapsed > 0) {
      // Standard WPM calculation: 5 characters = 1 word
      final charactersTyped = _userInput.trim().length;
      final wordsTyped = (charactersTyped / 5.0).ceil();
      final minutes = _timeElapsed / 60.0;
      _currentWPM = (wordsTyped / minutes).round();
    }
  }

  void _onInputChanged(String value) {
    setState(() {
      _userInput = value;
      _calculateWPM();
      _calculateAccuracy();
    });

    // Check if user has completed the text (more flexible matching)
    final userText = _userInput.trim();
    final targetText = _currentText.trim();

    if (userText.length >= targetText.length &&
        userText.substring(0, targetText.length) == targetText) {
      _finishGame();
    }
  }

  void _calculateAccuracy() {
    if (_currentText.isEmpty) return;

    // Calculate character-based accuracy for more precision
    final targetText = _currentText.trim();
    final userText = _userInput.trim();

    if (targetText.isEmpty) return;

    int correctCharacters = 0;
    final minLength = targetText.length < userText.length
        ? targetText.length
        : userText.length;

    for (int i = 0; i < minLength; i++) {
      if (userText[i] == targetText[i]) {
        correctCharacters++;
      }
    }

    _accuracy = ((correctCharacters / targetText.length) * 100).round();

    // Also calculate word-based stats for display
    final userWords = userText
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
    final targetWords = targetText
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    _totalWords = targetWords.length;
    _correctWords = 0;

    for (int i = 0; i < userWords.length && i < targetWords.length; i++) {
      if (userWords[i] == targetWords[i]) {
        _correctWords++;
      }
    }
  }

  void _finishGame() {
    _stopwatch.stop();
    setState(() {
      _gameState = GameState.result;
      _timeElapsed = _stopwatch.elapsed.inSeconds;
      _calculateWPM();
      _calculateAccuracy();
    });

    _scaleController.forward();

    // Save score if it's a new best
    if (_currentWPM > _bestWPM) {
      setState(() {
        _bestWPM = _currentWPM;
      });
      _saveBestScore();
    }

    // Submit score to Firebase
    _submitScore();
  }

  void _continueToNextText() {
    setState(() {
      _gameState = GameState.typing;
      _currentWPM = 0;
      _accuracy = 100;
      _totalWords = 0;
      _correctWords = 0;
      _timeElapsed = 0;
      _userInput = '';
      _inputController.clear();
      _textsCompleted++;
    });

    _stopwatch.reset();
    _selectRandomText();
    _stopwatch.start();
    _startTimer();

    // Focus on input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  Future<void> _saveBestScore() async {
    try {
      await LocalStorageService.saveBestTime(_bestWPM);
    } catch (e) {
      print('Failed to save best score: $e');
    }
  }

  Future<void> _submitScore() async {
    try {
      if (AuthService.currentUser != null) {
        final success = await ScoreService.submitGameScore(
          gameType: 'typing_speed',
          score: _currentWPM,
          additionalData: {
            'accuracy': _accuracy,
            'timeElapsed': _timeElapsed,
            'totalWords': _totalWords,
            'correctWords': _correctWords,
            'wpm': _currentWPM,
            'charactersTyped': _userInput.trim().length,
            'targetCharacters': _currentText.trim().length,
          },
        );

        if (success) {
          print('Typing speed score submitted successfully: $_currentWPM WPM');
        } else {
          print('Failed to submit typing speed score');
        }
      } else {
        print('User not authenticated, skipping score submission');
      }
    } catch (e) {
      print('Failed to submit score: $e');
    }
  }

  void _restartGame() {
    setState(() {
      _gameState = GameState.ready;
      _currentWPM = 0;
      _accuracy = 100;
      _totalWords = 0;
      _correctWords = 0;
      _timeElapsed = 0;
      _userInput = '';
      _inputController.clear();
      _textsCompleted = 0;
    });

    _stopwatch.reset();
    _selectRandomText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            _buildPageHeader(),
            SizedBox(height: 24),

            // Game content
            if (_gameState == GameState.ready) _buildReadyState(),
            if (_gameState == GameState.typing) _buildTypingState(),
            if (_gameState == GameState.result) _buildResultState(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[200],
                padding: EdgeInsets.all(12),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Typing Speed',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Test your typing speed and accuracy',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadyState() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: WebTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(Icons.keyboard, size: 60, color: WebTheme.primaryBlue),
          ),
          Gap(32),
          Text(
            'Test Your Typing Speed',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          Gap(16),
          Text(
            'Type the text as quickly and accurately as possible.\nYour score is measured in Words Per Minute (WPM).',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          Gap(32),
          if (_bestWPM > 0)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Best Score: $_bestWPM WPM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          Gap(32),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Start Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingState() {
    return Column(
      children: [
        // Stats bar
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50]!,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('WPM', '$_currentWPM', WebTheme.primaryBlue),
              _buildStatItem('Accuracy', '$_accuracy%', Colors.green),
              _buildStatItem('Time', '${_timeElapsed}s', Colors.orange),
              _buildStatItem('Texts', '$_textsCompleted', Colors.purple),
            ],
          ),
        ),
        Gap(24),

        // Text to type
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[50]!,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            _currentText,
            style: TextStyle(
              fontSize: 18,
              height: 1.6,
              color: Colors.grey[800],
            ),
          ),
        ),
        Gap(24),

        // Input field
        TextField(
          controller: _inputController,
          focusNode: _inputFocusNode,
          onChanged: _onInputChanged,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Start typing here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WebTheme.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: TextStyle(fontSize: 16),
        ),
        Gap(24),

        // Progress indicator
        LinearProgressIndicator(
          value: _userInput.length / _currentText.length,
          backgroundColor: Colors.grey[200]!,
          valueColor: AlwaysStoppedAnimation<Color>(WebTheme.primaryBlue),
        ),
        Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_userInput.length}/${_currentText.length} characters',
              style: TextStyle(color: Colors.grey[600]!),
            ),
            Text(
              'Real-time WPM: $_currentWPM',
              style: TextStyle(
                color: WebTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultState() {
    return Center(
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleController,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _currentWPM >= _bestWPM
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                _currentWPM >= _bestWPM ? Icons.emoji_events : Icons.speed,
                size: 60,
                color: _currentWPM >= _bestWPM ? Colors.green : Colors.blue,
              ),
            ),
          ),
          Gap(32),

          Text(
            _currentWPM >= _bestWPM ? 'New Best Score!' : 'Test Complete!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _currentWPM >= _bestWPM ? Colors.green : Colors.grey[800],
            ),
          ),
          Gap(24),

          // Results grid
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50]!,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildResultItem(
                      'WPM',
                      '$_currentWPM',
                      WebTheme.primaryBlue,
                    ),
                    _buildResultItem('Accuracy', '$_accuracy%', Colors.green),
                  ],
                ),
                Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildResultItem('Time', '${_timeElapsed}s', Colors.orange),
                    _buildResultItem('Texts Completed', '$_textsCompleted', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          Gap(32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _continueToNextText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Continue', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: _restartGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Try Again', style: TextStyle(fontSize: 16)),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Back to Games', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600]!)),
      ],
    );
  }

  Widget _buildResultItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600]!)),
      ],
    );
  }
}

enum GameState { ready, typing, result }
