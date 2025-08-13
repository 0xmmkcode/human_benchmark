import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:human_benchmark/firebase_options.dart';
import 'package:human_benchmark/web/pages/landing_page.dart';
import 'package:human_benchmark/web/pages/about_page.dart';
import 'package:human_benchmark/web/pages/features_page.dart';
import 'package:human_benchmark/web/pages/reaction_time_page.dart';
import 'package:human_benchmark/web/pages/leaderboard_page.dart';
import 'package:human_benchmark/web/components/web_sidebar.dart';
import 'package:human_benchmark/web/pages/privacy_policy_page.dart';
import 'package:human_benchmark/web/pages/terms_of_service_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for web
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
          final int selectedIndex = location.endsWith('/leaderboard') ? 1 : 0;
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
                        context.go('/app/leaderboard');
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
            path: '/app/leaderboard',
            builder: (context, state) => WebLeaderboardPage(),
          ),
        ],
      ),
    ],
  );

  runApp(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Human Benchmark l Test your limits',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      routerConfig: router,
    ),
  );
}
