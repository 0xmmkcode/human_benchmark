import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:human_benchmark/firebase_options.dart';
import 'package:human_benchmark/web/pages/landing_page.dart';
import 'package:human_benchmark/web/pages/about_page.dart';
import 'package:human_benchmark/web/pages/features_page.dart';
import 'package:human_benchmark/web/pages/reaction_time_page.dart';
import 'package:human_benchmark/web/pages/leaderboard_page.dart';
import 'package:human_benchmark/web/components/web_sidebar.dart';

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

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Human Benchmark - Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: WebApp(),
    ),
  );
}

class WebApp extends StatefulWidget {
  @override
  _WebAppState createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  String _currentPage = 'landing'; // 'landing', 'about', 'features', 'app'
  int _selectedIndex = 0;

  final List<Widget> _appPages = [WebReactionTimePage(), WebLeaderboardPage()];

  void _navigateToPage(String page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _startApp() {
    setState(() {
      _currentPage = 'app';
    });
  }

  void _goBackToLanding() {
    setState(() {
      _currentPage = 'landing';
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentPage) {
      case 'landing':
        return LandingPage(
          onStartApp: _startApp,
          onAbout: () => _navigateToPage('about'),
          onFeatures: () => _navigateToPage('features'),
        );
      case 'about':
        return AboutPage(onBackToLanding: _goBackToLanding);
      case 'features':
        return FeaturesPage(onBackToLanding: _goBackToLanding);
      case 'app':
        return Scaffold(
          body: Row(
            children: [
              // Persistent Sidebar
              WebSidebar(
                selectedIndex: _selectedIndex,
                onIndexChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                onBackToLanding: _goBackToLanding,
              ),

              // Main Content Area
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _appPages[_selectedIndex],
                ),
              ),
            ],
          ),
        );
      default:
        return LandingPage(
          onStartApp: _startApp,
          onAbout: () => _navigateToPage('about'),
          onFeatures: () => _navigateToPage('features'),
        );
    }
  }
}
