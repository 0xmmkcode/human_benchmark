import 'package:flutter/material.dart';
import 'package:human_benchmark/web/components/web_navigation_item.dart';

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
                    Icon(Icons.speed, color: Colors.blue[600], size: 32),
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
                  icon: Icons.timer,
                  title: 'Reaction Time',
                  subtitle: 'Test your reflexes',
                  isSelected: selectedIndex == 0,
                  onTap: () => onIndexChanged(0),
                ),
                WebNavigationItem(
                  icon: Icons.leaderboard,
                  title: 'Leaderboard',
                  subtitle: 'See top scores',
                  isSelected: selectedIndex == 1,
                  onTap: () => onIndexChanged(1),
                ),
                SizedBox(height: 32),
                WebNavigationItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Learn more',
                  isSelected: selectedIndex == 2,
                  isComingSoon: true,
                ),
                WebNavigationItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'Customize your experience',
                  isSelected: selectedIndex == 3,
                  isComingSoon: true,
                ),
              ],
            ),
          ),

          // Footer
          Container(
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
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.person, color: Colors.blue[600]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest User',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Sign in for more features',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
