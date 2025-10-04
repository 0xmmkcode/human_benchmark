import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/utils/web_utils.dart';
import 'package:human_benchmark/web/components/web_navigation_item.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/web/services/firebase_navigation_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

class WebSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final VoidCallback? onBackToLanding;
  final VoidCallback? onMinimize;

  const WebSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.onBackToLanding,
    this.onMinimize,
  }) : super(key: key);

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  @override
  void initState() {
    super.initState();
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
              color: WebTheme.grey50,
              // Removed bottom border
            ),
            child: Column(
              children: [
                // Back to Landing Button
                /*if (widget.onBackToLanding != null)
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
*/
                // Logo and Title with Minimize Button
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
                    // Minimize Button
                    if (widget.onMinimize != null)
                      IconButton(
                        onPressed: widget.onMinimize,
                        icon: Icon(
                          Icons.minimize,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        tooltip: 'Minimize Sidebar',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: EdgeInsets.all(8),
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

          // Navigation Items
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Loading navigation...',
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
                                Icon(
                                  Icons.error,
                                  color: Colors.red[400],
                                  size: 16,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Error loading navigation: ${snapshot.error}',
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

                    final navigationItems = snapshot.data ?? [];

                    if (navigationItems.isEmpty) {
                      return ListView(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.blue[400],
                                  size: 16,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'No navigation items available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      children: navigationItems.map((item) {
                        return WebNavigationItem(
                          icon: WebUtils.getIconFromString(item['icon']),
                          title: item['title'],
                          subtitle: item['subtitle'],
                          isSelected: widget.selectedIndex == item['index'],
                          isMaintenance: item['isMaintenance'] ?? false,
                          isBlocked: item['isBlocked'] ?? false,
                          isActive: item['isActive'] ?? true,
                          onTap: () => widget.onIndexChanged(item['index']),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
          Gap(16),
          // Footer
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
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WebTheme.grey50,
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
                                  isSignedIn
                                      ? Icons.person
                                      : Icons.person_outline,
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
                              // Show admin status if user is admin
                              if (isSignedIn && isAdmin)
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
              );
            },
          ),
        ],
      ),
    );
  }
}
