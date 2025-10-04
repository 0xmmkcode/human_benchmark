import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/components/web_banner_ad.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/services/local_storage_service.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/widgets/reaction_time_leaderboard.dart';

class WebReactionTimePage extends StatefulWidget {
  @override
  _WebReactionTimePageState createState() => _WebReactionTimePageState();
}

class _WebReactionTimePageState extends State<WebReactionTimePage>
    with TickerProviderStateMixin {
  bool _isWaiting = false;
  bool _isGreen = false;
  bool _isGameOver = false;
  int _reactionTime = 0;
  int _bestTime = 0;
  List<int> _times = [];
  int _firebaseTotalTests = 0;
  int _firebaseAverage = 0;
  DateTime? _startTime;
  late AnimationController _colorController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _loadBestTime();
  }

  @override
  void dispose() {
    _colorController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadBestTime() async {
    final bestTime = await LocalStorageService.getBestTime();
    setState(() {
      _bestTime = bestTime ?? 0;
    });
    // Load previous local times to compute average/tests for the session
    final localTimes = await LocalStorageService.getTimesList();
    if (mounted) {
      setState(() {
        _times = List<int>.from(localTimes);
      });
    }
    // If logged in, also fetch Firebase reaction stats
    if (AuthService.currentUser != null) {
      try {
        final stats = await ScoreService.getReactionTimeStats();
        if (mounted && stats.isNotEmpty) {
          setState(() {
            _firebaseTotalTests = (stats['totalGames'] as num?)?.toInt() ?? 0;
            _firebaseAverage = (stats['averageScore'] as num?)?.round() ?? 0;
          });
        }
      } catch (_) {}
    }
  }

  void _startGame() {
    setState(() {
      _isWaiting = true;
      _isGreen = false;
      _isGameOver = false;
      _reactionTime = 0;
    });

    // Random delay between 1-5 seconds
    final randomDelay = Duration(
      milliseconds: 1000 + (DateTime.now().millisecondsSinceEpoch % 4000),
    );

    Future.delayed(randomDelay, () {
      if (mounted && _isWaiting) {
        setState(() {
          _isGreen = true;
          _startTime = DateTime.now();
        });
        _colorController.forward();
        _scaleController.forward();
      }
    });
  }

  Future<void> _onTap() async {
    if (!_isGreen || _isGameOver) return;

    final endTime = DateTime.now();
    final reactionTime = endTime.difference(_startTime!).inMilliseconds;

    setState(() {
      _reactionTime = reactionTime;
      _times.add(reactionTime);
      _isGameOver = true;
      _isGreen = false;
      _isWaiting = false; // hide "Wait for it" when showing result
    });

    _colorController.reverse();
    _scaleController.reverse();

    // Always save to local storage
    await LocalStorageService.addTime(reactionTime);

    // Always save score to Firebase if user is logged in - updates counter and average
    if (AuthService.currentUser != null) {
      try {
        await ScoreService.submitGameScore(
          gameType: 'reaction_time',
          score: reactionTime,
          additionalData: {
            'times': _times,
            'bestTime': _bestTime,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );

        // Refresh Firebase stats to show updated counter and average
        final stats = await ScoreService.getReactionTimeStats();
        if (mounted && stats.isNotEmpty) {
          setState(() {
            _firebaseTotalTests =
                (stats['totalGames'] as num?)?.toInt() ?? _firebaseTotalTests;
            _firebaseAverage =
                (stats['averageScore'] as num?)?.round() ?? _firebaseAverage;
          });
        }
      } catch (e) {
        // Log error but don't break the game
        print('Failed to save score to Firebase: $e');
      }
    }

    // Update best time if this is better - only update best score when actually better
    if (_bestTime == 0 || reactionTime < _bestTime) {
      setState(() {
        _bestTime = reactionTime;
      });

      // Save best time to local storage
      await LocalStorageService.saveBestTime(reactionTime);
    }
  }

  void _resetGame() {
    setState(() {
      _isWaiting = false;
      _isGreen = false;
      _isGameOver = false;
      _reactionTime = 0;
    });
    _colorController.reset();
    _scaleController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          PageHeader(
            title: 'Reaction Time Test',
            subtitle: 'Test your reflexes! Click when the screen turns green.',
          ),
          SizedBox(height: 40),

          // Game Area (scroll-friendly, no Expanded)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game Instructions
                if (!_isWaiting && !_isGreen && !_isGameOver)
                  Container(
                    padding: EdgeInsets.all(32),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 64,
                          color: Colors.blue[400],
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Click Start to begin',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Wait for the screen to turn green, then click as fast as you can!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Start Test',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        WebBannerAd(height: 90),
                      ],
                    ),
                  ),

                // Waiting State
                if (_isWaiting && !_isGreen)
                  GestureDetector(
                    onTapDown: (_) {
                      // Too early -> game over
                      setState(() {
                        _isGameOver = true;
                        _isWaiting = false;
                        _isGreen = false;
                        _reactionTime = -1;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 64,
                            color: Colors.orange[400],
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Wait for it...',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'The screen will turn green soon. Don\'t click yet!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          WebBannerAd(height: 90),
                        ],
                      ),
                    ),
                  ),

                // Game Area (Green Screen)
                if (_isGreen)
                  GestureDetector(
                    onTapDown: (_) => _onTap(),
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 400,
                            height: 300,
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
                            child: Center(
                              child: Text(
                                'CLICK NOW!',
                                style: TextStyle(
                                  fontSize: 32,
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

                // Results
                if (_isGameOver)
                  Container(
                    padding: EdgeInsets.all(32),
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
                          size: 64,
                          color: _reactionTime == -1
                              ? Colors.red[400]
                              : Colors.blue[400],
                        ),
                        SizedBox(height: 24),
                        if (_reactionTime == -1) ...[
                          Text(
                            'Game Over',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.red[800],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Wait for green to appear',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red[600],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Your Reaction Time',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '${_reactionTime}ms',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          // Show user's score profile
                          // TODO: Re-enable score display widget once ScoreDisplay is available
                          // FutureBuilder<UserScore?>(
                          //   future: ScoreService.getUserScoreProfile(),
                          //   builder: (context, snapshot) {
                          //     if (snapshot.connectionState ==
                          //         ConnectionState.waiting) {
                          //       return SizedBox(
                          //         height: 100,
                          //         child: Center(
                          //           child: CircularProgressIndicator(),
                          //         ),
                          //       );
                          //     }

                          //     if (snapshot.hasData && snapshot.data != null) {
                          //       return ScoreDisplay(
                          //         userScore: snapshot.data,
                          //         currentGame: GameType.reactionTime,
                          //         onViewLeaderboard: () {
                          //           Navigator.push(
                          //             context,
                          //             MaterialPageRoute(
                          //               builder: (context) =>
                          //                   const ComprehensiveLeaderboardPage(),
                          //             ),
                          //           );
                          //         },
                          //       );
                          //     }

                          //     return SizedBox.shrink();
                          //   },
                          // ),
                        ],
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _startGame,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _reactionTime == -1
                                    ? Colors.red[600]
                                    : Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Try Again'),
                            ),
                            SizedBox(width: 16),
                            OutlinedButton(
                              onPressed: _resetGame,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('New Game'),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        WebBannerAd(height: 90),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Gap(30),
          // Stats Bar
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Best Time',
                    _bestTime == 0 ? '--' : '${_bestTime}ms',
                    Icons.star,
                    Colors.amber[600]!,
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: _buildStatCard(
                    'Tests Taken',
                    AuthService.currentUser != null
                        ? (_firebaseTotalTests == 0
                              ? '${_times.length}'
                              : '$_firebaseTotalTests')
                        : '${_times.length}',
                    Icons.analytics,
                    Colors.green[600]!,
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: _buildStatCard(
                    'Average',
                    AuthService.currentUser != null
                        ? (_firebaseAverage == 0
                              ? (_times.isEmpty
                                    ? '--'
                                    : '${(_times.reduce((a, b) => a + b) / _times.length).round()}ms')
                              : '${_firebaseAverage}ms')
                        : (_times.isEmpty
                              ? '--'
                              : '${(_times.reduce((a, b) => a + b) / _times.length).round()}ms'),
                    Icons.trending_up,
                    Colors.blue[600]!,
                  ),
                ),
              ],
            ),
          ),

          Gap(30),
          // Leaderboard
          const ReactionTimeLeaderboard(
            showTitle: true,
            maxItems: 10,
            showLocalScores: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
