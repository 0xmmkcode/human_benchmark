import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/services/local_storage_service.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:human_benchmark/ad_helper.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:human_benchmark/widgets/game_page_header.dart';
import 'package:human_benchmark/widgets/game_score_display.dart';
import 'package:human_benchmark/widgets/brain_theme.dart';
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

  // AdMob banner ad
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

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
    _loadBannerAd();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _bannerAd?.dispose();
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

  void _loadBannerAd() {
    if (!kReleaseMode) return;
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
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
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GamePageHeader(
                    title: 'Number Memory Test',
                    subtitle:
                        'Number memory exercises help improve working memory, attention span, and cognitive flexibility. Regular practice can enhance your ability to process and retain information, which is valuable for learning, problem-solving, and daily tasks.',
                    primaryColor: BrainTheme.accentBrain,
                  ),
                  const Gap(24),

                  // Score Display
                  GameScoreDisplay(
                    title: 'Memory Performance',
                    scores: [
                      ScoreItem(
                        label: 'Level',
                        value: '$_currentLevel',
                        icon: Icons.trending_up,
                      ),
                      ScoreItem(
                        label: 'Score',
                        value: '$_currentScore',
                        icon: Icons.star,
                      ),
                      ScoreItem(
                        label: 'Best',
                        value: '$_bestScore',
                        icon: Icons.emoji_events,
                      ),
                    ],
                    primaryColor: BrainTheme.accentBrain,
                  ),
                  const Gap(24),

                  // Game Area
                  Expanded(child: _buildGameArea()),

                  // Banner Ad at bottom
                  if (kReleaseMode && _isBannerAdReady && _bannerAd != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        height: _bannerAd!.size.height.toDouble(),
                        width: _bannerAd!.size.width.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.all(16),
      decoration: BrainTheme.brainCard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BrainTheme.brainIcon(size: 60, color: BrainTheme.accentBrain),
          const Gap(16),
          Text(
            'Ready to Test Your Neural Memory?',
            style: BrainTheme.brainTitle.copyWith(
              fontSize: 20,
              color: BrainTheme.accentBrain,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(12),
          Text(
            'You\'ll see a number for a few seconds.\nThen type it back from memory.\n\nEach level completed adds to your total score!\nThe game continues until you make a mistake.',
            style: BrainTheme.brainSubtitle.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BrainTheme.accentBrain.withOpacity(0.1),
                  BrainTheme.accentBrain.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: BrainTheme.accentBrain.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BrainTheme.neuralPulse(
                      color: BrainTheme.accentBrain,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Neural Memory Training',
                      style: BrainTheme.brainLabel.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: BrainTheme.accentBrain,
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                Text(
                  'Number memory exercises help improve working memory, attention span, and cognitive flexibility. Regular practice can enhance your ability to process and retain information, which is valuable for learning, problem-solving, and daily tasks.',
                  style: BrainTheme.brainSubtitle.copyWith(
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Gap(20),
          Container(
            decoration: BoxDecoration(
              gradient: BrainTheme.brainGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: BrainTheme.accentBrain.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BrainTheme.neuralPulse(color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Start Neural Training',
                    style: BrainTheme.brainTitle.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  BrainTheme.neuralPulse(color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BrainTheme.brainCard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrainTheme.neuralPulse(color: BrainTheme.accentBrain, size: 12),
              const SizedBox(width: 6),
              Text(
                'Neural Memory Input',
                style: BrainTheme.brainLabel.copyWith(
                  fontSize: 16,
                  color: BrainTheme.accentBrain,
                ),
              ),
              const SizedBox(width: 6),
              BrainTheme.neuralPulse(color: BrainTheme.accentBrain, size: 12),
            ],
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BrainTheme.accentBrain.withOpacity(0.1),
                  BrainTheme.accentBrain.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: BrainTheme.accentBrain.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              _currentNumber,
              style: BrainTheme.brainTitle.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: BrainTheme.accentBrain,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Gap(24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BrainTheme.accentBrain.withOpacity(0.1),
                  BrainTheme.accentBrain.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: BrainTheme.accentBrain.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                ),
                const Gap(16),
                Text(
                  'Neural Processing...',
                  style: BrainTheme.brainSubtitle.copyWith(
                    fontSize: 16,
                    color: BrainTheme.accentBrain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BrainTheme.brainCard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrainTheme.neuralPulse(color: BrainTheme.accentBrain, size: 12),
              const SizedBox(width: 6),
              Text(
                'Neural Memory Recall',
                style: BrainTheme.brainLabel.copyWith(
                  fontSize: 16,
                  color: BrainTheme.accentBrain,
                ),
              ),
              const SizedBox(width: 6),
              BrainTheme.neuralPulse(color: BrainTheme.accentBrain, size: 12),
            ],
          ),
          const Gap(16),
          TextField(
            controller: _inputController,
            focusNode: _inputFocusNode,
            onChanged: (value) {
              setState(() {
                _userInput = value;
              });
            },
            onSubmitted: (_) => _checkAnswer(),
            style: BrainTheme.brainTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Enter number...',
              hintStyle: BrainTheme.brainSubtitle.copyWith(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: BrainTheme.accentBrain, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          const Gap(24),
          Container(
            decoration: BoxDecoration(
              gradient: _userInput.isNotEmpty
                  ? BrainTheme.brainGradient
                  : LinearGradient(
                      colors: [Colors.grey[400]!, Colors.grey[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _userInput.isNotEmpty
                  ? [
                      BoxShadow(
                        color: BrainTheme.accentBrain.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: _userInput.isNotEmpty ? _checkAnswer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_userInput.isNotEmpty)
                    BrainTheme.neuralPulse(color: Colors.white, size: 16),
                  if (_userInput.isNotEmpty) const SizedBox(width: 8),
                  Text(
                    'Submit Neural Response',
                    style: BrainTheme.brainTitle.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  if (_userInput.isNotEmpty) const SizedBox(width: 8),
                  if (_userInput.isNotEmpty)
                    BrainTheme.neuralPulse(color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    final resultColor = _isCorrect
        ? BrainTheme.successBrain
        : BrainTheme.errorBrain;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [resultColor.withOpacity(0.1), resultColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: resultColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: resultColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [resultColor, resultColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isCorrect ? Icons.check_circle : Icons.cancel,
              size: 36,
              color: Colors.white,
            ),
          ),
          const Gap(16),
          Text(
            _message,
            style: BrainTheme.brainTitle.copyWith(
              fontSize: 20,
              color: resultColor,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          if (_isCorrect) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrainTheme.successBrain.withOpacity(0.2),
                    BrainTheme.successBrain.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Neural Level $_currentLevel Completed!',
                style: BrainTheme.brainLabel.copyWith(
                  fontSize: 18,
                  color: BrainTheme.successBrain,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(8),
            Text(
              'Total Neural Score: $_currentScore',
              style: BrainTheme.brainSubtitle.copyWith(
                fontSize: 16,
                color: BrainTheme.successBrain,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              'Neural processing next level...',
              style: BrainTheme.brainSubtitle.copyWith(
                fontSize: 14,
                color: BrainTheme.successBrain,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Gap(24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrainTheme.successBrain,
                    BrainTheme.successBrain.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: BrainTheme.successBrain.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _nextLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BrainTheme.neuralPulse(color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Advance Neural Level',
                      style: BrainTheme.brainTitle.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BrainTheme.neuralPulse(color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              'Neural Overload!',
              style: BrainTheme.brainTitle.copyWith(
                fontSize: 20,
                color: BrainTheme.errorBrain,
              ),
            ),
            const Gap(8),
            Text(
              'Final Neural Score: $_currentScore',
              style: BrainTheme.brainSubtitle.copyWith(
                fontSize: 18,
                color: BrainTheme.errorBrain,
              ),
            ),
            const Gap(8),
            Text(
              'Neural Level reached: $_currentLevel',
              style: BrainTheme.brainSubtitle.copyWith(
                fontSize: 16,
                color: BrainTheme.errorBrain,
              ),
            ),
            const Gap(8),
            Text(
              'Best Neural Score: $_bestScore',
              style: BrainTheme.brainSubtitle.copyWith(
                fontSize: 16,
                color: BrainTheme.accentBrain,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(24),
            Container(
              decoration: BoxDecoration(
                gradient: BrainTheme.brainGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: BrainTheme.primaryBrain.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _restartGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BrainTheme.neuralPulse(color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Retrain Neural Network',
                      style: BrainTheme.brainTitle.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BrainTheme.neuralPulse(color: Colors.white, size: 16),
                  ],
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
