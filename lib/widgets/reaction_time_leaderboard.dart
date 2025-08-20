import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/score_service.dart';

import 'package:human_benchmark/models/user_score.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReactionTimeLeaderboard extends StatefulWidget {
  final bool showTitle;
  final int maxItems;
  final bool showLocalScores;

  const ReactionTimeLeaderboard({
    super.key,
    this.showTitle = true,
    this.maxItems = 10,
    this.showLocalScores = true,
  });

  @override
  State<ReactionTimeLeaderboard> createState() =>
      _ReactionTimeLeaderboardState();
}

class _ReactionTimeLeaderboardState extends State<ReactionTimeLeaderboard> {
  List<Map<String, dynamic>> _publicScores = [];
  bool _isLoadingPublic = true;

  @override
  void initState() {
    super.initState();
    _loadPublicScores();
  }

  Future<void> _loadPublicScores() async {
    try {
      // Try to get public leaderboard data
      final scores = await ScoreService.getReactionTimeLeaderboard(
        limit: widget.maxItems,
      );
      if (mounted) {
        setState(() {
          _publicScores = scores
              .map(
                (score) => {
                  'rank': 0, // Will be set below
                  'userName': score.userName ?? 'Player',
                  'time': score.getHighScore(GameType.reactionTime),
                  'userId': score.userId,
                },
              )
              .toList();

          // Sort by time (lower is better for reaction time) and assign ranks
          _publicScores.sort(
            (a, b) => (a['time'] as int).compareTo(b['time'] as int),
          );
          for (int i = 0; i < _publicScores.length; i++) {
            _publicScores[i]['rank'] = i + 1;
          }

          _isLoadingPublic = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPublic = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            Row(
              children: [
                Icon(Icons.leaderboard, color: Colors.blue[600], size: 24),
                const Gap(8),
                Text(
                  'Leaderboard',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadPublicScores,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const Gap(16),
          ],

          // Firebase Leaderboard (for logged-in users)
          StreamBuilder<User?>(
            stream: AuthService.authStateChanges,
            builder: (context, authSnapshot) {
              final isLoggedIn = authSnapshot.data != null;

              if (isLoggedIn) {
                return FutureBuilder<List<UserScore>>(
                  future: ScoreService.getReactionTimeLeaderboard(
                    limit: widget.maxItems,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState('Failed to load leaderboard');
                    }

                    final scores = snapshot.data ?? [];
                    if (scores.isEmpty) {
                      return _buildEmptyState('No scores yet. Be the first!');
                    }

                    return FutureBuilder<List<Widget>>(
                      future: Future.wait(
                        scores.asMap().entries.map((entry) async {
                          final index = entry.key;
                          final score = entry.value;
                          final reactionTime = score.getHighScore(
                            GameType.reactionTime,
                          );

                          // Get display name with fallback
                          final displayName =
                              score.userName ??
                              'Player ${score.userId.substring(0, 6)}';

                          return _buildLeaderboardRow(
                            rank: index + 1,
                            userName: displayName,
                            score: reactionTime,
                            isCurrentUser:
                                score.userId == AuthService.currentUser?.uid,
                          );
                        }),
                      ),
                      builder: (context, leaderboardSnapshot) {
                        if (leaderboardSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final leaderboardItems = leaderboardSnapshot.data ?? [];

                        return Column(
                          children: [
                            _buildLeaderboardHeader(),
                            const Gap(8),
                            ...leaderboardItems,
                          ],
                        );
                      },
                    );
                  },
                );
              } else {
                // Show public scores for non-logged-in users
                if (_isLoadingPublic) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (_publicScores.isEmpty) {
                  return Center(
                    child: _buildEmptyState('No public scores available yet.'),
                  );
                }

                return Column(
                  children: [
                    _buildLeaderboardHeader(),
                    const Gap(8),
                    ..._publicScores.map((score) {
                      return _buildLeaderboardRow(
                        rank: score['rank'],
                        userName: score['userName'],
                        score: score['time'],
                        isCurrentUser: false,
                        isLocal: false,
                      );
                    }),
                  ],
                );
              }
            },
          ),

          // Sign-in prompt for non-logged-in users
          StreamBuilder<User?>(
            stream: AuthService.authStateChanges,
            builder: (context, snapshot) {
              final isLoggedIn = snapshot.data != null;

              if (!isLoggedIn) {
                return Column(
                  children: [
                    const Gap(16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              'Sign in to compete on the global leaderboard and save your scores!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'Rank',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Player',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'Time',
              textAlign: TextAlign.right,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow({
    required int rank,
    required String userName,
    required int score,
    required bool isCurrentUser,
    bool isLocal = false,
  }) {
    Color rankColor = Colors.grey[600]!;
    IconData? rankIcon;

    // Special styling for top 3
    if (rank == 1) {
      rankColor = Colors.amber[600]!;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
      rankIcon = Icons.military_tech;
    } else if (rank == 3) {
      rankColor = Colors.orange[600]!;
      rankIcon = Icons.workspace_premium;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCurrentUser ? Colors.blue[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: [
                if (rankIcon != null) ...[
                  Icon(rankIcon, color: rankColor, size: 16),
                  const Gap(4),
                ],
                Text(
                  '$rank',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: rankColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  userName,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isCurrentUser ? Colors.blue[700] : Colors.grey[800],
                  ),
                ),
                if (isLocal) ...[
                  const Gap(4),
                  Icon(Icons.storage, size: 12, color: Colors.grey[500]),
                ],
                if (isCurrentUser) ...[
                  const Gap(4),
                  Text(
                    '(You)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '${score}ms',
              textAlign: TextAlign.right,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCurrentUser ? Colors.blue[700] : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey[400]),
          const Gap(8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const Gap(8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.red[600]),
          ),
        ],
      ),
    );
  }
}
