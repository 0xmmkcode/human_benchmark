import 'package:flutter/material.dart';
import 'package:human_benchmark/web/widgets/app_loading.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/utils/web_utils.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/web/services/firebase_navigation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebMinimizedSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final VoidCallback? onBackToLanding;
  final VoidCallback? onMaximize;

  const WebMinimizedSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.onBackToLanding,
    this.onMaximize,
  }) : super(key: key);

  @override
  State<WebMinimizedSidebar> createState() => _WebMinimizedSidebarState();
}

class _WebMinimizedSidebarState extends State<WebMinimizedSidebar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(color: Colors.grey[50]),
      child: Column(
        children: [
          // Header - App Logo with Maximize Button
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // App Logo with Maximize Button on Top
                Stack(
                  children: [
                    // App Logo
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            WebTheme.primaryBlue,
                            WebTheme.primaryBlueLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          "assets/images/human_benchmark_onlylogo_white.png",
                          height: 24,
                        ),
                      ),
                    ),
                    // Maximize Button on Top
                    if (widget.onMaximize != null)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: widget.onMaximize,
                            icon: Icon(
                              Icons.open_in_full,
                              color: Colors.grey[600],
                              size: 12,
                            ),
                            tooltip: 'Expand Sidebar',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Navigation Items - Only Icons
          Expanded(
            child: StreamBuilder<User?>(
              stream: AuthService.authStateChanges,
              builder: (context, authSnapshot) {
                final bool isSignedIn = authSnapshot.data != null;
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirebaseNavigationService.getAllNavigationItemsStream(
                    isSignedIn: isSignedIn,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: AppLoading(width: 18, height: 18),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Icon(
                          Icons.error,
                          color: Colors.red[400],
                          size: 20,
                        ),
                      );
                    }

                    final navigationItems = snapshot.data ?? [];

                    if (navigationItems.isEmpty) {
                      return Center(
                        child: Icon(
                          Icons.info,
                          color: Colors.blue[400],
                          size: 20,
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: navigationItems.map((item) {
                        return _buildMinimizedNavigationItem(item);
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),

          // Footer - User Icon
          StreamBuilder<User?>(
            stream: AuthService.authStateChanges,
            builder: (context, authSnapshot) {
              final User? user = authSnapshot.data;
              final bool isSignedIn = user != null;
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirebaseNavigationService.getAllNavigationItemsStream(
                  isSignedIn: isSignedIn,
                ),
                builder: (context, navSnapshot) {
                  final navigationItems = navSnapshot.data ?? [];
                  final bool isAdmin = navigationItems.any(
                    (item) =>
                        item['type']?.toString().startsWith('admin') == true,
                  );

                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: _buildUserIcon(user, isSignedIn, isAdmin),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedNavigationItem(Map<String, dynamic> item) {
    final isDisabled =
        (item['isMaintenance'] ?? false) ||
        (item['isBlocked'] ?? false) ||
        !(item['isActive'] ?? true);
    final isSelected = widget.selectedIndex == item['index'];
    final opacity = isDisabled ? 0.5 : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: item['title'] ?? 'Unknown',
          preferBelow: false,
          verticalOffset: 10,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isDisabled
                ? null
                : () => widget.onIndexChanged(item['index']),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Main Icon
                    Center(
                      child: Icon(
                        WebUtils.getIconFromString(item['icon']),
                        color: isSelected
                            ? WebTheme.primaryBlue
                            : (isDisabled
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                        size: 24,
                      ),
                    ),

                    // Status Indicators
                    if (item['isMaintenance'] ?? false)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    else if (item['isBlocked'] ?? false)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    else if (!(item['isActive'] ?? true))
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserIcon(User? user, bool isSignedIn, bool isAdmin) {
    return Container(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: isSignedIn
              ? (user?.displayName ?? user?.email ?? 'User Profile')
              : 'Guest',
          preferBelow: false,
          verticalOffset: 10,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Handle user menu tap - could show a popup menu
              _showUserMenu(context, user, isSignedIn, isAdmin);
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSignedIn ? Colors.blue[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // User Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: isSignedIn
                          ? Colors.blue[100]
                          : WebTheme.primaryBlue,
                      backgroundImage:
                          (isSignedIn &&
                              user?.photoURL != null &&
                              user!.photoURL!.isNotEmpty)
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: isSignedIn
                          ? ((user?.photoURL == null || user!.photoURL!.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    color: Colors.blue[600],
                                    size: 20,
                                  )
                                : null)
                          : Text(
                              'G',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Admin Indicator
                  if (isAdmin)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.star, color: Colors.white, size: 8),
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

  void _showUserMenu(
    BuildContext context,
    User? user,
    bool isSignedIn,
    bool isAdmin,
  ) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 0, 0, 0),
      items: [
        if (isSignedIn) ...[
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person, size: 20),
                SizedBox(width: 12),
                Text('Profile'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings, size: 20),
                SizedBox(width: 12),
                Text('Settings'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 20),
                SizedBox(width: 12),
                Text('Logout'),
              ],
            ),
          ),
        ] else ...[
          PopupMenuItem(
            value: 'login',
            child: Row(
              children: [
                Icon(Icons.login, size: 20),
                SizedBox(width: 12),
                Text('Login'),
              ],
            ),
          ),
        ],
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'profile':
            // Navigate to profile
            break;
          case 'settings':
            // Navigate to settings
            break;
          case 'logout':
            AuthService.signOut();
            break;
          case 'login':
            // Navigate to login
            break;
        }
      }
    });
  }
}
