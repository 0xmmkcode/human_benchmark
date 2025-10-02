import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:gap/gap.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:human_benchmark/ad_helper.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/services/local_storage_service.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/widgets/reaction_time_leaderboard.dart';
import 'package:human_benchmark/widgets/game_page_header.dart';
import 'package:human_benchmark/widgets/game_score_display.dart';
import 'package:human_benchmark/widgets/brain_theme.dart';

class ReactionTimePage extends StatefulWidget {
  @override
  _ReactionTimePageState createState() => _ReactionTimePageState();
}

enum GameState { ready, waiting, go, result }

class _ReactionTimePageState extends State<ReactionTimePage> {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _roundCounter = 0;

  bool _isBannerAdReady = false;
  GameState _state = GameState.ready;
  Timer? _timer;
  DateTime? _startTime;
  int? _reactionTime;
  int? _highScore;
  int _totalTests = 0;
  int _averageTime = 0;

  final Random _random = Random();
  final Color backgroundColor = Color(0xFF0074EB);

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _loadReactionTimeStats();
    if (kReleaseMode) {
      _loadInterstitialAd();
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
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadInterstitialAd() {
    if (!kReleaseMode) return;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoaded = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void _startGame() {
    setState(() {
      _state = GameState.waiting;
      _reactionTime = null;
    });

    int delay = 2000 + _random.nextInt(3000); // 2 to 5 seconds
    _timer = Timer(Duration(milliseconds: delay), () {
      setState(() {
        _state = GameState.go;
        _startTime = DateTime.now();
      });
    });
  }

  void _onScreenTap() async {
    _roundCounter++;

    if (kReleaseMode && _roundCounter % 8 == 0 && _isAdLoaded) {
      _interstitialAd?.show();
      _interstitialAd = null;
      _isAdLoaded = false;
      _loadInterstitialAd();
    }
    if (_state == GameState.waiting) {
      _timer?.cancel();
      setState(() {
        _state = GameState.result;
        _reactionTime = -1; // Too early
      });
    } else if (_state == GameState.go) {
      final now = DateTime.now();

      setState(() {
        _state = GameState.result;
        _reactionTime = now.difference(_startTime!).inMilliseconds;
      });

      // Always save to local storage
      await LocalStorageService.addTime(_reactionTime!);

      // Update local stats
      _totalTests++;
      _averageTime =
          (((_averageTime * (_totalTests - 1)) + _reactionTime!) / _totalTests)
              .round();

      // Save to Firebase if user is logged in - ALWAYS update counter and average
      if (AuthService.currentUser != null) {
        try {
          // Submit the game score - this updates totalGames and averageScore
          await ScoreService.submitGameScore(
            gameType: 'reaction_time',
            score: _reactionTime!,
            additionalData: {
              'roundCounter': _roundCounter,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            },
          );

          // Note: submitGameScore already handles updating totalGames and averageScore
          // No need to call updateReactionTimeAverage separately
        } catch (e) {
          // Log error but don't break the game
          print('Failed to save score to Firebase: $e');
        }
      }

      // Check if this is a new high score - only update best score when better
      if (_reactionTime! < (_highScore ?? 999999)) {
        _highScore = _reactionTime;
        await LocalStorageService.saveBestTime(_reactionTime!);
      }

      // Update the UI and refresh stats
      setState(() {});

      // Refresh stats from Firebase to ensure consistency
      if (AuthService.currentUser != null) {
        _refreshStatsFromFirebase();
      }
    } else if (_state == GameState.result) {
      setState(() {
        _state = GameState.ready;
      });
    }
  }

  Future<void> _loadHighScore() async {
    try {
      // Try to get high score from Firebase first if user is logged in
      if (AuthService.currentUser != null) {
        try {
          final userScore = await ScoreService.getUserScoreProfile();
          if (userScore != null) {
            final firebaseBestTime = userScore.getHighScore(
              GameType.reactionTime,
            );
            if (firebaseBestTime > 0) {
              setState(() {
                _highScore = firebaseBestTime;
              });
              return;
            }
          }
        } catch (e) {
          print('Failed to load Firebase high score: $e');
          // Continue to local fallback
        }
      }

      // Fallback to local storage
      final bestTime = await LocalStorageService.getBestTime();
      setState(() {
        _highScore = bestTime;
      });
    } catch (e) {
      print('Error loading high score: $e');
      setState(() {
        _highScore = null;
      });
    }
  }

  Future<void> _refreshStatsFromFirebase() async {
    try {
      if (AuthService.currentUser == null) return;

      final firebaseStats = await ScoreService.getReactionTimeStats();
      if (firebaseStats.isNotEmpty && firebaseStats['totalGames'] != null) {
        setState(() {
          _totalTests =
              (firebaseStats['totalGames'] as num?)?.toInt() ?? _totalTests;
          _averageTime =
              (firebaseStats['averageScore'] as num?)?.round() ?? _averageTime;
        });
      }
    } catch (e) {
      print('Failed to refresh stats from Firebase: $e');
    }
  }

  Future<void> _loadReactionTimeStats() async {
    try {
      setState(() {
        // Loading stats...
      });

      // Always load local stats first as fallback
      final localTimes = await LocalStorageService.getTimesList();
      int localTotalTests = localTimes.length;
      int localAverageTime = 0;

      if (localTimes.isNotEmpty) {
        localAverageTime =
            (localTimes.reduce((a, b) => a + b) / localTimes.length).round();
      }

      // Try to get stats from Firebase if user is logged in
      if (AuthService.currentUser != null) {
        try {
          // First try to initialize stats if they don't exist
          await ScoreService.initializeReactionTimeStats();

          final firebaseStats = await ScoreService.getReactionTimeStats();
          if (firebaseStats.isNotEmpty && firebaseStats['totalTests'] != null) {
            // Use Firebase stats if available
            setState(() {
              _totalTests = firebaseStats['totalTests'] ?? localTotalTests;
              _averageTime = firebaseStats['averageTime'] ?? localAverageTime;
            });
            return;
          }
        } catch (e) {
          print('Failed to load Firebase stats: $e');
          // Continue to local fallback
        }
      }

      // Use local storage stats
      setState(() {
        _totalTests = localTotalTests;
        _averageTime = localAverageTime;
      });
    } catch (e) {
      print('Error loading reaction time stats: $e');
      // Set default values on error
      setState(() {
        _totalTests = 0;
        _averageTime = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GamePageHeader(
                  title: 'Reaction Time Test',
                  subtitle:
                      'Reaction time measures how quickly you can respond to a visual stimulus. This test helps assess your cognitive processing speed, which is crucial for daily activities like driving, sports, and decision-making. The average human reaction time is 200-300ms.',
                  primaryColor: BrainTheme.primaryBrain,
                ),
                const Gap(24),

                // Game Area
                Center(
                  child: Column(
                    children: [
                      // Game Instructions
                      if (_state == GameState.ready)
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          decoration: BrainTheme.brainCard,
                          child: Column(
                            children: [
                              BrainTheme.brainIcon(
                                size: 40,
                                color: BrainTheme.primaryBrain,
                              ),
                              const Gap(16),
                              Text(
                                'Ready to Test Your Reflexes?',
                                style: BrainTheme.brainTitle.copyWith(
                                  fontSize: 18,
                                  color: BrainTheme.primaryBrain,
                                ),
                              ),
                              const Gap(10),
                              Text(
                                'Wait for the screen to turn green, then tap as fast as you can!',
                                textAlign: TextAlign.center,
                                style: BrainTheme.brainSubtitle.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              const Gap(20),
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: BrainTheme.brainGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: BrainTheme.primaryBrain
                                            .withOpacity(0.3),
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
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        BrainTheme.neuralPulse(
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Start Test',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 6),
                                        BrainTheme.neuralPulse(
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Waiting State
                      if (_state == GameState.waiting)
                        GestureDetector(
                          onTapDown: (_) {
                            // Too early -> game over
                            setState(() {
                              _state = GameState.result;
                              _reactionTime = -1;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  BrainTheme.warningBrain.withOpacity(0.1),
                                  BrainTheme.warningBrain.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: BrainTheme.warningBrain.withOpacity(
                                    0.1,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        BrainTheme.warningBrain,
                                        BrainTheme.warningBrain.withOpacity(
                                          0.8,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.hourglass_empty,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                const Gap(16),
                                Text(
                                  'Neural Processing...',
                                  style: BrainTheme.brainTitle.copyWith(
                                    fontSize: 18,
                                    color: BrainTheme.warningBrain,
                                  ),
                                ),
                                const Gap(10),
                                Text(
                                  'The screen will turn green soon. Don\'t tap yet!',
                                  textAlign: TextAlign.center,
                                  style: BrainTheme.brainSubtitle.copyWith(
                                    fontSize: 13,
                                    color: BrainTheme.warningBrain,
                                  ),
                                ),
                                const Gap(12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    BrainTheme.neuralPulse(
                                      color: BrainTheme.warningBrain,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 6),
                                    BrainTheme.neuralPulse(
                                      color: BrainTheme.warningBrain,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    BrainTheme.neuralPulse(
                                      color: BrainTheme.warningBrain,
                                      size: 10,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Game Area (Green Screen)
                      if (_state == GameState.go)
                        GestureDetector(
                          onTapDown: (_) => _onScreenTap(),
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  BrainTheme.successBrain,
                                  BrainTheme.successBrain.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: BrainTheme.successBrain.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  BrainTheme.neuralPulse(
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'TAP NOW!',
                                    style: BrainTheme.brainTitle.copyWith(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Neural Response Required',
                                    style: BrainTheme.brainSubtitle.copyWith(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Results
                      if (_state == GameState.result)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _reactionTime == -1
                                  ? [
                                      BrainTheme.errorBrain.withOpacity(0.1),
                                      BrainTheme.errorBrain.withOpacity(0.05),
                                    ]
                                  : [
                                      BrainTheme.primaryBrain.withOpacity(0.1),
                                      BrainTheme.primaryBrain.withOpacity(0.05),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_reactionTime == -1
                                            ? BrainTheme.errorBrain
                                            : BrainTheme.primaryBrain)
                                        .withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _reactionTime == -1
                                        ? [
                                            BrainTheme.errorBrain,
                                            BrainTheme.errorBrain.withOpacity(
                                              0.8,
                                            ),
                                          ]
                                        : [
                                            BrainTheme.primaryBrain,
                                            BrainTheme.primaryBrain.withOpacity(
                                              0.8,
                                            ),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _reactionTime == -1
                                      ? Icons.error_outline
                                      : Icons.timer,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                              const Gap(16),
                              if (_reactionTime == -1) ...[
                                Text(
                                  'Neural Overload',
                                  style: BrainTheme.brainTitle.copyWith(
                                    fontSize: 18,
                                    color: BrainTheme.errorBrain,
                                  ),
                                ),
                                const Gap(6),
                                Text(
                                  'Wait for green to appear',
                                  textAlign: TextAlign.center,
                                  style: BrainTheme.brainSubtitle.copyWith(
                                    fontSize: 13,
                                    color: BrainTheme.errorBrain,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'Neural Response Time',
                                  style: BrainTheme.brainTitle.copyWith(
                                    fontSize: 16,
                                    color: BrainTheme.primaryBrain,
                                  ),
                                ),
                                const Gap(12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: BrainTheme.brainGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: BrainTheme.primaryBrain
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${_reactionTime}ms',
                                    style: BrainTheme.brainScore.copyWith(
                                      fontSize: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Gap(6),
                                Text(
                                  _getPerformanceText(_reactionTime!),
                                  style: BrainTheme.brainSubtitle.copyWith(
                                    fontSize: 12,
                                    color: BrainTheme.primaryBrain,
                                  ),
                                ),
                              ],
                              const Gap(20),
                              Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _reactionTime == -1
                                            ? [
                                                BrainTheme.errorBrain,
                                                BrainTheme.errorBrain
                                                    .withOpacity(0.8),
                                              ]
                                            : [
                                                BrainTheme.primaryBrain,
                                                BrainTheme.primaryBrain
                                                    .withOpacity(0.8),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (_reactionTime == -1
                                                      ? BrainTheme.errorBrain
                                                      : BrainTheme.primaryBrain)
                                                  .withOpacity(0.3),
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
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text('Try Again'),
                                    ),
                                  ),
                                  const Gap(12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _resetGame,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            BrainTheme.primaryBrain,
                                        side: BorderSide(
                                          color: BrainTheme.primaryBrain,
                                          width: 2,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('New Game'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const Gap(24),
                // Stats Bar
                GameScoreDisplay(
                  title: 'Performance Metrics',
                  scores: [
                    ScoreItem(
                      label: 'Best Time',
                      value: _highScore == null ? '--' : '${_highScore}ms',
                      icon: Icons.star,
                    ),
                    ScoreItem(
                      label: 'Tests Taken',
                      value: '$_totalTests',
                      icon: Icons.analytics,
                    ),
                    ScoreItem(
                      label: 'Average',
                      value: _averageTime == 0 ? '--' : '${_averageTime}ms',
                      icon: Icons.trending_up,
                    ),
                  ],
                  primaryColor: BrainTheme.primaryBrain,
                ),

                const Gap(24),
                // Leaderboard
                ReactionTimeLeaderboard(
                  showTitle: true,
                  maxItems: 5,
                  showLocalScores: true,
                ),

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
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _state = GameState.ready;
      _reactionTime = null;
    });
  }

  String _getPerformanceText(int reactionTime) {
    if (reactionTime < 200) return 'Neural Superhuman! 🧠⚡';
    if (reactionTime < 250) return 'Exceptional Processing! 🎯';
    if (reactionTime < 300) return 'Strong Neural Response! 👍';
    if (reactionTime < 400) return 'Average Cognitive Speed 📊';
    return 'Neural Training Needed 💪';
  }
}
