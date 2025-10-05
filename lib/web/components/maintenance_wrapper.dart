import 'package:flutter/material.dart';
import 'package:human_benchmark/services/maintenance_service.dart';
import 'package:human_benchmark/web/widgets/app_loading.dart';
import 'package:human_benchmark/web/pages/maintenance_page.dart';

class MaintenanceWrapper extends StatefulWidget {
  final Widget child;
  final bool showMaintenancePage;

  const MaintenanceWrapper({
    super.key,
    required this.child,
    this.showMaintenancePage = false,
  });

  @override
  State<MaintenanceWrapper> createState() => _MaintenanceWrapperState();
}

class _MaintenanceWrapperState extends State<MaintenanceWrapper> {
  bool _isMaintenanceMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkMaintenanceStatus();
  }

  Future<void> _checkMaintenanceStatus() async {
    try {
      final isMaintenance = await MaintenanceService.isMaintenanceMode();
      if (mounted) {
        setState(() {
          _isMaintenanceMode = isMaintenance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMaintenanceMode = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking maintenance status
    if (_isLoading) {
      return const Scaffold(body: Center(child: AppLoading()));
    }

    // Show maintenance page if in maintenance mode or explicitly requested
    if (_isMaintenanceMode || widget.showMaintenancePage) {
      return const MaintenancePage();
    }

    // Show the normal app content
    return widget.child;
  }
}
