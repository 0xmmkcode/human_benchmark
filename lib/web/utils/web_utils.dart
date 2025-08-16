import 'package:flutter/material.dart';

class WebUtils {
  // Icon mapping for navigation items
  static IconData getIconFromString(String iconName) {
    switch (iconName) {
      case 'timer':
        return Icons.timer;
      case 'dashboard':
        return Icons.dashboard;
      case 'memory':
        return Icons.memory;
      case 'psychology':
        return Icons.psychology;
      case 'info_outline':
        return Icons.info_outline;
      case 'settings':
        return Icons.settings;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'military_tech':
        return Icons.military_tech;
      case 'star':
        return Icons.star;
      case 'touch_app':
        return Icons.touch_app;
      case 'hourglass_empty':
        return Icons.hourglass_empty;
      case 'analytics':
        return Icons.analytics;
      case 'trending_up':
        return Icons.trending_up;
      case 'person':
        return Icons.person;
      case 'speed':
        return Icons.speed;
      case 'refresh':
        return Icons.refresh;
      default:
        return Icons.help_outline;
    }
  }

  // Format date for display
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Calculate average from list of integers
  static int calculateAverage(List<int> numbers) {
    if (numbers.isEmpty) return 0;
    return (numbers.reduce((a, b) => a + b) / numbers.length).round();
  }

  // Generate random delay for reaction time game
  static Duration generateRandomDelay() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final delayMs = 1000 + (random % 4000); // 1-5 seconds
    return Duration(milliseconds: delayMs);
  }

  // Build stat card widget
  static Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Build loading widget
  static Widget buildLoadingWidget({String message = 'Loading...'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Build empty state widget
  static Widget buildEmptyStateWidget({
    required IconData icon,
    required String title,
    required String subtitle,
    double iconSize = 64,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
