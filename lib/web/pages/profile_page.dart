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
  bool _isLoadingProfile = true;
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
      setState(() {
        _isLoadingProfile = true;
      });

      final userProfile = await UserProfileService.getOrCreateUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
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
        backgroundColor: WebTheme.grey50,
        body: _buildProfileContent(),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 80, color: WebTheme.primaryBlue),
              const Gap(24),
              Text(
                'Sign in to view profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              Text(
                'Please sign in to see your statistics and achievements.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WebTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final cred = await AuthService.signInWithGoogle();
                    if (mounted && cred != null) {
                      _loadUserProfile();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                PageHeader(
                  title: 'Profile',
                  subtitle: 'View your statistics and achievements.',
                ),

                // Profile Header
                _buildProfileHeader(user),
                const Gap(32),

                // Statistics Overview
                if (_userScore != null) _buildStatisticsOverview(),
                const Gap(32),

                // Game Performance
                if (_userScore != null) _buildGamePerformance(),
                const Gap(32),

                // Recent Activity
                if (_userScore != null) _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue[100],
            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null || user.photoURL!.isEmpty
                ? Icon(Icons.person, size: 50, color: Colors.blue[600])
                : null,
          ),
          const Gap(24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _userProfile?.displayName ?? user.displayName ?? 'User',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WebTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  user.email ?? 'No email',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                if (_userProfile?.country != null) ...[
                  const Gap(4),
                  Row(
                    children: [
                      Text(
                        'Country: ',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      Text(
                        Countries.findByName(_userProfile!.country!)?.flag ??
                            '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Gap(4),
                      Text(
                        _userProfile!.country!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
                if (_userProfile?.birthday != null) ...[
                  const Gap(4),
                  Text(
                    'Birthday: ${_formatDate(_userProfile!.birthday!)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
                if (_userScore != null) ...[
                  const Gap(12),
                  Text(
                    'Member since ${_formatDate(_userScore!.createdAt)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsOverview() {
    final overallScore = _userScore!.overallScore;
    final totalGames = _userScore!.totalGamesPlayedOverall;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Overall Score',
                  overallScore.toString(),
                  Icons.star,
                  Colors.amber[600]!,
                ),
              ),
              const Gap(24),
              Expanded(
                child: _buildStatCard(
                  'Total Games',
                  totalGames.toString(),
                  Icons.games,
                  Colors.blue[600]!,
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const Gap(16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(8),
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGamePerformance() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Performance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: GameType.values.map((gameType) {
              final highScore = _userScore!.getHighScore(gameType);
              final gamesPlayed = _userScore!.totalGamesPlayed[gameType] ?? 0;
              final lastPlayed = _userScore!.lastPlayedAt[gameType];

              if (gamesPlayed == 0) return const SizedBox.shrink();

              return Container(
                width: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
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
                          size: 24,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            _getGameName(gameType),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Text(
                      'Best Score: $highScore',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: WebTheme.primaryBlue,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Games Played: $gamesPlayed',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (lastPlayed != null) ...[
                      const Gap(8),
                      Text(
                        'Last played: ${_formatDate(lastPlayed)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(24),
          if (_isLoadingActivities)
            const Center(child: CircularProgressIndicator())
          else if (_recentActivities.isEmpty)
            Text(
              'No recent activities found.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivities.length,
              itemBuilder: (context, index) {
                final activity = _recentActivities[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getGameIcon(activity.gameType),
                          color: WebTheme.primaryBlue,
                          size: 24,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGameName(activity.gameType),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const Gap(4),
                              Text(
                                'Score: ${activity.score}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Gap(4),
                              Text(
                                'Date: ${_formatDateTime(activity.playedAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
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
}
