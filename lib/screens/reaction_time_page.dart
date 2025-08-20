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

    if (kReleaseMode && _roundCounter % 5 == 0 && _isAdLoaded) {
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
                _buildPageHeader(),
                const Gap(24),
                Text(
                  'Test your reflexes! Tap when the screen turns green.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const Gap(32),

                // Game Area
                Center(
                  child: Column(
                    children: [
                      // Game Instructions
                      if (_state == GameState.ready)
                        Container(
                          padding: const EdgeInsets.all(24),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 48,
                                color: Colors.blue[400],
                              ),
                              const Gap(20),
                              Text(
                                'Tap Start to begin',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const Gap(12),
                              Text(
                                'Wait for the screen to turn green, then tap as fast as you can!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Gap(24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _startGame,
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
                                  child: const Text(
                                    'Start Test',
                                    style: TextStyle(fontSize: 16),
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
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.hourglass_empty,
                                  size: 48,
                                  color: Colors.orange[400],
                                ),
                                const Gap(20),
                                Text(
                                  'Wait for it...',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                const Gap(12),
                                Text(
                                  'The screen will turn green soon. Don\'t tap yet!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[600],
                                  ),
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
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'TAP NOW!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Results
                      if (_state == GameState.result)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _reactionTime == -1
                                ? Colors.red[50]
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                            border: _reactionTime == -1
                                ? Border.all(color: Colors.red[200]!)
                                : null,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _reactionTime == -1
                                    ? Icons.error_outline
                                    : Icons.timer,
                                size: 48,
                                color: _reactionTime == -1
                                    ? Colors.red[400]
                                    : Colors.blue[400],
                              ),
                              const Gap(20),
                              if (_reactionTime == -1) ...[
                                Text(
                                  'Game Over',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red[800],
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  'Wait for green to appear',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'Your Reaction Time',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const Gap(16),
                                Text(
                                  '${_reactionTime}ms',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                              const Gap(24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: _startGame,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _reactionTime == -1
                                          ? Colors.red[600]
                                          : Colors.blue[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Try Again'),
                                  ),
                                  OutlinedButton(
                                    onPressed: _resetGame,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('New Game'),
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Best Time',
                          _highScore == null ? '--' : '${_highScore}ms',
                          Icons.star,
                          Colors.amber[600]!,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Tests Taken',
                          '$_totalTests',
                          Icons.analytics,
                          Colors.green[600]!,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Average',
                          _averageTime == 0 ? '--' : '${_averageTime}ms',
                          Icons.trending_up,
                          Colors.blue[600]!,
                        ),
                      ),
                    ],
                  ),
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
          'Reaction Time',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _state = GameState.ready;
      _reactionTime = null;
    });
  }
}
