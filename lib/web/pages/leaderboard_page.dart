import 'package:flutter/material.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/services/leaderboard_service.dart';
import 'package:human_benchmark/screens/comprehensive_leaderboard_page.dart';

class WebLeaderboardPage extends StatefulWidget {
  @override
  _WebLeaderboardPageState createState() => _WebLeaderboardPageState();
}

class _WebLeaderboardPageState extends State<WebLeaderboardPage> {
  List<UserScore> _scores = [];
  bool _isLoading = true;
  String _selectedCategory = 'reaction_time';
  String _selectedTimeFrame = 'all_time';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the static method from LeaderboardService
      final scoresStream = LeaderboardService.topScores(limit: 50);
      await for (final scores in scoresStream) {
        setState(() {
          _scores = scores;
          _isLoading = false;
        });
        break; // Take the first emission
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Leaderboard',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'See how you rank against the best players',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          // Navigation to comprehensive leaderboard
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ComprehensiveLeaderboardPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.leaderboard, size: 20),
                label: Text(
                  'View Comprehensive Leaderboard',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 40),

          // Filters
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Category Filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'reaction_time',
                            child: Text('Reaction Time'),
                          ),
                          DropdownMenuItem(
                            value: 'memory',
                            child: Text('Memory'),
                          ),
                          DropdownMenuItem(
                            value: 'typing',
                            child: Text('Typing Speed'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                          _loadLeaderboard();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 24),

                // Time Frame Filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Frame',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedTimeFrame,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all_time',
                            child: Text('All Time'),
                          ),
                          DropdownMenuItem(
                            value: 'this_month',
                            child: Text('This Month'),
                          ),
                          DropdownMenuItem(
                            value: 'this_week',
                            child: Text('This Week'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTimeFrame = value!;
                          });
                          _loadLeaderboard();
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 24),

                // Refresh Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loadLeaderboard,
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Leaderboard Content
          // Content area (no Expanded inside scroll view)
          _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[600]!,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading leaderboard...',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : _scores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.leaderboard_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No scores yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Be the first to set a record!',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                'Rank',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Player ID',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Score',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Date',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scores List
                      SizedBox(
                        height: 600,
                        child: ListView.builder(
                          itemCount: _scores.length,
                          itemBuilder: (context, index) {
                            final score = _scores[index];
                            final isTop3 = index < 3;

                            return Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isTop3
                                    ? _getTop3Color(index)
                                    : Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[100]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Rank
                                  SizedBox(
                                    width: 60,
                                    child: Row(
                                      children: [
                                        if (isTop3) ...[
                                          Icon(
                                            _getTop3Icon(index),
                                            color: _getTop3IconColor(index),
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                        ],
                                        Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isTop3
                                                ? Colors.white
                                                : Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Player ID
                                  Expanded(
                                    child: Text(
                                      score.userId,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: isTop3
                                            ? Colors.white
                                            : Colors.grey[800],
                                      ),
                                    ),
                                  ),

                                  // Score
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '${score.getHighScore(GameType.reactionTime)}ms',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isTop3
                                            ? Colors.white
                                            : Colors.blue[600],
                                      ),
                                    ),
                                  ),

                                  // Date
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      _formatDate(
                                        score.getLastPlayed(
                                              GameType.reactionTime,
                                            ) ??
                                            DateTime.now(),
                                      ),
                                      style: TextStyle(
                                        color: isTop3
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Color _getTop3Color(int index) {
    switch (index) {
      case 0:
        return Colors.amber[600]!;
      case 1:
        return Colors.grey[400]!;
      case 2:
        return Colors.orange[600]!;
      default:
        return Colors.white;
    }
  }

  IconData _getTop3Icon(int index) {
    switch (index) {
      case 0:
        return Icons.emoji_events;
      case 1:
        return Icons.workspace_premium;
      case 2:
        return Icons.military_tech;
      default:
        return Icons.star;
    }
  }

  Color _getTop3IconColor(int index) {
    switch (index) {
      case 0:
        return Colors.yellow[100]!;
      case 1:
        return Colors.white;
      case 2:
        return Colors.orange[100]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
