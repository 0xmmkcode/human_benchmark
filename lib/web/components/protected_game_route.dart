import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/route_protection_service.dart';

class ProtectedGameRoute extends ConsumerStatefulWidget {
  final String gameId;
  final Widget child;

  const ProtectedGameRoute({
    super.key,
    required this.gameId,
    required this.child,
  });

  @override
  ConsumerState<ProtectedGameRoute> createState() => _ProtectedGameRouteState();
}

class _ProtectedGameRouteState extends ConsumerState<ProtectedGameRoute> {
  bool _isLoading = true;
  bool _isGameEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkGameAccess();
  }

  Future<void> _checkGameAccess() async {
    try {
      final isEnabled = await RouteProtectionService.isGameRouteAccessible(
        widget.gameId,
      );
      setState(() {
        _isGameEnabled = isEnabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isGameEnabled = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isGameEnabled) {
      // Game is disabled - show nothing or redirect to dashboard
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Game Not Available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This game is currently disabled.',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to dashboard instead
                  Navigator.of(context).pushReplacementNamed('/app/dashboard');
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
