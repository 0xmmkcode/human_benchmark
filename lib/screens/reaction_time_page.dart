import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:human_benchmark/ad_helper.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/services/local_storage_service.dart';
import 'package:human_benchmark/services/auth_service.dart';

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
  bool _isLoadingStats = true;
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
        _isLoadingStats = true;
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
              _isLoadingStats = false;
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
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading reaction time stats: $e');
      // Set default values on error
      setState(() {
        _totalTests = 0;
        _averageTime = 0;
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String message = '';
    Color bgColor = backgroundColor;

    switch (_state) {
      case GameState.ready:
        message = 'Tap to Start';
        break;
      case GameState.waiting:
        message = 'Wait for Green...';
        bgColor = Colors.red;
        break;
      case GameState.go:
        message = 'TAP NOW!';
        bgColor = Colors.green;
        break;
      case GameState.result:
        if (_reactionTime == -1) {
          message = 'Game Over\nWait for green to appear\nTap to try again';
          bgColor = Colors.red.shade900;
        } else {
          message = 'Your Reaction Time: $_reactionTime ms\nTap to Retry';
          bgColor = Colors.blueGrey;
        }
        break;
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          return SafeArea(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_state == GameState.ready) {
                      _startGame();
                    } else {
                      _onScreenTap();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 70,
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    decoration: BoxDecoration(color: bgColor),
                    height: constraints.maxHeight * 0.8,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/human_logo_white.png",
                              height: 40,
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    "assets/images/trophy-star.png",
                                    height: 30,
                                  ),
                                  Gap(10),
                                  Text(
                                    '${_highScore ?? "--"} ms',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!_isLoadingStats) ...[
                          Gap(10),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_arrow,
                                      size: 16,
                                      color: Colors.blue.shade600,
                                    ),
                                    Gap(4),
                                    Text(
                                      'Tests: $_totalTests',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        color: Colors.blue.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Gap(8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      size: 16,
                                      color: Colors.green.shade600,
                                    ),
                                    Gap(4),
                                    Text(
                                      'Avg: ${_averageTime}ms',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        color: Colors.green.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Banner Ad
                      // Banner Ad
                      if (kReleaseMode && _isBannerAdReady && _bannerAd != null)
                        SizedBox(
                          height: _bannerAd!.size.height.toDouble(),
                          width: _bannerAd!.size.width.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
