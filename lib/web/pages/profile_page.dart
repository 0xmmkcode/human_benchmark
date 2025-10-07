import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:human_benchmark/web/widgets/app_loading.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';
import 'package:human_benchmark/web/widgets/auth_required_wrapper.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/services/user_profile_service.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/models/user_profile.dart';
import 'package:human_benchmark/models/rank.dart';
import 'package:human_benchmark/services/rank_service.dart';
import 'package:human_benchmark/utils/rank_image_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/user_avatar.dart';

class WebProfilePage extends StatefulWidget {
  const WebProfilePage({super.key});

  @override
  State<WebProfilePage> createState() => _WebProfilePageState();
}

class _WebProfilePageState extends State<WebProfilePage> {
  UserScore? _userScore;
  UserProfile? _userProfile;
  List<Rank> _ranks = [];
  bool _isLoadingRanks = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserProfileData();
    _loadRanks();
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
        // nothing extra
      }
    } catch (e) {
      // Ignore: non-critical for rendering
    }
  }

  Future<void> _loadRanks() async {
    try {
      setState(() {
        _isLoadingRanks = true;
      });

      print('🔄 Loading ranks from Firestore...');
      final ranks = await RankService.getAllRanks();
      print('✅ Loaded ${ranks.length} ranks from Firestore');

      ranks.sort((a, b) => a.order.compareTo(b.order));

      if (mounted) {
        setState(() {
          _ranks = ranks;
          _isLoadingRanks = false;
        });
        print('✅ Ranks state updated: ${_ranks.length} ranks');
      }
    } catch (e) {
      print('❌ Error loading ranks: $e');
      if (mounted) {
        setState(() {
          _isLoadingRanks = false;
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
      return const Center(child: AppLoading());
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
          _loadUserProfileData(),
          _loadRanks(),
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

                // Your Rank
                if (_ranks.isNotEmpty && _userProfile != null)
                  _buildYourRankSection(),
                if (_ranks.isNotEmpty && _userProfile != null) const Gap(32),

                // Milestones (Ranks)
                if (_isLoadingRanks)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: AppLoading()),
                  ),
                if (_isLoadingRanks) const Gap(32),
                if (_ranks.isNotEmpty) _buildMilestones(),
                if (_ranks.isNotEmpty) const Gap(32),

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
    final String countryFlag = '';
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
          UserAvatar(
            radius: 40,
            photoURL: user.photoURL,
            displayName: _userProfile?.displayName ?? user.displayName,
            email: user.email,
            borderColor: Colors.blue[200],
            borderWidth: 2,
          ),
          const Gap(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _showEditProfileDialog,
                      icon: Icon(Icons.edit, color: Colors.grey[600]),
                      tooltip: 'Edit Profile',
                    ),
                  ],
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

  Widget _buildMilestones() {
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
            'All Ranks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _ranks.map((rank) {
                final imagePath = RankImageMapper.getImagePath(rank.order);
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                imagePath,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rank.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Text(
                          rank.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(8),
                        _kv(
                          'Score Range',
                          '${rank.minGlobalScore} - ${rank.maxGlobalScore}',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourRankSection() {
    final info = _getCurrentRankInfo();
    if (info == null) return const SizedBox.shrink();

    final Rank current = info['current'] as Rank;
    final Rank? next = info['next'] as Rank?;
    final double progress = info['progress'] as double;
    final int pointsToNext = info['pointsToNext'] as int;
    final int global = _userProfile?.globalScore ?? 0;
    final imagePath = RankImageMapper.getImagePath(current.order);

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
            'Your Rank',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      current.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'Score: $global',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          if (next != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                color: Colors.amber[600],
                backgroundColor: Colors.grey[200],
              ),
            ),
            const Gap(8),
            Text(
              '$pointsToNext points to ${next.name}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: WebTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Max Rank Achieved',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _EditProfileDialog(
        userProfile: _userProfile,
        onSave: _updateUserProfile,
      ),
    );
  }

  Future<void> _updateUserProfile(UserProfile updatedProfile) async {
    try {
      await UserProfileService.updateUserProfile(updatedProfile);

      if (mounted) {
        setState(() {
          _userProfile = updatedProfile;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic>? _getCurrentRankInfo() {
    if (_userProfile == null || _ranks.isEmpty) return null;
    final int score = _userProfile!.globalScore;
    if (_ranks.length > 1) {
      _ranks.sort((a, b) => a.order.compareTo(b.order));
    }

    Rank? current;
    Rank? next;
    for (int i = 0; i < _ranks.length; i++) {
      final r = _ranks[i];
      if (r.qualifiesForRank(score)) {
        current = r;
        if (i + 1 < _ranks.length) {
          next = _ranks[i + 1];
        }
        break;
      }
    }

    if (current == null) {
      // If below first rank, treat first as next
      if (score < _ranks.first.minGlobalScore) {
        next = _ranks.first;
        return {
          'current': _ranks.first,
          'next': next,
          'progress': 0.0,
          'pointsToNext': next.minGlobalScore - score,
        };
      }
      return null;
    }

    final double progress = current.calculateProgress(score);
    final int pointsToNext = next != null ? (next.minGlobalScore - score) : 0;

    return {
      'current': current,
      'next': next,
      'progress': progress,
      'pointsToNext': pointsToNext,
    };
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

  // Ranks timeline removed

  int _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  // (removed) _getRankIcon no longer used; rank images are shown instead

  // Rank helpers removed

  // Debug section for troubleshooting (only in debug mode)
  Widget _buildDebugSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🐛 Debug Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          const Gap(8),
          Text('Loading Ranks: $_isLoadingRanks'),
          Text('Ranks Count: ${_ranks.length}'),
          Text('User Profile: ${_userProfile != null}'),
          Text('Global Score: ${_userProfile?.globalScore ?? 'N/A'}'),
          const Gap(8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loadRanks,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload Ranks'),
              ),
            ],
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
}

class _EditProfileDialog extends StatefulWidget {
  final UserProfile? userProfile;
  final Function(UserProfile) onSave;

  const _EditProfileDialog({required this.userProfile, required this.onSave});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameController;
  String? _selectedCountry;
  DateTime? _selectedBirthday;
  bool _isLoading = false;

  // List of countries
  static const List<String> _countries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahrain',
    'Bangladesh',
    'Belarus',
    'Belgium',
    'Brazil',
    'Bulgaria',
    'Cambodia',
    'Canada',
    'Chile',
    'China',
    'Colombia',
    'Croatia',
    'Czech Republic',
    'Denmark',
    'Egypt',
    'Estonia',
    'Finland',
    'France',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kuwait',
    'Latvia',
    'Lebanon',
    'Lithuania',
    'Luxembourg',
    'Malaysia',
    'Mexico',
    'Morocco',
    'Netherlands',
    'New Zealand',
    'Nigeria',
    'Norway',
    'Oman',
    'Pakistan',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Saudi Arabia',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'South Africa',
    'South Korea',
    'Spain',
    'Sri Lanka',
    'Sweden',
    'Switzerland',
    'Thailand',
    'Turkey',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Vietnam',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userProfile?.displayName ?? '',
    );
    _selectedCountry = widget.userProfile?.country;
    _selectedBirthday = widget.userProfile?.birthday;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 500,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[200]!.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          WebTheme.primaryBlue.withOpacity(0.1),
                          Colors.grey[50]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: WebTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: WebTheme.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: Colors.grey[600]),
                            tooltip: 'Close',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Required fields note
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'All fields marked with * are required. You must be at least 13 years old to use this app.',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Name field
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Display Name *',
                            hintText: 'Enter your display name',
                            prefixIcon: Icon(
                              Icons.person,
                              color: WebTheme.primaryBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
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
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            helperText: 'This will be visible to other users',
                            helperStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Country dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedCountry,
                          decoration: InputDecoration(
                            labelText: 'Country *',
                            hintText: 'Select your country',
                            prefixIcon: Icon(
                              Icons.public,
                              color: WebTheme.primaryBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
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
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            helperText: 'Required for age verification',
                            helperStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          items: _countries.map((country) {
                            return DropdownMenuItem(
                              value: country,
                              child: Text(
                                country,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCountry = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Birthday field
                        InkWell(
                          onTap: _selectBirthday,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Birthday *',
                              hintText: 'Select your birthday',
                              prefixIcon: Icon(
                                Icons.cake,
                                color: WebTheme.primaryBlue,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: WebTheme.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              helperText: 'You must be at least 13 years old',
                              helperStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            child: Text(
                              _selectedBirthday != null
                                  ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                                  : 'Select your birthday',
                              style: TextStyle(
                                color: _selectedBirthday != null
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
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
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    // Validate all required fields
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCountry == null || _selectedCountry!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Country is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedBirthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Birthday is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate age (must be at least 13 years old)
    final age = _calculateAge(_selectedBirthday!);
    if (age < 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be at least 13 years old to use this app'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if display name already exists (only if it's different from current)
    final currentDisplayName = widget.userProfile?.displayName;
    final newDisplayName = _nameController.text.trim();

    if (newDisplayName != currentDisplayName) {
      final isNameTaken = await _checkDisplayNameExists(newDisplayName);
      if (isNameTaken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This display name is already taken. Please choose another one.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile = widget.userProfile?.copyWith(
        displayName: newDisplayName,
        country: _selectedCountry,
        birthday: _selectedBirthday,
        updatedAt: DateTime.now(),
      );

      if (updatedProfile == null) {
        throw Exception('Failed to create updated profile');
      }

      await widget.onSave(updatedProfile);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Future<bool> _checkDisplayNameExists(String displayName) async {
    try {
      // Query Firestore to check if display name exists
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_profiles')
          .where('displayName', isEqualTo: displayName)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // If there's an error checking, assume it's available to avoid blocking users
      print('Error checking display name availability: $e');
      return false;
    }
  }
}
