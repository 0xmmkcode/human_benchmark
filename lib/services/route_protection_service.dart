import 'package:flutter/material.dart';
import 'game_management_service.dart';
import 'app_logger.dart';

class RouteProtectionService {
  RouteProtectionService._();

  // Check if a game route is accessible
  static Future<bool> isGameRouteAccessible(String gameId) async {
    try {
      return await GameManagementService.isGameAccessible(gameId);
    } catch (e, st) {
      AppLogger.error('routeProtection.isGameRouteAccessible', e, st);
      return false; // Default to disabled on error
    }
  }

  // Get the appropriate route for a game (returns null if disabled)
  static Future<String?> getGameRoute(String gameId) async {
    final isEnabled = await isGameRouteAccessible(gameId);

    if (isEnabled) {
      return '/app/$gameId';
    } else {
      return null; // Game is disabled, no route available
    }
  }

  // Check if navigation should show a game
  static Future<bool> shouldShowGameInNavigation(String gameId) async {
    try {
      return await GameManagementService.isGameVisible(gameId);
    } catch (e, st) {
      AppLogger.error('routeProtection.shouldShowGameInNavigation', e, st);
      return false;
    }
  }

  // Get all accessible game routes
  static Future<List<String>> getAccessibleGameRoutes() async {
    try {
      final accessibleGames = await GameManagementService.getAccessibleGames();
      return accessibleGames.map((gameId) => '/app/$gameId').toList();
    } catch (e, st) {
      AppLogger.error('routeProtection.getAccessibleGameRoutes', e, st);
      return [];
    }
  }

  // Get game ID from route path
  static String? getGameIdFromRoute(String route) {
    if (route.startsWith('/app/')) {
      final parts = route.split('/');
      if (parts.length >= 3) {
        final gameId = parts[2];
        // List of valid game IDs
        const validGameIds = [
          'reaction_time',
          'number_memory',
          'decision_making',
          'personality_quiz',
          'aim_trainer',
          'verbal_memory',
          'visual_memory',
          'typing_speed',
          'sequence_memory',
          'chimp_test',
        ];

        if (validGameIds.contains(gameId)) {
          return gameId;
        }
      }
    }
    return null;
  }

  // Check if a route is a game route
  static bool isGameRoute(String route) {
    return getGameIdFromRoute(route) != null;
  }

  // Validate route access and block if disabled
  static Future<bool> isRouteAccessible(String route) async {
    if (!isGameRoute(route)) {
      return true; // Not a game route, allow access
    }

    final gameId = getGameIdFromRoute(route);
    if (gameId == null) {
      return true; // Invalid game route, allow access (will show 404)
    }

    final isAccessible = await isGameRouteAccessible(gameId);
    return isAccessible; // Return true if enabled, false if disabled
  }

  // Block route access completely for disabled games
  static Future<void> blockDisabledGameAccess(String gameId) async {
    final isEnabled = await isGameRouteAccessible(gameId);
    if (!isEnabled) {
      throw Exception('Game $gameId is currently disabled and not accessible');
    }
  }
}
