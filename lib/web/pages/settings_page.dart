import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:human_benchmark/models/user_settings.dart';
import 'package:human_benchmark/services/settings_service.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';

class WebSettingsPage extends StatefulWidget {
  const WebSettingsPage({super.key});

  @override
  State<WebSettingsPage> createState() => _WebSettingsPageState();
}

class _WebSettingsPageState extends State<WebSettingsPage> {
  UserSettings? _settings;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await SettingsService.getUserSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load settings: $e');
      }
    }
  }

  Future<void> _updateSetting<T>(String settingKey, T value) async {
    if (_settings == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await SettingsService.updateSetting(settingKey, value);
      if (success) {
        // Update local settings
        if (mounted) {
          setState(() {
            _settings = _settings!.copyWith(
              soundEnabled: settingKey == 'soundEnabled'
                  ? value as bool
                  : _settings!.soundEnabled,
              vibrationEnabled: settingKey == 'vibrationEnabled'
                  ? value as bool
                  : _settings!.vibrationEnabled,
              notificationsEnabled: settingKey == 'notificationsEnabled'
                  ? value as bool
                  : _settings!.notificationsEnabled,
              theme: settingKey == 'theme' ? value as String : _settings!.theme,
              language: settingKey == 'language'
                  ? value as String
                  : _settings!.language,
              autoSaveEnabled: settingKey == 'autoSaveEnabled'
                  ? value as bool
                  : _settings!.autoSaveEnabled,
              showTutorials: settingKey == 'showTutorials'
                  ? value as bool
                  : _settings!.showTutorials,
              updatedAt: DateTime.now(),
            );
          });
          _showSuccessSnackBar('Setting updated successfully');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Failed to update setting');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating setting: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to defaults? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await SettingsService.resetToDefaults();
      if (success) {
        if (mounted) {
          await _loadSettings();
          _showSuccessSnackBar('Settings reset to defaults');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Failed to reset settings');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error resetting settings: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildNotAuthenticatedView();
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_settings == null) {
      return _buildErrorView();
    }

    return _buildSettingsView();
  }

  Widget _buildNotAuthenticatedView() {
    return Scaffold(
      backgroundColor: WebTheme.grey50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
            const Gap(24),
            const Text(
              'Sign in Required',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const Gap(16),
            const Text(
              'Please sign in to access your settings',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(32),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInAnonymously();
                  if (mounted) {
                    await _loadSettings();
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackBar('Failed to sign in: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WebTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Scaffold(
      backgroundColor: WebTheme.grey50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorView() {
    return Scaffold(
      backgroundColor: WebTheme.grey50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
            const Gap(24),
            const Text(
              'Failed to Load Settings',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const Gap(16),
            const Text(
              'Please try again later',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const Gap(32),
            ElevatedButton(
              onPressed: _loadSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: WebTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsView() {
    if (_settings == null) {
      return _buildErrorView();
    }

    return Scaffold(
      backgroundColor: WebTheme.grey50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            _buildUserInfoCard(),
            const Gap(32),

            // General Settings
            _buildSectionHeader('General'),
            _buildSwitchTile(
              'Sound Effects',
              'Enable sound effects in games',
              Icons.volume_up,
              _settings!.soundEnabled,
              (value) => _updateSetting('soundEnabled', value),
            ),
            _buildSwitchTile(
              'Vibration',
              'Enable vibration feedback',
              Icons.vibration,
              _settings!.vibrationEnabled,
              (value) => _updateSetting('vibrationEnabled', value),
            ),
            _buildSwitchTile(
              'Notifications',
              'Enable push notifications',
              Icons.notifications,
              _settings!.notificationsEnabled,
              (value) => _updateSetting('notificationsEnabled', value),
            ),
            _buildSwitchTile(
              'Auto Save',
              'Automatically save game progress',
              Icons.save,
              _settings!.autoSaveEnabled,
              (value) => _updateSetting('autoSaveEnabled', value),
            ),
            _buildSwitchTile(
              'Show Tutorials',
              'Show tutorial hints for new users',
              Icons.help_outline,
              _settings!.showTutorials,
              (value) => _updateSetting('showTutorials', value),
            ),
            const Gap(32),

            // Appearance Settings
            _buildSectionHeader('Appearance'),
            _buildDropdownTile(
              'Theme',
              'Choose your preferred theme',
              Icons.palette,
              _settings!.theme,
              ['system', 'light', 'dark'],
              ['System', 'Light', 'Dark'],
              (value) => _updateSetting('theme', value),
            ),
            _buildDropdownTile(
              'Language',
              'Choose your preferred language',
              Icons.language,
              _settings!.language,
              ['en', 'es', 'fr', 'de'],
              ['English', 'Español', 'Français', 'Deutsch'],
              (value) => _updateSetting('language', value),
            ),
            const Gap(32),

            // Game Settings
            _buildSectionHeader('Game Settings'),
            _buildGameSettingsTile('Reaction Time'),
            _buildGameSettingsTile('Decision Risk'),
            _buildGameSettingsTile('Personality Quiz'),
            const Gap(32),

            // Actions
            _buildSectionHeader('Actions'),
            _buildActionTile(
              'Reset to Defaults',
              'Reset all settings to default values',
              Icons.restore,
              Colors.orange.shade600,
              _resetToDefaults,
            ),
            _buildActionTile(
              'Sign Out',
              'Sign out of your account',
              Icons.logout,
              Colors.red.shade600,
              () async {
                await AuthService.signOut();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            const Gap(32),

            // Settings Info
            _buildSettingsInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (_settings == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: WebTheme.primaryBlue.withValues(alpha: 0.1),
            child: Icon(Icons.person, size: 40, color: WebTheme.primaryBlue),
          ),
          const Gap(24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Anonymous User',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Gap(8),
                Text(
                  user?.email ?? 'No email',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Gap(8),
                Text(
                  _formatDate(_settings!.updatedAt),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    color: WebTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        secondary: Icon(icon, color: WebTheme.primaryBlue, size: 28),
        value: value,
        onChanged: _isUpdating ? null : onChanged,
        activeColor: WebTheme.primaryBlue,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String currentValue,
    List<String> values,
    List<String> displayNames,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        leading: Icon(icon, color: WebTheme.primaryBlue, size: 28),
        trailing: DropdownButton<String>(
          value: currentValue,
          onChanged: _isUpdating
              ? null
              : (value) {
                  if (value != null) onChanged(value);
                },
          items: values.asMap().entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.value,
              child: Text(
                displayNames[entry.key],
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
              ),
            );
          }).toList(),
          underline: Container(),
        ),
      ),
    );
  }

  Widget _buildGameSettingsTile(String gameName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          gameName,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Customize $gameName settings',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        leading: Icon(Icons.settings, color: WebTheme.primaryBlue, size: 28),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () {
          // TODO: Navigate to game-specific settings
          _showComingSoonSnackBar();
        },
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        leading: Icon(icon, color: color, size: 28),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: _isUpdating ? null : onTap,
      ),
    );
  }

  Widget _buildSettingsInfoCard() {
    if (_settings == null) return const SizedBox.shrink();

    final summary = SettingsService.getSettingsSummary(_settings);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: WebTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: WebTheme.primaryBlue, size: 32),
              const Gap(16),
              Text(
                'Settings Summary',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: WebTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const Gap(24),
          _buildInfoRow('Status', summary['status']),
          _buildInfoRow('Theme', summary['theme']),
          _buildInfoRow('Language', summary['language']),
          _buildInfoRow('Sound', summary['sound']),
          _buildInfoRow('Notifications', summary['notifications']),
          _buildInfoRow('Last Updated', summary['lastUpdated']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: WebTheme.primaryBlue,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Colors.blue.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Game-specific settings coming soon!',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
