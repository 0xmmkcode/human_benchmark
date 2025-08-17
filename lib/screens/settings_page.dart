import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../services/account_service.dart';
import '../services/data_export_service.dart';
import '../services/auth_service.dart';
import '../widgets/user_avatar.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _usernameController = TextEditingController();
  DateTime? _selectedBirthday;
  bool _isLoading = false;
  bool _isExporting = false;
  Map<String, dynamic>? _userStats;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load current username
      final currentName = AccountService.getCurrentDisplayName();
      _usernameController.text = currentName ?? '';

      // Load birthday
      final birthday = await AccountService.getBirthday();
      if (birthday != null) {
        _selectedBirthday = birthday;
      }

      // Load user statistics
      final stats = await DataExportService.getUserStatistics();
      setState(() {
        _userStats = stats;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load user data');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      _showErrorSnackBar('Username cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AccountService.updateDisplayName(newUsername);
      if (success) {
        _showSuccessSnackBar('Username updated successfully');
        // Refresh user data
        await _loadUserData();
      } else {
        _showErrorSnackBar('Failed to update username');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating username');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });

      try {
        final success = await AccountService.updateBirthday(picked);
        if (success) {
          _showSuccessSnackBar('Birthday updated successfully');
        } else {
          _showErrorSnackBar('Failed to update birthday');
        }
      } catch (e) {
        _showErrorSnackBar('Error updating birthday');
      }
    }
  }

  Future<void> _exportDataAsJson() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final jsonData = await DataExportService.exportUserDataAsJson();
      await Share.share(jsonData, subject: 'Human Benchmark Data Export (JSON)');
      _showSuccessSnackBar('Data exported as JSON successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to export data as JSON');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _exportDataAsCsv() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final csvData = await DataExportService.exportUserDataAsCsv();
      await Share.share(csvData, subject: 'Human Benchmark Data Export (CSV)');
      _showSuccessSnackBar('Data exported as CSV successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to export data as CSV');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data, scores, and settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await AccountService.deleteAccount();
        if (success) {
          _showSuccessSnackBar('Account deleted successfully');
          // Navigate to home or sign out
          await AuthService.signOut();
        } else {
          _showErrorSnackBar('Failed to delete account');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting account');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildNotAuthenticatedView();
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    return _buildSettingsView();
  }

  Widget _buildNotAuthenticatedView() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const Gap(24),
            Text(
              'Sign in Required',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const Gap(16),
            Text(
              'Please sign in to access your settings',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildSettingsView() {
    final user = FirebaseAuth.instance.currentUser!;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              _buildProfileSection(user),
              const Gap(24),

              // Account Settings Section
              _buildAccountSettingsSection(),
              const Gap(24),

              // Data Export Section
              _buildDataExportSection(),
              const Gap(24),

              // Statistics Section
              if (_userStats != null) ...[
                _buildStatisticsSection(),
                const Gap(24),
              ],

              // Danger Zone Section
              _buildDangerZoneSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(
            radius: 40,
            photoURL: user.photoURL,
            displayName: user.displayName,
            email: user.email,
            borderColor: Colors.blue.shade200,
            borderWidth: 2,
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'User',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Gap(4),
                Text(
                  user.email ?? 'No email',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (user.emailVerified) ...[
                  const Gap(4),
                  Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.green.shade600),
                      const Gap(4),
                      Text(
                        'Email verified',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const Gap(20),

          // Username
          Text(
            'Username',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Enter username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const Gap(12),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateUsername,
                child: const Text('Update'),
              ),
            ],
          ),
          const Gap(20),

          // Birthday
          Text(
            'Birthday',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const Gap(8),
          InkWell(
            onTap: _selectBirthday,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey.shade600),
                  const Gap(8),
                  Text(
                    _selectedBirthday != null
                        ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                        : 'Select birthday',
                    style: TextStyle(
                      color: _selectedBirthday != null
                          ? Colors.grey.shade800
                          : Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataExportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Export',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const Gap(8),
          Text(
            'Export your data in different formats',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Gap(20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportDataAsJson,
                  icon: const Icon(Icons.code),
                  label: const Text('Export as JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportDataAsCsv,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export as CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (_isExporting) ...[
            const Gap(16),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Gap(8),
                  Text('Exporting data...'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    if (_userStats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Statistics',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const Gap(20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Games',
                  '${_userStats!['totalGames']}',
                  Icons.games,
                  Colors.blue.shade600,
                ),
              ),
              const Gap(16),
              Expanded(
                child: _buildStatCard(
                  'High Scores',
                  '${_userStats!['highScores']}',
                  Icons.emoji_events,
                  Colors.amber.shade600,
                ),
              ),
              const Gap(16),
              Expanded(
                child: _buildStatCard(
                  'Avg Score',
                  '${_userStats!['averageScore']}',
                  Icons.trending_up,
                  Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const Gap(8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(4),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600),
              const Gap(8),
              Text(
                'Danger Zone',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            'These actions cannot be undone',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.red.shade600,
            ),
          ),
          const Gap(20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _deleteAccount,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
