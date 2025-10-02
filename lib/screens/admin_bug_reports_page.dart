import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../models/bug_report.dart';
import '../services/bug_report_service.dart';
import '../widgets/brain_theme.dart';

class AdminBugReportsPage extends StatefulWidget {
  const AdminBugReportsPage({super.key});

  @override
  State<AdminBugReportsPage> createState() => _AdminBugReportsPageState();
}

class _AdminBugReportsPageState extends State<AdminBugReportsPage> {
  String _selectedStatus = 'all';
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await BugReportService.getBugReportStats();
    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Bug Reports Admin',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey[800],
      ),
      body: Column(
        children: [
          // Stats cards
          Container(
            padding: EdgeInsets.all(horizontalPadding),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    _stats['total']?.toString() ?? '0',
                    Colors.blue,
                    Icons.bug_report,
                    isMobile,
                  ),
                ),
                Gap(12),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    _stats['pending']?.toString() ?? '0',
                    Colors.orange,
                    Icons.pending,
                    isMobile,
                  ),
                ),
                Gap(12),
                Expanded(
                  child: _buildStatCard(
                    'Resolved',
                    _stats['resolved']?.toString() ?? '0',
                    Colors.green,
                    Icons.check_circle,
                    isMobile,
                  ),
                ),
              ],
            ),
          ),

          // Filter dropdown
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Row(
              children: [
                Text(
                  'Filter by status:',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Gap(12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Reports'),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'in_progress',
                            child: Text('In Progress'),
                          ),
                          DropdownMenuItem(
                            value: 'resolved',
                            child: Text('Resolved'),
                          ),
                          DropdownMenuItem(
                            value: 'closed',
                            child: Text('Closed'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bug reports list
          Expanded(
            child: StreamBuilder<List<BugReport>>(
              stream: BugReportService.getAllBugReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        BrainTheme.primaryBrain,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        Gap(16),
                        Text(
                          'Error loading bug reports',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allReports = snapshot.data ?? [];
                final filteredReports = _selectedStatus == 'all'
                    ? allReports
                    : allReports
                          .where((report) => report.status == _selectedStatus)
                          .toList();

                if (filteredReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        Gap(16),
                        Text(
                          'No bug reports found',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return _buildAdminReportCard(context, report, isMobile);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 24 : 28),
          Gap(8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 12 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminReportCard(
    BuildContext context,
    BugReport report,
    bool isMobile,
  ) {
    final statusColor = _getStatusColor(report.status);
    final severityColor = _getSeverityColor(report.severity);

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BrainTheme.brainCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          Gap(isMobile ? 8 : 12),

          // Description
          Text(
            report.description,
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          Gap(isMobile ? 12 : 16),

          // Details row
          Row(
            children: [
              _buildDetailChip(
                icon: Icons.category,
                label: _getCategoryDisplayName(report.category),
                color: Colors.blue,
                isMobile: isMobile,
              ),
              Gap(8),
              _buildDetailChip(
                icon: Icons.priority_high,
                label: _getSeverityDisplayName(report.severity),
                color: severityColor,
                isMobile: isMobile,
              ),
              Gap(8),
              _buildDetailChip(
                icon: Icons.person,
                label: 'User: ${report.userId.substring(0, 8)}...',
                color: Colors.grey,
                isMobile: isMobile,
              ),
            ],
          ),

          Gap(isMobile ? 8 : 12),

          // Footer row
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: isMobile ? 14 : 16,
                color: Colors.grey[500],
              ),
              Gap(4),
              Text(
                _formatDate(report.createdAt),
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[500],
                ),
              ),
              Spacer(),
              // Action buttons
              Row(
                children: [
                  if (report.status == 'pending') ...[
                    TextButton.icon(
                      onPressed: () => _updateStatus(report.id, 'in_progress'),
                      icon: Icon(Icons.play_arrow, size: 16),
                      label: Text('Start'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                  if (report.status == 'in_progress') ...[
                    TextButton.icon(
                      onPressed: () => _updateStatus(report.id, 'resolved'),
                      icon: Icon(Icons.check, size: 16),
                      label: Text('Resolve'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                  if (report.status == 'resolved') ...[
                    TextButton.icon(
                      onPressed: () => _updateStatus(report.id, 'closed'),
                      icon: Icon(Icons.close, size: 16),
                      label: Text('Close'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 12 : 14, color: color),
          Gap(4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String reportId, String status) async {
    try {
      final bugStatus = BugStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => BugStatus.pending,
      );

      await BugReportService.updateBugReportStatus(
        reportId: reportId,
        status: bugStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${bugStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryDisplayName(String category) {
    return BugCategory.values
        .firstWhere((c) => c.name == category, orElse: () => BugCategory.other)
        .displayName;
  }

  String _getSeverityDisplayName(String severity) {
    return BugSeverity.values
        .firstWhere((s) => s.name == severity, orElse: () => BugSeverity.medium)
        .displayName;
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
