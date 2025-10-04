import 'package:flutter/material.dart';
import 'package:human_benchmark/web/components/web_sidebar.dart';
import 'package:human_benchmark/web/components/web_minimized_sidebar.dart';

class WebSidebarToggle extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final VoidCallback? onBackToLanding;
  final Widget child;

  const WebSidebarToggle({
    Key? key,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.onBackToLanding,
    required this.child,
  }) : super(key: key);

  @override
  State<WebSidebarToggle> createState() => _WebSidebarToggleState();
}

class _WebSidebarToggleState extends State<WebSidebarToggle> {
  static bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (Regular or Minimized)
          _isMinimized
              ? WebMinimizedSidebar(
                  selectedIndex: widget.selectedIndex,
                  onIndexChanged: widget.onIndexChanged,
                  onBackToLanding: widget.onBackToLanding,
                  onMaximize: () {
                    setState(() {
                      _isMinimized = false;
                    });
                  },
                )
              : WebSidebar(
                  selectedIndex: widget.selectedIndex,
                  onIndexChanged: widget.onIndexChanged,
                  onBackToLanding: widget.onBackToLanding,
                  onMinimize: () {
                    setState(() {
                      _isMinimized = true;
                    });
                  },
                ),

          // Main Content Area
          Expanded(
            child: Container(color: Colors.white, child: widget.child),
          ),
        ],
      ),
    );
  }
}
