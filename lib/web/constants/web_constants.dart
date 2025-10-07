class WebConstants {
  // Navigation Items
  static List<Map<String, dynamic>> get navigationItems => [
    {
      'icon': 'timer',
      'title': 'Reaction Time',
      'subtitle': 'Test your reflexes',
      'index': 0,
      'isComingSoon': false,
    },
    {
      'icon': 'memory',
      'title': 'Number Memory',
      'subtitle': 'Test your memory (Sign in required)',
      'index': 1,
      'isComingSoon': false,
    },
    {
      'icon': 'format_list_numbered',
      'title': 'Sequence Memory',
      'subtitle': 'Remember sequences (Coming Soon)',
      'index': 2,
      'isComingSoon': true,
    },
    {
      'icon': 'record_voice_over',
      'title': 'Verbal Memory',
      'subtitle': 'Remember words (Coming Soon)',
      'index': 3,
      'isComingSoon': true,
    },
    {
      'icon': 'visibility',
      'title': 'Visual Memory',
      'subtitle': 'Remember patterns (Coming Soon)',
      'index': 4,
      'isComingSoon': true,
    },
    {
      'icon': 'pets',
      'title': 'Chimp Test',
      'subtitle': 'Test your memory (Coming Soon)',
      'index': 5,
      'isComingSoon': true,
    },
    {
      'icon': 'speed',
      'title': 'Decision Risk',
      'subtitle': 'Speed vs accuracy',
      'index': 6,
      'isComingSoon': false,
    },
    {
      'icon': 'gps_fixed',
      'title': 'Aim Trainer',
      'subtitle': 'Test your precision (Coming Soon)',
      'index': 7,
      'isComingSoon': true,
    },
    {
      'icon': 'psychology',
      'title': 'Personality Quiz',
      'subtitle': 'Big Five assessment (Sign in required)',
      'index': 8,
      'isComingSoon': false,
    },
    {
      'icon': 'dashboard',
      'title': 'Global Statistics',
      'subtitle': 'View global statistics',
      'index': 9,
      'isComingSoon': false,
    },
    {
      'icon': 'settings',
      'title': 'Settings',
      'subtitle': 'Customize your experience',
      'index': 10,
      'isComingSoon': false,
    },
    {
      'icon': 'person',
      'title': 'Profile',
      'subtitle': 'View your statistics',
      'index': 11,
      'isComingSoon': false,
    },
  ];

  // App Information
  static const String appName = 'Human Benchmark';
  static const String appTagline = 'Test Your Limits';
  static const String appDescription =
      'Test your reaction time and cognitive abilities';

  // User States
  static const String guestUserName = 'Guest User';
  static const String guestUserSubtitle = 'Sign in for more features';

  // Game Constants
  static const int minReactionDelay = 1000; // 1 second
  static const int maxReactionDelay = 5000; // 5 seconds

  // UI Constants
  static const double sidebarWidth = 280.0;
  static const double gameAreaWidth = 400.0;
  static const double gameAreaHeight = 300.0;

  // Animation Durations
  static const int colorAnimationDuration = 300; // milliseconds
  static const int scaleAnimationDuration = 200; // milliseconds

  // Top 3 Colors for Leaderboard
  static const List<String> top3Colors = [
    'amber600', // Gold
    'grey400', // Silver
    'orange600', // Bronze
  ];

  // Top 3 Icons for Leaderboard
  static const List<String> top3Icons = [
    'emoji_events', // Trophy
    'workspace_premium', // Premium
    'military_tech', // Medal
  ];
}
