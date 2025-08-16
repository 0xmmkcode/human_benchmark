import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:human_benchmark/screens/reaction_time_page.dart';
import 'package:human_benchmark/screens/personality_quiz_page.dart';
import 'package:human_benchmark/screens/decision_risk_page.dart';
import 'package:human_benchmark/screens/number_memory_page.dart';
import 'package:human_benchmark/screens/settings_page.dart';
import 'package:human_benchmark/screens/leaderboard_page.dart';
import 'package:human_benchmark/screens/profile_page.dart';
import 'package:human_benchmark/widgets/score_display.dart';

class HomeShell extends StatefulWidget {
  final Widget playPage;
  const HomeShell({super.key, required this.playPage});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ReactionTimePage(),
      const LeaderboardPage(),
      const PersonalityQuizPage(),
      const DecisionRiskPage(),
      const NumberMemoryPage(),
      const ProfilePage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0074EB),
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.montserrat(),
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.flash_on_outlined),
              activeIcon: Icon(Icons.flash_on),
              label: 'Play',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'Personality',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Decision'),
            BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'Memory'),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
