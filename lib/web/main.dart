import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:human_benchmark/firebase_options.dart';
import 'package:human_benchmark/web/pages/landing_page.dart';
import 'package:human_benchmark/web/pages/about_page.dart';
import 'package:human_benchmark/web/pages/features_page.dart';
import 'package:human_benchmark/web/pages/reaction_time_page.dart';
import 'package:human_benchmark/web/components/web_sidebar.dart';
import 'package:human_benchmark/web/pages/privacy_policy_page.dart';
import 'package:human_benchmark/web/pages/terms_of_service_page.dart';
import 'package:human_benchmark/screens/personality_quiz_page.dart';
import 'package:human_benchmark/web/pages/decision_making_page.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/web/pages/global_dashboard_page.dart';
import 'package:human_benchmark/web/pages/number_memory_page.dart';
import 'package:human_benchmark/web/pages/chimp_test_page.dart';
import 'package:human_benchmark/web/pages/profile_page.dart';
import 'package:human_benchmark/web/pages/admin_users_page.dart';
import 'package:human_benchmark/web/pages/admin_game_management_page.dart';
import 'package:human_benchmark/web/pages/admin_web_settings_page.dart';
import 'package:human_benchmark/web/components/protected_game_route.dart';
import 'package:human_benchmark/web/components/maintenance_wrapper.dart';
import 'package:human_benchmark/web/services/firebase_navigation_service.dart';
import 'package:human_benchmark/services/game_management_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for web
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure Firebase Auth for web persistence
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      print('Firebase Auth persistence set to LOCAL for web');
    }

    // Initialize auth service for web persistence
    await AuthService.initializeAuth();

    // Listen to auth state changes to verify persistence
    if (kIsWeb) {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          print('User signed in: ${user.uid}');
        } else {
          print('User signed out');
        }
      });
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Create dynamic router based on Firebase settings
  final GoRouter router = await _createDynamicRouter();

  runApp(
    ProviderScope(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Human Benchmark l Test your limits',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          brightness: Brightness.light,
          fontFamily: GoogleFonts.montserrat().fontFamily,
        ),
        routerConfig: router,
      ),
    ),
  );
}

// Create dynamic router based on Firebase game management settings
Future<GoRouter> _createDynamicRouter() async {
  final routes = await FirebaseNavigationService.getAllRoutes();

  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      // Landing page
      GoRoute(
        path: '/',
        builder: (context, state) => LandingPage(
          onStartApp: () => context.go('/app/dashboard'),
          onAbout: () => context.go('/app/about'),
          onFeatures: () => context.go('/app/features'),
        ),
      ),
      // Static pages
      GoRoute(
        path: '/app/about',
        builder: (context, state) =>
            AboutPage(onBackToLanding: () => context.go('/')),
      ),
      GoRoute(
        path: '/app/features',
        builder: (context, state) =>
            FeaturesPage(onBackToLanding: () => context.go('/')),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsOfServicePage(),
      ),
      // Admin pages (registered statically to avoid missing routes)
      GoRoute(
        path: '/app/admin-users',
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: '/app/admin-game-management',
        builder: (context, state) => const AdminGameManagementPage(),
      ),
      GoRoute(
        path: '/app/admin-web-settings',
        builder: (context, state) => const AdminWebSettingsPage(),
      ),
      // Aliases/redirects for common typos
      GoRoute(
        path: '/app/game-management',
        redirect: (context, state) => '/app/admin-game-management',
      ),
      GoRoute(
        path: '/app/ugame-management',
        redirect: (context, state) => '/app/admin-game-management',
      ),
      // Dynamic shell route for all app pages
      ShellRoute(
        builder: (context, state, child) {
          return MaintenanceWrapper(child: _WebAppShell(child: child));
        },
        routes: _buildDynamicRoutes(routes),
      ),
    ],
  );
}

// Build dynamic routes based on Firebase settings
List<RouteBase> _buildDynamicRoutes(List<Map<String, dynamic>> routes) {
  final List<RouteBase> dynamicRoutes = [];

  for (final route in routes) {
    final path = route['path'] as String;
    final type = route['type'] as String;

    if (type == 'dashboard') {
      dynamicRoutes.add(
        GoRoute(
          path: path,
          builder: (context, state) => const GlobalDashboardPage(),
        ),
      );
    } else if (type == 'game') {
      final gameId = route['gameId'] as String;
      dynamicRoutes.add(
        GoRoute(
          path: path,
          builder: (context, state) => _buildGameRoute(gameId),
        ),
      );
    } else if (type == 'profile') {
      dynamicRoutes.add(
        GoRoute(
          path: path,
          builder: (context, state) => const WebProfilePage(),
        ),
      );
    } else if (type == 'admin_users') {
      dynamicRoutes.add(
        GoRoute(
          path: path,
          builder: (context, state) => const AdminUsersPage(),
        ),
      );
    } else if (type == 'admin_game_management') {
      dynamicRoutes.add(
        GoRoute(
          path: path,
          builder: (context, state) => const AdminGameManagementPage(),
        ),
      );
    } else if (type == 'admin_web_settings') {
      dynamicRoutes.add(
        GoRoute(
          path: path,
          builder: (context, state) => const AdminWebSettingsPage(),
        ),
      );
    }
  }

  return dynamicRoutes;
}

// Build game route based on game ID
Widget _buildGameRoute(String gameId) {
  return FutureBuilder<Map<String, dynamic>>(
    future: _getGameStatus(gameId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final gameStatus = snapshot.data ?? {};
      final isMaintenance = gameStatus['isMaintenance'] ?? false;
      final isBlocked = gameStatus['isBlocked'] ?? false;
      final isActive = gameStatus['isActive'] ?? true;

      // Show appropriate message based on game status
      if (isMaintenance) {
        return _buildStatusPage(
          gameId: gameId,
          status: 'Under Maintenance',
          message:
              'This game is temporarily unavailable. Please check back later.',
          icon: Icons.build,
          color: Colors.purple[400]!,
        );
      } else if (isBlocked) {
        return _buildStatusPage(
          gameId: gameId,
          status: 'Blocked',
          message: 'This game has been blocked and is not available.',
          icon: Icons.block,
          color: Colors.red[400]!,
        );
      } else if (!isActive) {
        return _buildStatusPage(
          gameId: gameId,
          status: 'Disabled',
          message: 'This game is currently disabled and not available.',
          icon: Icons.pause,
          color: Colors.orange[400]!,
        );
      }

      // Game is active, show the actual game
      switch (gameId) {
        case 'reaction_time':
          return ProtectedGameRoute(
            gameId: gameId,
            child: WebReactionTimePage(),
          );
        case 'number_memory':
          return ProtectedGameRoute(
            gameId: gameId,
            child: const WebNumberMemoryPage(),
          );
        case 'chimp_test':
          return ProtectedGameRoute(
            gameId: gameId,
            child: const WebChimpTestPage(),
          );
        case 'decision_risk':
          return ProtectedGameRoute(
            gameId: gameId,
            child: const WebDecisionMakingPage(),
          );
        case 'personality_quiz':
          return ProtectedGameRoute(
            gameId: gameId,
            child: const PersonalityQuizPage(),
          );
        case 'sequence_memory':
        case 'verbal_memory':
        case 'visual_memory':
        case 'aim_trainer':
        default:
          return ProtectedGameRoute(
            gameId: gameId,
            child: Scaffold(
              body: Center(
                child: Text(
                  '${_getGameTitle(gameId)} - Coming Soon!',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
      }
    },
  );
}

// Build status page for different game states
Widget _buildStatusPage({
  required String gameId,
  required String status,
  required String message,
  required IconData icon,
  required Color color,
}) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            _getGameTitle(gameId),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) => ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ),
        ],
      ),
    ),
  );
}

// Get complete game status information
Future<Map<String, dynamic>> _getGameStatus(String gameId) async {
  try {
    final gameManagement = await GameManagementService.getGameManagement(
      gameId,
    );
    if (gameManagement == null) {
      return {'isMaintenance': false, 'isBlocked': false, 'isActive': true};
    }

    return {
      'isMaintenance': gameManagement.isMaintenance,
      'isBlocked': gameManagement.isBlocked,
      'isActive': gameManagement.isActive,
    };
  } catch (e) {
    return {'isMaintenance': false, 'isBlocked': false, 'isActive': true};
  }
}

// Helper method to get game title
String _getGameTitle(String gameId) {
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

// Web app shell widget that handles dynamic navigation
class _WebAppShell extends StatefulWidget {
  final Widget child;

  const _WebAppShell({required this.child});

  @override
  State<_WebAppShell> createState() => _WebAppShellState();
}

class _WebAppShellState extends State<_WebAppShell> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseNavigationService.getAllNavigationItemsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error loading navigation: ${snapshot.error}'),
            ),
          );
        }

        final navigationItems = snapshot.data ?? [];
        if (navigationItems.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No navigation items available')),
          );
        }

        final location = GoRouterState.of(context).uri.toString();
        final selectedIndex = _getSelectedIndex(location, navigationItems);

        return Scaffold(
          body: Row(
            children: [
              WebSidebar(
                selectedIndex: selectedIndex,
                onIndexChanged: (int idx) {
                  final item = navigationItems.firstWhere(
                    (item) => item['index'] == idx,
                    orElse: () => <String, dynamic>{},
                  );

                  final route = item['path'] as String?;
                  if (route != null) {
                    context.go(route);
                  }
                },
                onBackToLanding: () => context.go('/'),
              ),
              Expanded(
                child: Container(color: Colors.white, child: widget.child),
              ),
            ],
          ),
        );
      },
    );
  }

  int _getSelectedIndex(
    String location,
    List<Map<String, dynamic>> navigationItems,
  ) {
    for (final item in navigationItems) {
      if (item['path'] == location) {
        return item['index'] as int;
      }
    }
    return 0; // Default to first item
  }
}
