import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/components/web_banner_ad.dart';
// import 'package:human_benchmark/models/user_score.dart';
// import 'package:human_benchmark/services/leaderboard_service.dart';

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
    // Load best time from local storage or service
    // For now, we'll use a placeholder
    setState(() {
      _bestTime = 0;
    });
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

  void _onTap() {
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

    // Update best time if this is better
    if (_bestTime == 0 || reactionTime < _bestTime) {
      setState(() {
        _bestTime = reactionTime;
      });
      // Save best time
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
          // Header
          Text(
            'Reaction Time Test',
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Test your reflexes! Click when the screen turns green.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                      border: Border.all(color: Colors.grey[200]!),
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
                        border: Border.all(color: Colors.orange[200]!),
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
                                  color: Colors.green.withOpacity(0.3),
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
                      border: Border.all(
                        color: _reactionTime == -1
                            ? Colors.red[200]!
                            : Colors.blue[200]!,
                      ),
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
              border: Border.all(color: Colors.grey[200]!),
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
                    '${_times.length}',
                    Icons.analytics,
                    Colors.green[600]!,
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: _buildStatCard(
                    'Average',
                    _times.isEmpty
                        ? '--'
                        : '${(_times.reduce((a, b) => a + b) / _times.length).round()}ms',
                    Icons.trending_up,
                    Colors.blue[600]!,
                  ),
                ),
              ],
            ),
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
        border: Border.all(color: Colors.grey[200]!),
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
