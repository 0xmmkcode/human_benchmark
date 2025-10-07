import 'package:flutter/material.dart';
import 'package:human_benchmark/web/components/web_sidebar_toggle.dart';
import 'package:human_benchmark/web/services/firebase_navigation_service.dart';
import 'package:go_router/go_router.dart';

class SidebarDemoPage extends StatefulWidget {
  const SidebarDemoPage({super.key});

  @override
  State<SidebarDemoPage> createState() => _SidebarDemoPageState();
}

class _SidebarDemoPageState extends State<SidebarDemoPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return WebSidebarToggle(
      selectedIndex: selectedIndex,
      onIndexChanged: (int idx) {
        setState(() {
          selectedIndex = idx;
        });

        // Get the navigation item and navigate
        FirebaseNavigationService.getAllNavigationItemsStream().first.then((
          items,
        ) {
          final item = items.firstWhere(
            (item) => item['index'] == idx,
            orElse: () => <String, dynamic>{},
          );

          final route = item['path'] as String?;
          if (route != null) {
            context.push(route);
          }
        });
      },
      onBackToLanding: () => context.push('/'),
      child: _buildDemoContent(),
    );
  }

  Widget _buildDemoContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sidebar Demo',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This page demonstrates the minimized sidebar functionality.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Features List
          _buildFeatureCard(
            'Minimized Sidebar',
            'Icons-only sidebar that takes up minimal space (80px width)',
            Icons.view_sidebar,
            Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'App Logo',
            'Compact app logo at the top of the sidebar',
            Icons.apps,
            Colors.green,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'Navigation Icons',
            'All navigation items displayed as icons with status indicators',
            Icons.navigation,
            Colors.orange,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'User Icon',
            'User avatar with admin indicator and popup menu',
            Icons.person,
            Colors.purple,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'Toggle Functionality',
            'Switch between regular and minimized sidebar using the toggle button',
            Icons.swap_horiz,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
