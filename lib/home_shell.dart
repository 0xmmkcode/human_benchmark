import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_page.dart';
import 'screens/game_grid_page.dart';
import 'screens/settings_page.dart';
import 'screens/profile_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;
  late List<Widget> pages;
  late List<BottomNavigationBarItem> navigationItems;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  void _initializeNavigation() {
    // Initialize with basic pages
    pages = [
      const DashboardPage(),
      const GameGridPage(),
      const SettingsPage(),
      const ProfilePage(),
    ];

    navigationItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.games),
        activeIcon: Icon(Icons.games),
        label: 'Games',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        activeIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
          items: navigationItems,
        ),
      ),
    );
  }
}
