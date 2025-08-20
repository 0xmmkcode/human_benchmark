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
import 'package:human_benchmark/web/pages/typing_speed_page.dart';
import 'package:human_benchmark/web/pages/chimp_test_page.dart';
import 'package:human_benchmark/web/pages/profile_page.dart';
import 'package:human_benchmark/web/pages/admin_users_page.dart';
import 'package:human_benchmark/web/pages/admin_game_management_page.dart';
import 'package:human_benchmark/web/components/protected_game_route.dart';
import 'package:human_benchmark/web/components/maintenance_wrapper.dart';

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
          print('User authenticated: ${user.email}');
        } else {
          print('User signed out');
        }
      });
    }
  } catch (_) {
    // Swallow init errors until project is configured; avoids breaking runtime.
  }

  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => LandingPage(
          onStartApp: () => context.go('/app/reaction'),
          onAbout: () => context.go('/app/about'),
          onFeatures: () => context.go('/app/features'),
        ),
      ),
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
      ShellRoute(
        builder: (context, state, child) {
          final String location = state.uri.toString();
          final int selectedIndex = _getSelectedIndex(location);
          return MaintenanceWrapper(
            child: Scaffold(
              body: Row(
                children: [
                  WebSidebar(
                    selectedIndex: selectedIndex,
                    onIndexChanged: (int idx) {
                      switch (idx) {
                        case 0:
                          context.go('/app/reaction');
                          break;
                        case 1:
                          context.go('/app/dashboard');
                          break;
                        case 2:
                          context.go('/app/personality');
                          break;
                        case 3:
                          context.go('/app/number-memory');
                          break;
                        case 4:
                          context.go('/app/chimp-test');
                          break;
                        case 5:
                          context.go('/app/decision');
                          break;
                        case 6:
                          context.go('/app/aim-trainer');
                          break;
                        case 7:
                          context.go('/app/verbal-memory');
                          break;
                        case 8:
                          context.go('/app/typing-speed');
                          break;
                        case 9:
                          context.go('/app/sequence-memory');
                          break;
                        case 10:
                          context.go('/app/profile');
                          break;
                        case 11:
                          context.go('/app/admin-users');
                          break;
                        case 12:
                          context.go('/app/admin-game-management');
                          break;
                      }
                    },
                    onBackToLanding: () => context.go('/'),
                  ),
                  Expanded(
                    child: Container(color: Colors.white, child: child),
                  ),
                ],
              ),
            ),
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/app/reaction',
            builder: (context, state) => ProtectedGameRoute(
              gameId: 'reaction_time',
              child: WebReactionTimePage(),
            ),
          ),
          GoRoute(
            path: '/app/dashboard',
            builder: (context, state) => const GlobalDashboardPage(),
          ),
          GoRoute(
            path: '/app/personality',
            builder: (context, state) => ProtectedGameRoute(
              gameId: 'personality_quiz',
              child: const PersonalityQuizPage(),
            ),
          ),
          GoRoute(
            path: '/app/decision',
            builder: (context, state) => ProtectedGameRoute(
              gameId: 'decision_making',
              child: const WebDecisionMakingPage(),
            ),
          ),
          GoRoute(
            path: '/app/number-memory',
            builder: (context, state) => ProtectedGameRoute(
              gameId: 'number_memory',
              child: const WebNumberMemoryPage(),
            ),
          ),
          GoRoute(
            path: '/app/typing-speed',
            builder: (context, state) => ProtectedGameRoute(
              gameId: 'typing_speed',
              child: const WebTypingSpeedPage(),
            ),
          ),
          GoRoute(
            path: '/app/verbal-memory',
            builder: (context, state) => ProtectedGameRoute(
              gameId: 'verbal_memory',
              child: const Scaffold(
                body: Center(
                  child: Text(
                    'Verbal Memory - Coming Soon!',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/app/sequence-memory',
            builder: (context, state) => ProtectedGameRoute(
              gameId: 'sequence_memory',
              child: const Scaffold(
                body: Center(
                  child: Text(
                    'Sequence Memory - Coming Soon!',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/app/chimp-test',
            builder: (context, state) => ProtectedGameRoute(
              gameId: 'chimp_test',
              child: const WebChimpTestPage(),
            ),
          ),
          GoRoute(
            path: '/app/aim-trainer',
            builder: (context, state) => ProtectedGameRoute(
              gameId: 'aim_trainer',
              child: const Scaffold(
                body: Center(
                  child: Text(
                    'Aim Trainer - Coming Soon!',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),

          GoRoute(
            path: '/app/profile',
            builder: (context, state) => const WebProfilePage(),
          ),
          GoRoute(
            path: '/app/admin-users',
            builder: (context, state) => const AdminUsersPage(),
          ),
          GoRoute(
            path: '/app/admin-game-management',
            builder: (context, state) => const AdminGameManagementPage(),
          ),
        ],
      ),
    ],
  );

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

int _getSelectedIndex(String location) {
  if (location.endsWith('/reaction')) {
    return 0;
  } else if (location.endsWith('/dashboard')) {
    return 1;
  } else if (location.endsWith('/personality')) {
    return 2;
  } else if (location.endsWith('/decision')) {
    return 3;
  } else if (location.endsWith('/number-memory')) {
    return 4;
  } else if (location.endsWith('/chimp-test')) {
    return 4;
  } else if (location.endsWith('/decision')) {
    return 5;
  } else if (location.endsWith('/aim-trainer')) {
    return 6;
  } else if (location.endsWith('/verbal-memory')) {
    return 7;
  } else if (location.endsWith('/typing-speed')) {
    return 8;
  } else if (location.endsWith('/sequence-memory')) {
    return 9;
  } else if (location.endsWith('/profile')) {
    return 10;
  } else if (location.endsWith('/admin-users')) {
    return 11;
  } else if (location.endsWith('/admin-game-management')) {
    return 12;
  }
  return 0; // Default to reaction time
}
