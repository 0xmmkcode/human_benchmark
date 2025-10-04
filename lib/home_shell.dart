import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_page.dart';
import 'screens/game_grid_page.dart';
import 'screens/profile_page.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    // Initialize with basic pages - Games first
    pages = [const GameGridPage(), const DashboardPage()];
    navigationItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.games),
        activeIcon: Icon(Icons.games),
        label: 'Games',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.insights),
        activeIcon: Icon(Icons.insights),
        label: 'Statistics',
      ),
    ];
  }

  void _updateNavigationForAuth(User? user) {
    if (user != null) {
      // User is signed in - add profile
      if (pages.length == 2) {
        pages.add(const ProfilePage());
        navigationItems.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        );
      }
    } else {
      // User is signed out - remove profile
      if (pages.length == 3) {
        pages.removeLast();
        navigationItems.removeLast();
        if (_currentIndex >= pages.length) {
          _currentIndex = pages.length - 1;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        _updateNavigationForAuth(user);

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
      },
    );
  }
}
