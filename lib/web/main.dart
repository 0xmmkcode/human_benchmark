import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:human_benchmark/web/pages/settings_page.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/web/pages/global_dashboard_page.dart';
import 'package:human_benchmark/web/pages/number_memory_page.dart';
import 'package:human_benchmark/web/pages/profile_page.dart';

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
          return Scaffold(
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
                        context.go('/app/decision');
                        break;
                      case 4:
                        context.go('/app/number-memory');
                        break;
                      case 5:
                        context.go('/app/settings');
                        break;
                      case 6:
                        context.go('/app/profile');
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
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/app/reaction',
            builder: (context, state) => WebReactionTimePage(),
          ),
          GoRoute(
            path: '/app/dashboard',
            builder: (context, state) => const GlobalDashboardPage(),
          ),
          GoRoute(
            path: '/app/personality',
            builder: (context, state) => const PersonalityQuizPage(),
          ),
          GoRoute(
            path: '/app/decision',
            builder: (context, state) => const WebDecisionMakingPage(),
          ),
          GoRoute(
            path: '/app/number-memory',
            builder: (context, state) => const WebNumberMemoryPage(),
          ),
          GoRoute(
            path: '/app/settings',
            builder: (context, state) => const WebSettingsPage(),
          ),
          GoRoute(
            path: '/app/profile',
            builder: (context, state) => const WebProfilePage(),
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
  } else if (location.endsWith('/settings')) {
    return 5;
  } else if (location.endsWith('/profile')) {
    return 6;
  }
  return 0; // Default to reaction time
}
