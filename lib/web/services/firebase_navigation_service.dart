import 'package:human_benchmark/services/game_management_service.dart';
import 'package:human_benchmark/services/admin_service.dart';
import 'package:human_benchmark/models/game_management.dart';
import 'dart:async';

class FirebaseNavigationService {
  // Static navigation items (always present)
  static const List<Map<String, dynamic>> staticNavigationItems = [
    {
      'type': 'dashboard',
      'path': '/app/dashboard',
      'title': 'Global Dashboard',
      'subtitle': 'View global statistics',
      'icon': 'dashboard',
    },
  ];

  // Static end navigation items
  static const List<Map<String, dynamic>> endNavigationItems = [
    {
      'type': 'profile',
      'path': '/app/profile',
      'title': 'Profile',
      'subtitle': 'View your statistics',
      'icon': 'person',
    },
  ];

  // Get end navigation items based on authentication status
  static List<Map<String, dynamic>> getEndNavigationItems(bool isSignedIn) {
    if (isSignedIn) {
      return endNavigationItems;
    } else {
      return []; // No profile for signed out users
    }
  }

  // Admin navigation items
  static const List<Map<String, dynamic>> adminNavigationItems = [
    {
      'type': 'admin_users',
      'path': '/app/admin-users',
      'title': 'Admin Users',
      'subtitle': 'Manage all users',
      'icon': 'people',
    },
    {
      'type': 'admin_game_management',
      'path': '/app/admin-game-management',
      'title': 'Game Management',
      'subtitle': 'Enable/disable games',
      'icon': 'games',
    },
    {
      'type': 'admin_web_settings',
      'path': '/app/admin-web-settings',
      'title': 'Web Settings',
      'subtitle': 'Control web game access',
      'icon': 'settings',
    },
  ];

  // Game ID to route mapping
  static const Map<String, String> gameIdToRoute = {
    'reaction_time': '/app/reaction',
    'number_memory': '/app/number-memory',
    'sequence_memory': '/app/sequence-memory',
    'verbal_memory': '/app/verbal-memory',
    'visual_memory': '/app/visual-memory',
    'chimp_test': '/app/chimp-test',
    'decision_risk': '/app/decision',
    'aim_trainer': '/app/aim-trainer',
    'personality_quiz': '/app/personality',
  };

  // Get all navigation items based on Firebase settings
  static Future<List<Map<String, dynamic>>> getAllNavigationItems({
    bool isSignedIn = false,
  }) async {
    final visibleGames = await GameManagementService.getVisibleGamesInOrder();
    final isAdmin = await AdminService.isCurrentUserAdmin();

    final List<Map<String, dynamic>> allItems = [];
    int currentIndex = 0;

    // Add static items first
    for (final item in staticNavigationItems) {
      allItems.add({...item, 'index': currentIndex});
      currentIndex++;
    }

    // Add games from Firebase
    for (final gameId in visibleGames) {
      allItems.add({
        'type': 'game',
        'gameId': gameId,
        'path': gameIdToRoute[gameId],
        'title': _getGameTitle(gameId),
        'subtitle': _getGameSubtitle(gameId),
        'icon': _getGameIcon(gameId),
        'index': currentIndex,
      });
      currentIndex++;
    }

    // Add end items
    for (final item in getEndNavigationItems(isSignedIn)) {
      allItems.add({...item, 'index': currentIndex});
      currentIndex++;
    }

    // Add admin items if user is admin
    if (isAdmin) {
      for (final item in adminNavigationItems) {
        allItems.add({...item, 'index': currentIndex});
        currentIndex++;
      }
    }

    return allItems;
  }

  // Get navigation items stream for real-time updates
  static Stream<List<Map<String, dynamic>>> getAllNavigationItemsStream({
    bool isSignedIn = false,
  }) {
    return GameManagementService.getAllGameManagementStream().asyncMap((
      allGames,
    ) async {
      final isAdmin = await AdminService.isCurrentUserAdmin();

      final List<Map<String, dynamic>> allItems = [];
      int currentIndex = 0;

      // Add static items first
      for (final item in staticNavigationItems) {
        allItems.add({...item, 'index': currentIndex});
        currentIndex++;
      }

      // Add ALL games from Firebase (including hidden/blocked ones for admin view)
      // Sort by the fixed order
      final completeFixedOrder = [
        'reaction_time',
        'number_memory',
        'sequence_memory',
        'verbal_memory',
        'visual_memory',
        'chimp_test',
        'decision_risk',
        'aim_trainer',
        'personality_quiz',
      ];

      final orderedGames = <GameManagement>[];

      // Add games in fixed order
      for (final gameId in completeFixedOrder) {
        final game = allGames.firstWhere(
          (g) => g.gameId == gameId,
          orElse: () => GameManagement(
            gameId: '',
            gameName: '',
            status: GameStatus.active,
            updatedAt: DateTime.now(),
            updatedBy: '',
          ),
        );
        if (game.gameId.isNotEmpty) {
          orderedGames.add(game);
        }
      }

      // Add any other games not in the fixed order
      for (final game in allGames) {
        if (!completeFixedOrder.contains(game.gameId)) {
          orderedGames.add(game);
        }
      }

      for (final game in orderedGames) {
        // Determine if game should be visible to user (only show active games or maintenance games)
        final isVisible = game.isActive || game.isMaintenance;

        if (isVisible) {
          allItems.add({
            'type': 'game',
            'gameId': game.gameId,
            'path': gameIdToRoute[game.gameId],
            'title': _getGameTitle(game.gameId),
            'subtitle': _getGameSubtitleWithStatus(game),
            'icon': _getGameIcon(game.gameId),
            'index': currentIndex,
            'status': game.status.name,
            'isMaintenance': game.isMaintenance,
            'isBlocked': game.isBlocked,
            'isActive': game.isActive,
          });
          currentIndex++;
        }
      }

      // Add end items
      for (final item in getEndNavigationItems(isSignedIn)) {
        allItems.add({...item, 'index': currentIndex});
        currentIndex++;
      }

      // Add admin items if user is admin
      if (isAdmin) {
        for (final item in adminNavigationItems) {
          allItems.add({...item, 'index': currentIndex});
          currentIndex++;
        }
      }

      return allItems;
    });
  }

  // Helper method to get subtitle with status
  static String _getGameSubtitleWithStatus(GameManagement game) {
    if (game.isMaintenance) {
      return 'Under Maintenance';
    } else if (game.isBlocked) {
      return 'Blocked';
    } else {
      return _getGameSubtitle(game.gameId);
    }
  }

  // Get navigation item for a specific index
  static Future<Map<String, dynamic>?> getNavigationItemForIndex(
    int index,
  ) async {
    final allItems = await getAllNavigationItems();

    for (final item in allItems) {
      if (item['index'] == index) {
        return item;
      }
    }

    return null;
  }

  // Get route for a specific index
  static Future<String?> getRouteForIndex(int index) async {
    final item = await getNavigationItemForIndex(index);
    return item?['path'];
  }

  // Get index for a specific route
  static Future<int?> getIndexForRoute(String route) async {
    final allItems = await getAllNavigationItems();

    for (final item in allItems) {
      if (item['path'] == route) {
        return item['index'];
      }
    }

    return null;
  }

  // Get all routes that should be registered
  static Future<List<Map<String, dynamic>>> getAllRoutes({
    bool isSignedIn = false,
  }) async {
    final visibleGames = await GameManagementService.getVisibleGamesInOrder();
    final isAdmin = await AdminService.isCurrentUserAdmin();

    final List<Map<String, dynamic>> routes = [];

    // Add static routes
    for (final item in staticNavigationItems) {
      routes.add({'path': item['path'], 'type': item['type']});
    }

    // Add game routes
    for (final gameId in visibleGames) {
      routes.add({
        'path': gameIdToRoute[gameId],
        'type': 'game',
        'gameId': gameId,
      });
    }

    // Add end routes
    for (final item in getEndNavigationItems(isSignedIn)) {
      routes.add({'path': item['path'], 'type': item['type']});
    }

    // Add admin routes if user is admin
    if (isAdmin) {
      for (final item in adminNavigationItems) {
        routes.add({'path': item['path'], 'type': item['type']});
      }
    }

    return routes;
  }

  // Helper methods for game data
  static String _getGameTitle(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return 'Reaction Time';
      case 'number_memory':
        return 'Number Memory';
      case 'sequence_memory':
        return 'Sequence Memory';
      case 'verbal_memory':
        return 'Verbal Memory';
      case 'visual_memory':
        return 'Visual Memory';
      case 'chimp_test':
        return 'Chimp Test';
      case 'decision_risk':
        return 'Decision Risk';
      case 'aim_trainer':
        return 'Aim Trainer';
      case 'personality_quiz':
        return 'Personality Quiz';
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

  static String _getGameSubtitle(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return 'Test your reflexes';
      case 'number_memory':
        return 'Test your memory';
      case 'sequence_memory':
        return 'Remember sequences';
      case 'verbal_memory':
        return 'Remember words';
      case 'visual_memory':
        return 'Remember patterns';
      case 'chimp_test':
        return 'Test your memory';
      case 'decision_risk':
        return 'Speed vs accuracy';
      case 'aim_trainer':
        return 'Test your precision';
      case 'personality_quiz':
        return 'Big Five assessment';
      default:
        return 'Game not found';
    }
  }

  static String _getGameIcon(String gameId) {
    switch (gameId) {
      case 'reaction_time':
        return 'timer';
      case 'number_memory':
        return 'memory';
      case 'sequence_memory':
        return 'format_list_numbered';
      case 'verbal_memory':
        return 'record_voice_over';
      case 'visual_memory':
        return 'visibility';
      case 'chimp_test':
        return 'pets';
      case 'decision_risk':
        return 'speed';
      case 'aim_trainer':
        return 'gps_fixed';
      case 'personality_quiz':
        return 'psychology';
      default:
        return 'games';
    }
  }
}
