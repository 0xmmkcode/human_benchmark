import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/settings_service.dart';
import 'package:human_benchmark/models/personality_result.dart';
import 'package:human_benchmark/repositories/personality_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonalityLeaderboard extends StatefulWidget {
  final bool showTitle;
  final int maxItems;
  final String? selectedTrait;

  const PersonalityLeaderboard({
    super.key,
    this.showTitle = true,
    this.maxItems = 10,
    this.selectedTrait,
  });

  @override
  State<PersonalityLeaderboard> createState() => _PersonalityLeaderboardState();
}

class _PersonalityLeaderboardState extends State<PersonalityLeaderboard> {
  List<PersonalityResult> _personalityResults = [];
  bool _isLoading = true;
  String? _selectedTrait;
  final List<String> _traits = [
    'Openness',
    'Conscientiousness',
    'Extraversion',
    'Agreeableness',
    'Neuroticism',
  ];
  final PersonalityRepository _repository = PersonalityRepository();

  @override
  void initState() {
    super.initState();
    _selectedTrait = widget.selectedTrait ?? _traits.first;
    _loadPersonalityResults();
  }

  Future<void> _loadPersonalityResults() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await _repository.getTopResults(
        trait: _selectedTrait!,
        limit: widget.maxItems,
      );
      
      if (mounted) {
        setState(() {
          _personalityResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load leaderboard: $e')),
        );
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
                Icon(Icons.psychology, color: Colors.purple[600], size: 24),
                const Gap(8),
                Text(
                  'Personality Leaderboard',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadPersonalityResults,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const Gap(16),
          ],

          // Trait Selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Text(
                  'Trait: ',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedTrait,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _traits.map((trait) {
                      return DropdownMenuItem<String>(
                        value: trait,
                        child: Text(
                          trait,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedTrait = newValue);
                        _loadPersonalityResults();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),

          // Leaderboard Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_personalityResults.isEmpty)
            _buildEmptyState('No personality results yet. Take the test to see your ranking!')
          else
            Column(
              children: [
                _buildLeaderboardHeader(),
                const Gap(8),
                ..._personalityResults.asMap().entries.map((entry) {
                  final index = entry.key;
                  final result = entry.value;
                  return _buildLeaderboardRow(
                    rank: index + 1,
                    userName: result.userName ?? 'Anonymous',
                    score: result.getTraitScore(_selectedTrait!),
                    percentile: result.getTraitPercentile(_selectedTrait!),
                    isCurrentUser: result.userId == AuthService.currentUser?.uid,
                  );
                }),
              ],
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
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.purple[600],
                            size: 20,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              'Sign in to see your personality ranking and compete with others!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.purple[700],
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
              'Score',
              textAlign: TextAlign.right,
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
              'Percentile',
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
    required double score,
    required double percentile,
    required bool isCurrentUser,
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
        color: isCurrentUser ? Colors.purple[50] : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCurrentUser ? Colors.purple[200]! : Colors.grey[200]!,
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
                    color: isCurrentUser ? Colors.purple[700] : Colors.grey[800],
                  ),
                ),
                if (isCurrentUser) ...[
                  const Gap(4),
                  Text(
                    '(You)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple[600],
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
              score.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCurrentUser ? Colors.purple[700] : Colors.grey[800],
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '${percentile.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCurrentUser ? Colors.purple[700] : Colors.grey[800],
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
          Icon(Icons.psychology_outlined, size: 48, color: Colors.grey[400]),
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
}
