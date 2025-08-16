import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/constants/web_constants.dart';
import 'package:human_benchmark/web/utils/web_utils.dart';
import 'package:human_benchmark/web/components/web_navigation_item.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebSidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(right: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Back to Landing Button
                if (onBackToLanding != null)
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBackToLanding,
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
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 16),
              children: [
                WebNavigationItem(
                  icon: WebUtils.getIconFromString('timer'),
                  title: 'Reaction Time',
                  subtitle: 'Test your reflexes',
                  isSelected: selectedIndex == 0,
                  onTap: () => onIndexChanged(0),
                ),
                WebNavigationItem(
                  icon: WebUtils.getIconFromString('dashboard'),
                  title: 'Global Dashboard',
                  subtitle: 'View global statistics',
                  isSelected: selectedIndex == 1,
                  onTap: () => onIndexChanged(1),
                ),
                WebNavigationItem(
                  icon: WebUtils.getIconFromString('psychology'),
                  title: 'Personality Quiz',
                  subtitle: 'Big Five assessment (Sign in required)',
                  isSelected: selectedIndex == 2,
                  onTap: () => onIndexChanged(2),
                ),
                WebNavigationItem(
                  icon: WebUtils.getIconFromString('speed'),
                  title: 'Decision Making',
                  subtitle: 'Speed vs accuracy',
                  isSelected: selectedIndex == 3,
                  onTap: () => onIndexChanged(3),
                ),
                WebNavigationItem(
                  icon: WebUtils.getIconFromString('memory'),
                  title: 'Number Memory',
                  subtitle: 'Test your memory (Sign in required)',
                  isSelected: selectedIndex == 4,
                  onTap: () => onIndexChanged(4),
                ),
                WebNavigationItem(
                  icon: WebUtils.getIconFromString('settings'),
                  title: 'Settings',
                  subtitle: 'Customize your experience',
                  isSelected: selectedIndex == 5,
                  onTap: () => onIndexChanged(5),
                ),
                WebNavigationItem(
                  icon: WebUtils.getIconFromString('person'),
                  title: 'Profile',
                  subtitle: 'View your statistics',
                  isSelected: selectedIndex == 6,
                  onTap: () => onIndexChanged(6),
                ),
              ],
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
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
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
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    if (isSignedIn)
                      // Logout button with only icon
                      IconButton(
                        onPressed: () async {
                          await AuthService.signOut();
                        },
                        icon: Icon(
                          Icons.logout,
                          size: 20,
                          color: Colors.red[600],
                        ),
                        tooltip: 'Sign out',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          side: BorderSide(color: Colors.red[200]!),
                        ),
                      )
                    else
                      // Sign in button
                      OutlinedButton.icon(
                        onPressed: () async {
                          await AuthService.signInWithGoogle();
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
                          side: BorderSide(color: Colors.blue[200]!),
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
}
