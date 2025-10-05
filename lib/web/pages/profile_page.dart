import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';
import 'package:human_benchmark/web/widgets/auth_required_wrapper.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/services/user_profile_service.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/models/game_score.dart';
import 'package:human_benchmark/models/user_profile.dart';
import 'package:human_benchmark/web/widgets/country_selector.dart';
import 'package:human_benchmark/web/constants/countries.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebProfilePage extends StatefulWidget {
  const WebProfilePage({super.key});

  @override
  State<WebProfilePage> createState() => _WebProfilePageState();
}

class _WebProfilePageState extends State<WebProfilePage> {
  UserScore? _userScore;
  UserProfile? _userProfile;
  List<GameScore> _recentActivities = [];
  bool _isLoading = true;
  bool _isLoadingActivities = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadRecentActivities();
    _loadUserProfileData();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userScore = await ScoreService.getUserScoreProfile();
      if (mounted) {
        setState(() {
          _userScore = userScore;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserProfileData() async {
    try {
      final userProfile = await UserProfileService.getOrCreateUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = userProfile;
        });
      }
    } catch (e) {
      // Ignore: non-critical for rendering
    }
  }

  Future<void> _showEditProfileDialog() async {
    if (_userProfile == null) return;

    final TextEditingController displayNameController = TextEditingController(
      text: _userProfile!.displayName ?? '',
    );
    final TextEditingController countryController = TextEditingController(
      text: _userProfile!.country ?? '',
    );
    DateTime? selectedBirthday = _userProfile!.birthday;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'Enter your display name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: WebTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const Gap(16),
                  CountrySelector(
                    initialValue: _userProfile!.country,
                    onCountrySelected: (String? country) {
                      // Update the country controller when a country is selected
                      if (country != null) {
                        countryController.text = country;
                      } else {
                        countryController.clear();
                      }
                    },
                  ),
                  const Gap(16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: const Text('Birthday'),
                      subtitle: Text(
                        selectedBirthday != null
                            ? '${selectedBirthday!.day}/${selectedBirthday!.month}/${selectedBirthday!.year}'
                            : 'Select your birthday',
                      ),
                      trailing: Icon(
                        Icons.calendar_today,
                        color: WebTheme.primaryBlue,
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedBirthday ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedBirthday = picked;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await UserProfileService.updateProfileFields(
                      uid: _userProfile!.uid,
                      displayName: displayNameController.text.isNotEmpty
                          ? displayNameController.text
                          : null,
                      birthday: selectedBirthday,
                      country: countryController.text.isNotEmpty
                          ? countryController.text
                          : null,
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                      _loadUserProfileData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update profile: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadRecentActivities() async {
    try {
      setState(() {
        _isLoadingActivities = true;
      });
      final activities = await ScoreService.getRecentActivities();
      if (mounted) {
        setState(() {
          _recentActivities = activities;
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load recent activities: $e';
          _isLoadingActivities = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthRequiredWrapper(
      title: 'Profile',
      subtitle:
          'Sign in to view and manage your profile, scores, and game statistics.',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _buildProfileContent(),
      ),
    );
  }

  // Removed unused _buildSignInPrompt

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const Gap(16),
          Text(
            'Error loading profile',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const Gap(8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final user = AuthService.currentUser;
    if (user == null) {
      return const Center(child: Text('No user found'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadUserProfile(),
          _loadRecentActivities(),
          _loadUserProfileData(),
        ]);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                PageHeader(
                  title: 'Profile',
                  subtitle: 'View your statistics and achievements.',
                ),
                const Gap(24),
                // Identity Block (avatar, name, country, age, joined)
                _buildIdentityBlock(user),
                const Gap(32),

                // Rank Block (global score + rank timeline)
                if (_userProfile != null) _buildRankBlock(),
                const Gap(32),

                // Per-game statistics cards
                if (_userScore != null) _buildPerGameStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityBlock(User user) {
    final String displayName =
        _userProfile?.displayName ?? user.displayName ?? 'User';
    final String? countryName = _userProfile?.country;
    final String countryFlag = countryName != null
        ? (Countries.findByName(countryName)?.flag ?? '')
        : '';
    final DateTime joinedAt =
        _userProfile?.createdAt ?? _userScore?.createdAt ?? DateTime.now();
    final int? age = _userProfile?.birthday != null
        ? _calculateAge(_userProfile!.birthday!)
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue[100],
            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                ? NetworkImage(user.photoURL!)
                : null,
            child: (user.photoURL == null || user.photoURL!.isEmpty)
                ? Icon(Icons.person, size: 40, color: Colors.blue[600])
                : null,
          ),
          const Gap(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Gap(6),
                if (user.email != null)
                  Text(user.email!, style: TextStyle(color: Colors.grey[600])),
                const Gap(12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (countryName != null)
                      _chip(
                        icon: Icons.flag,
                        label: '$countryFlag $countryName',
                      ),
                    if (age != null)
                      _chip(icon: Icons.cake, label: 'Age: $age'),
                    _chip(
                      icon: Icons.calendar_today,
                      label: 'Joined: ${_formatDate(joinedAt)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: WebTheme.primaryBlue),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildPerGameStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          SizedBox(
            height: 160,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    (_userProfile?.gameStats.keys.toList() ?? GameType.values)
                        .map((gameType) {
                          final int high =
                              _userScore?.getHighScore(gameType) ?? 0;
                          final int total =
                              _userScore?.getTotalGames(gameType) ?? 0;
                          final DateTime? last = _userScore?.getLastPlayed(
                            gameType,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Container(
                              width: 220,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getGameIcon(gameType),
                                        color: WebTheme.primaryBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _getGameName(gameType),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(12),
                                  _kv('High Score', '$high'),
                                  const Gap(6),
                                  _kv('Games Played', '$total'),
                                  if (last != null) ...[
                                    const Gap(6),
                                    _kv('Last Played', _formatDate(last)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBlock() {
    final int global = _userProfile?.globalScore ?? 0;
    final _RankInfo rank = _computeRank(global);
    final double progress = rank.progress;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: WebTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Global Rank',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Text(
                '${rank.name}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const Gap(12),
          _kv('Global Score', '$global'),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: WebTheme.primaryBlue,
              backgroundColor: Colors.grey[200],
            ),
          ),
          const Gap(16),
          // Make rank timeline horizontally scrollable (already scrolls),
          // and include a horizontal scrollable badge list of ranks for visibility
          SizedBox(height: 80, child: _rankTimeline(rankIndex: rank.index)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Expanded(
          child: Text(k, style: TextStyle(color: Colors.grey[600])),
        ),
        Text(
          v,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _rankTimeline({required int rankIndex}) {
    final ranks = _ranks();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(ranks.length, (i) {
          final active = i <= rankIndex;
          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? WebTheme.primaryBlue : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 100,
                    child: Column(
                      children: [
                        Text(
                          ranks[i].$1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: active ? Colors.grey[800] : Colors.grey[500],
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '≥ ${ranks[i].$2}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: active ? Colors.grey[700] : Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (i < ranks.length - 1)
                Container(
                  width: 48,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: i < rankIndex
                      ? WebTheme.primaryBlue
                      : Colors.grey[300],
                ),
            ],
          );
        }),
      ),
    );
  }

  int _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  _RankInfo _computeRank(int globalScore) {
    final ranks = _ranks();
    int idx = 0;
    for (int i = 0; i < ranks.length; i++) {
      if (globalScore >= ranks[i].$2) idx = i;
    }
    final int floor = ranks[idx].$2;
    final int ceil = idx + 1 < ranks.length ? ranks[idx + 1].$2 : floor + 1;
    final double progress = (globalScore - floor) / (ceil - floor);
    return _RankInfo(
      name: ranks[idx].$1,
      index: idx,
      progress: progress.clamp(0, 1),
    );
  }

  IconData _getGameIcon(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return Icons.timer;
      case GameType.numberMemory:
        return Icons.memory;
      case GameType.personalityQuiz:
        return Icons.psychology;
      case GameType.decisionRisk:
        return Icons.speed;
      case GameType.visualMemory:
        return Icons.visibility;
      case GameType.verbalMemory:
        return Icons.record_voice_over;
      case GameType.aimTrainer:
        return Icons.gps_fixed;
      case GameType.sequenceMemory:
        return Icons.format_list_numbered;
      case GameType.chimpTest:
        return Icons.pets;
      default:
        return Icons.games;
    }
  }

  String _getGameName(GameType gameType) {
    switch (gameType) {
      case GameType.reactionTime:
        return 'Reaction Time';
      case GameType.numberMemory:
        return 'Number Memory';
      case GameType.personalityQuiz:
        return 'Personality Quiz';
      case GameType.decisionRisk:
        return 'Decision Making';
      case GameType.visualMemory:
        return 'Visual Memory';
      case GameType.verbalMemory:
        return 'Verbal Memory';
      case GameType.aimTrainer:
        return 'Aim Trainer';
      case GameType.sequenceMemory:
        return 'Sequence Memory';
      case GameType.chimpTest:
        return 'Chimp Test';
      default:
        return 'Unknown Game';
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
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Returns list of (name, threshold)
  List<(String, int)> _ranks() {
    return [
      ('Novice Neuron', 0),
      ('Quick Learner', 500),
      ('Pattern Seeker', 1200),
      ('Recall Rookie', 2000),
      ('Focus Finder', 3000),
      ('Mind Sprinter', 4200),
      ('Cortex Challenger', 5600),
      ('Synapse Master', 7200),
      ('Cognitive Elite', 9000),
      ('Benchmark Legend', 11000),
    ];
  }
}

class _RankInfo {
  final String name;
  final int index;
  final double progress;
  _RankInfo({required this.name, required this.index, required this.progress});
}
