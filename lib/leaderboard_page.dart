import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/services/leaderboard_service.dart';
import 'package:human_benchmark/services/auth_service.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Leaderboard',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (AuthService.currentUser != null || true) _AuthButton(),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<UserScore>>(
                stream: LeaderboardService.topScores(limit: 10),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List<UserScore> scores = snapshot.data ?? const [];
                  if (scores.isEmpty) {
                    return Center(
                      child: Text(
                        'No scores yet. Be the first to play!',
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: scores.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final UserScore score = scores[index];
                      final int rank = index + 1;
                      return ListTile(
                        leading: _RankBadge(rank: rank),
                        title: Text(
                          'User ${score.userId.substring(0, score.userId.length > 6 ? 6 : score.userId.length)}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Last played: ${_formatDate(score.getLastPlayed(GameType.reactionTime) ?? DateTime.now())}',
                          style: GoogleFonts.montserrat(fontSize: 12),
                        ),
                        trailing: Text(
                          '${score.getHighScore(GameType.reactionTime)} ms',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    switch (rank) {
      case 1:
        bgColor = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        bgColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        bgColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        bgColor = Colors.grey.shade300;
    }
    return CircleAvatar(
      backgroundColor: bgColor,
      child: Text(
        '$rank',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = AuthService.currentUser;
        final bool signedIn = user != null;
        final String label = signedIn ? 'Sign out' : 'Sign in';

        return ElevatedButton.icon(
          onPressed: () async {
            try {
              if (signedIn) {
                await AuthService.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Signed out successfully')),
                );
              } else {
                // Show loading indicator
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Signing in...')));

                final result = await AuthService.signInWithGoogle();
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Signed in successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign in failed. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0074EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          icon: Icon(signedIn ? Icons.logout : Icons.login, size: 18),
          label: Text(
            signedIn ? (user?.displayName ?? 'Sign out') : label,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
