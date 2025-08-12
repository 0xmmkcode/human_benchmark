class WebConstants {
  // Navigation Items
  static const List<Map<String, dynamic>> navigationItems = [
    {
      'icon': 'timer',
      'title': 'Reaction Time',
      'subtitle': 'Test your reflexes',
      'index': 0,
      'isComingSoon': false,
    },
    {
      'icon': 'leaderboard',
      'title': 'Leaderboard',
      'subtitle': 'See top scores',
      'index': 1,
      'isComingSoon': false,
    },
    {
      'icon': 'info_outline',
      'title': 'About',
      'subtitle': 'Learn more',
      'index': 2,
      'isComingSoon': true,
    },
    {
      'icon': 'settings',
      'title': 'Settings',
      'subtitle': 'Customize your experience',
      'index': 3,
      'isComingSoon': true,
    },
  ];

  // Categories for Leaderboard
  static const List<Map<String, String>> leaderboardCategories = [
    {'value': 'reaction_time', 'label': 'Reaction Time'},
    {'value': 'memory', 'label': 'Memory'},
    {'value': 'typing', 'label': 'Typing Speed'},
  ];

  // Time Frames for Leaderboard
  static const List<Map<String, String>> timeFrames = [
    {'value': 'all_time', 'label': 'All Time'},
    {'value': 'this_month', 'label': 'This Month'},
    {'value': 'this_week', 'label': 'This Week'},
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
  static const int leaderboardLimit = 50;

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
