import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/services/settings_service.dart';

class WebSettingsPage extends StatefulWidget {
  const WebSettingsPage({super.key});

  @override
  State<WebSettingsPage> createState() => _WebSettingsPageState();
}

class _WebSettingsPageState extends State<WebSettingsPage> {
  bool _showNameInLeaderboard = true;
  bool _anonymousMode = false;
  String? _customDisplayName;
  final TextEditingController _displayNameController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final showName = await SettingsService.getShowNameInLeaderboard();
      final anonymousMode = await SettingsService.getAnonymousMode();
      final displayName = await SettingsService.getDisplayName();

      setState(() {
        _showNameInLeaderboard = showName;
        _anonymousMode = anonymousMode;
        _customDisplayName = displayName;
        _displayNameController.text = displayName ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
      }
    }
  }

  Future<void> _updateShowNameInLeaderboard(bool value) async {
    try {
      await SettingsService.setShowNameInLeaderboard(value);
      setState(() => _showNameInLeaderboard = value);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Setting updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update setting: $e')));
      }
    }
  }

  Future<void> _updateAnonymousMode(bool value) async {
    try {
      await SettingsService.setAnonymousMode(value);
      setState(() => _anonymousMode = value);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Setting updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update setting: $e')));
      }
    }
  }

  Future<void> _updateDisplayName(String? name) async {
    try {
      await SettingsService.setDisplayName(name);
      setState(() => _customDisplayName = name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Display name updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update display name: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Customize your privacy and display preferences',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Gap(48),

                    // Leaderboard Settings Section
                    _buildSectionHeader('Leaderboard Settings'),
                    const Gap(24),

                    // Show Name in Leaderboard
                    _buildSwitchTile(
                      title: 'Show Name in Leaderboard',
                      subtitle: 'Display your name in public leaderboards',
                      value: _showNameInLeaderboard,
                      onChanged: _updateShowNameInLeaderboard,
                    ),

                    const Gap(20),

                    // Anonymous Mode
                    _buildSwitchTile(
                      title: 'Anonymous Mode',
                      subtitle: 'Hide your identity in all leaderboards',
                      value: _anonymousMode,
                      onChanged: _updateAnonymousMode,
                    ),

                    const Gap(32),

                    // Custom Display Name
                    if (_showNameInLeaderboard && !_anonymousMode) ...[
                      _buildSectionHeader('Display Name'),
                      const Gap(24),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Display Name',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              'This name will be shown in leaderboards instead of your real name',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Gap(20),
                            TextField(
                              controller: _displayNameController,
                              decoration: InputDecoration(
                                hintText: 'Enter display name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (value) {
                                // Update in real-time as user types
                                _updateDisplayName(
                                  value.isEmpty ? null : value,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Gap(48),

                    // Info Section
                    _buildSectionHeader('How It Works'),
                    const Gap(24),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[600],
                                size: 24,
                              ),
                              const Gap(12),
                              Text(
                                'Privacy Information',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          const Gap(16),
                          Text(
                            '• Your real name is never shared publicly\n'
                            '• Anonymous mode hides your identity completely\n'
                            '• Custom display names are stored locally\n'
                            '• Settings apply to all games and leaderboards\n'
                            '• Changes take effect immediately',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.blue[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(6),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.2,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }
}
