import 'package:flutter/material.dart';
import 'package:human_benchmark/services/web_settings_service.dart';
import 'package:human_benchmark/models/web_settings.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';
import 'package:human_benchmark/services/admin_service.dart';

class AdminWebSettingsPage extends StatefulWidget {
  const AdminWebSettingsPage({Key? key}) : super(key: key);

  @override
  State<AdminWebSettingsPage> createState() => _AdminWebSettingsPageState();
}

class _AdminWebSettingsPageState extends State<AdminWebSettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  WebSettings? _currentSettings;
  final _playStoreLinkController = TextEditingController();
  bool _webGameEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadWebSettings();
  }

  @override
  void dispose() {
    _playStoreLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadWebSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await WebSettingsService.getWebSettings();
      setState(() {
        _currentSettings = settings;
        _webGameEnabled = settings.webGameEnabled;
        _playStoreLinkController.text = settings.playStoreLink ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load web settings: $e');
    }
  }

  Future<void> _saveWebSettings() async {
    if (!await AdminService.isCurrentUserAdmin()) {
      _showErrorSnackBar('You do not have admin privileges');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await WebSettingsService.updateWebSettings(
        webGameEnabled: _webGameEnabled,
        playStoreLink: _playStoreLinkController.text.trim().isEmpty
            ? null
            : _playStoreLinkController.text.trim(),
      );

      if (success) {
        _showSuccessSnackBar('Web settings updated successfully');
        await _loadWebSettings(); // Reload to get updated data
      } else {
        _showErrorSnackBar('Failed to update web settings');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating web settings: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Web Settings',
          style: WebTheme.headingMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WebTheme.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  PageHeader(
                    title: 'Manage Web Game Access',
                    subtitle:
                        'Control whether users can access the web game or be redirected to the mobile app',
                  ),
                  const SizedBox(height: 32),

                  // Web Game Toggle
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.web,
                                color: WebTheme.primaryBlue,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Web Game Access',
                                      style: WebTheme.headingMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Enable or disable access to the web version of the game',
                                      style: WebTheme.bodyMedium.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SwitchListTile(
                            title: Text(
                              _webGameEnabled
                                  ? 'Web Game Enabled'
                                  : 'Web Game Disabled',
                              style: WebTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _webGameEnabled
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                            subtitle: Text(
                              _webGameEnabled
                                  ? 'Users can play the game directly on the web'
                                  : 'Users will be redirected to download the mobile app',
                              style: WebTheme.bodyMedium.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            value: _webGameEnabled,
                            onChanged: (value) {
                              setState(() {
                                _webGameEnabled = value;
                              });
                            },
                            activeColor: WebTheme.primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Play Store Link
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.smartphone,
                                color: WebTheme.primaryBlue,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mobile App Link',
                                      style: WebTheme.headingMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'URL where users will be redirected when web game is disabled',
                                      style: WebTheme.bodyMedium.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _playStoreLinkController,
                            decoration: InputDecoration(
                              labelText: 'Play Store Link',
                              hintText:
                                  'https://play.google.com/store/apps/details?id=...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.link),
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Leave empty to use the default Play Store link',
                            style: WebTheme.bodySmall.copyWith(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Current Status
                  if (_currentSettings != null) ...[
                    Card(
                      elevation: 1,
                      color: Colors.grey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Settings',
                              style: WebTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStatusRow(
                              'Web Game Status',
                              _currentSettings!.webGameEnabled
                                  ? 'Enabled'
                                  : 'Disabled',
                              _currentSettings!.webGameEnabled
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            _buildStatusRow(
                              'Play Store Link',
                              _currentSettings!.playStoreLink ?? 'Default',
                              Colors.blue,
                            ),
                            _buildStatusRow(
                              'Last Updated',
                              _formatDate(_currentSettings!.updatedAt),
                              Colors.grey[600]!,
                            ),
                            _buildStatusRow(
                              'Updated By',
                              _currentSettings!.updatedBy,
                              Colors.grey[600]!,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveWebSettings,
                      style: WebTheme.largePrimaryButton.copyWith(
                        backgroundColor: MaterialStateProperty.all(
                          WebTheme.primaryBlue,
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: WebTheme.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: WebTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: WebTheme.bodyMedium.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
