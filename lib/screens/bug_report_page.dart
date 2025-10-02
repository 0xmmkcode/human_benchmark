import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../models/bug_report.dart';
import '../services/bug_report_service.dart';
import '../widgets/brain_theme.dart';

class BugReportPage extends StatefulWidget {
  const BugReportPage({super.key});

  @override
  State<BugReportPage> createState() => _BugReportPageState();
}

class _BugReportPageState extends State<BugReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  BugCategory _selectedCategory = BugCategory.other;
  BugSeverity _selectedSeverity = BugSeverity.medium;

  bool _isSubmitting = false;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _checkRateLimit();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkRateLimit() async {
    try {
      final canSubmit = await BugReportService.canSubmitBugReport();

      print('Rate limit check - Can submit: $canSubmit');

      setState(() {
        _canSubmit = canSubmit;
      });
    } catch (e) {
      print('Error checking rate limit: $e');
      setState(() {
        _canSubmit = false;
      });
    }
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Check rate limit before submitting
      final canSubmit = await BugReportService.canSubmitBugReport();
      if (!canSubmit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Rate limit exceeded. You can only submit 2 bug reports per day.',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await BugReportService.submitBugReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        severity: _selectedSeverity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bug report submitted successfully!',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reset form
        _titleController.clear();
        _descriptionController.clear();
        _selectedCategory = BugCategory.other;
        _selectedSeverity = BugSeverity.medium;

        // Update rate limit
        await _checkRateLimit();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit bug report: ${e.toString()}',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
          'Report a Bug',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey[800],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rate limit info
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BrainTheme.brainCard,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _canSubmit ? Colors.blue : Colors.orange,
                    size: isMobile ? 20 : 24,
                  ),
                  Gap(isMobile ? 8 : 12),
                  Expanded(
                    child: Text(
                      'You can submit up to 2 bug reports per day',
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Gap(isMobile ? 16 : 20),

            // Bug report form
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BrainTheme.brainCard,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bug Report Details',
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),

                    Gap(isMobile ? 16 : 20),

                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        hintText: 'Brief description of the issue',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 5) {
                          return 'Title must be at least 5 characters';
                        }
                        return null;
                      },
                    ),

                    Gap(isMobile ? 16 : 20),

                    // Category dropdown
                    Text(
                      'Category *',
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Gap(8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<BugCategory>(
                          value: _selectedCategory,
                          isExpanded: true,
                          items: BugCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category.displayName,
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    Gap(isMobile ? 16 : 20),

                    // Severity dropdown
                    Text(
                      'Severity *',
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Gap(8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<BugSeverity>(
                          value: _selectedSeverity,
                          isExpanded: true,
                          items: BugSeverity.values.map((severity) {
                            return DropdownMenuItem(
                              value: severity,
                              child: Text(
                                severity.displayName,
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSeverity = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    Gap(isMobile ? 16 : 20),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText:
                            'Please provide detailed information about the bug:\n• What happened?\n• What did you expect to happen?\n• Steps to reproduce the issue\n• Any error messages you saw',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.trim().length < 20) {
                          return 'Description must be at least 20 characters';
                        }
                        return null;
                      },
                    ),

                    Gap(isMobile ? 20 : 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: isMobile ? 48 : 52,
                      child: ElevatedButton(
                        onPressed: !_isSubmitting
                            ? () => _submitBugReport()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrainTheme.primaryBrain,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  Gap(12),
                                  Text(
                                    'Submitting...',
                                    style: GoogleFonts.montserrat(
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Submit Bug Report',
                                style: GoogleFonts.montserrat(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
