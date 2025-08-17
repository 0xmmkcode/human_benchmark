import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:human_benchmark/firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:human_benchmark/home_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase non-blockingly; keep app behavior identical if it fails
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Swallow init errors until project is configured; avoids breaking runtime.
  }
  MobileAds.instance.initialize();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final GoRouter router = GoRouter(
    routes: <GoRoute>[
      GoRoute(path: '/', builder: (context, state) => const HomeShell()),
    ],
  );

  runApp(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: GoogleFonts.montserrat().fontFamily),
      ),
    ),
  );
}
