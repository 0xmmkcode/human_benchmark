import 'package:flutter/material.dart';
import 'package:human_benchmark/web/utils/web_utils.dart';
import 'package:human_benchmark/web/components/web_navigation_item.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/services/admin_service.dart';
import 'package:human_benchmark/services/game_management_service.dart';
import 'package:human_benchmark/models/game_management.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final VoidCallback? onBackToLanding;

  const WebSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.onBackToLanding,
  }) : super(key: key);

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  bool _isAdmin = false;
  bool _isLoadingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await AdminService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
        _isLoadingAdmin = false;
      });
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isLoadingAdmin = false;
      });
    }
  }

  int _getGameIndex(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return 0;
      case 'personality_quiz':
        return 2;
      case 'decision_making':
        return 3;
      case 'number_memory':
        return 4;
      default:
        return -1; // No specific index for this game
    }
  }

  String _getGameSubtitle(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return 'Test your reflexes';
      case 'personality_quiz':
        return 'Big Five assessment (Sign in required)';
      case 'decision_making':
        return 'Speed vs accuracy';
      case 'number_memory':
        return 'Test your memory (Sign in required)';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        // Removed outer right border for cleaner look
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              // Removed bottom border
            ),
            child: Column(
              children: [
                // Back to Landing Button
                if (widget.onBackToLanding != null)
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBackToLanding,
                        icon: Icon(Icons.arrow_back, color: Colors.grey[600]),
                        tooltip: 'Back to Landing Page',
                      ),
                      Spacer(),
                    ],
                  ),

                // Logo and Title
                Row(
                  children: [
                    Image.asset(
                      "assets/images/human_benchmark_onlylogo.png",
                      height: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Human Benchmark',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Test Your Limits',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: GameManagementService.getVisibleGamesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Loading games...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return ListView(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red[400], size: 16),
                            SizedBox(width: 12),
                            Text(
                              'Error loading games',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                final visibleGames = snapshot.data ?? [];

                return ListView(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  children: [
                    // Dashboard (always visible)
                    WebNavigationItem(
                      icon: WebUtils.getIconFromString('dashboard'),
                      title: 'Global Dashboard',
                      subtitle: 'View global statistics',
                      isSelected: widget.selectedIndex == 1,
                      onTap: () => widget.onIndexChanged(1),
                    ),

                    // Dynamic game items
                    ...visibleGames
                        .map((gameId) {
                          final gameIndex = _getGameIndex(gameId);
                          if (gameIndex == -1)
                            return SizedBox.shrink(); // Skip if no index mapping

                          return WebNavigationItem(
                            icon: _getGameIcon(gameId),
                            title: _getGameName(gameId),
                            subtitle: _getGameSubtitle(gameId),
                            isSelected: widget.selectedIndex == gameIndex,
                            onTap: () => widget.onIndexChanged(gameIndex),
                          );
                        })
                        .where((item) => item != SizedBox.shrink())
                        .toList(),

                    // Settings (always visible)
                    WebNavigationItem(
                      icon: WebUtils.getIconFromString('settings'),
                      title: 'Settings',
                      subtitle: 'Customize your experience',
                      isSelected: widget.selectedIndex == 5,
                      onTap: () => widget.onIndexChanged(5),
                    ),

                    // Profile (always visible)
                    WebNavigationItem(
                      icon: WebUtils.getIconFromString('person'),
                      title: 'Profile',
                      subtitle: 'View your statistics',
                      isSelected: widget.selectedIndex == 6,
                      onTap: () => widget.onIndexChanged(6),
                    ),

                    // Admin Users Link - Only show for admin users
                    if (_isAdmin)
                      WebNavigationItem(
                        icon: WebUtils.getIconFromString('people'),
                        title: 'Admin Users',
                        subtitle: 'Manage all users',
                        isSelected: widget.selectedIndex == 7,
                        onTap: () => widget.onIndexChanged(7),
                      ),

                    // Game Management Link - Only show for admin users
                    if (_isAdmin)
                      WebNavigationItem(
                        icon: WebUtils.getIconFromString('games'),
                        title: 'Game Management',
                        subtitle: 'Enable/disable games',
                        isSelected: widget.selectedIndex == 8,
                        onTap: () => widget.onIndexChanged(8),
                      ),

                    // Show loading indicator while checking admin status
                    if (_isLoadingAdmin)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Checking permissions...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Footer
          StreamBuilder<User?>(
            stream: AuthService.authStateChanges,
            builder: (context, snapshot) {
              final User? user = snapshot.data;
              final bool isSignedIn = user != null;

              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  // Removed top border
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isSignedIn
                          ? Colors.blue[100]
                          : Colors.grey[100],
                      backgroundImage:
                          (isSignedIn &&
                              user.photoURL != null &&
                              user.photoURL!.isNotEmpty)
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child:
                          (!isSignedIn ||
                              user.photoURL == null ||
                              user.photoURL!.isEmpty)
                          ? Icon(
                              isSignedIn ? Icons.person : Icons.person_outline,
                              color: isSignedIn
                                  ? Colors.blue[600]
                                  : Colors.grey[600],
                            )
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSignedIn
                                ? (user.displayName ?? 'User')
                                : 'Guest User',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            isSignedIn
                                ? user.email ?? 'Signed in user'
                                : 'Sign in for more features',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSignedIn
                                  ? Colors.blue[600]
                                  : Colors.grey[600],
                            ),
                          ),
                          // Show admin status if user is signed in
                          if (isSignedIn && _isAdmin)
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    if (isSignedIn)
                      // Logout button with only icon
                      IconButton(
                        onPressed: () async {
                          await AuthService.signOut();
                          // Refresh admin status after logout
                          _checkAdminStatus();
                        },
                        icon: Icon(
                          Icons.logout,
                          size: 20,
                          color: Colors.red[600],
                        ),
                        tooltip: 'Sign out',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red[50],
                        ),
                      )
                    else
                      // Sign in button
                      OutlinedButton.icon(
                        onPressed: () async {
                          await AuthService.signInWithGoogle();
                          // Refresh admin status after sign in
                          _checkAdminStatus();
                        },
                        icon: Icon(
                          Icons.login,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        label: Text(
                          'Sign in',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper methods for game information
  IconData _getGameIcon(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return Icons.timer;
      case 'number_memory':
        return Icons.memory;
      case 'decision_making':
        return Icons.speed;
      case 'personality_quiz':
        return Icons.psychology;
      case 'aim_trainer':
        return Icons.gps_fixed;
      case 'verbal_memory':
        return Icons.record_voice_over;
      case 'visual_memory':
        return Icons.visibility;
      case 'typing_speed':
        return Icons.keyboard;
      case 'sequence_memory':
        return Icons.format_list_numbered;
      case 'chimp_test':
        return Icons.pets;
      default:
        return Icons.games;
    }
  }

  String _getGameName(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return 'Reaction Time';
      case 'number_memory':
        return 'Number Memory';
      case 'decision_making':
        return 'Decision Making';
      case 'personality_quiz':
        return 'Personality Quiz';
      case 'aim_trainer':
        return 'Aim Trainer';
      case 'verbal_memory':
        return 'Verbal Memory';
      case 'visual_memory':
        return 'Visual Memory';
      case 'typing_speed':
        return 'Typing Speed';
      case 'sequence_memory':
        return 'Sequence Memory';
      case 'chimp_test':
        return 'Chimp Test';
      default:
        return gameId
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : '',
            )
            .join(' ');
    }
  }
}
