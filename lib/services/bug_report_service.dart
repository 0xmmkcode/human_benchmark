import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/bug_report.dart';

class BugReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collectionName = 'bug_reports';
  static const String _rateLimitCollectionName = 'bug_report_rate_limits';
  static const int _maxReportsPerDay = 2;

  // Submit a new bug report
  static Future<String> submitBugReport({
    required String title,
    required String description,
    required BugCategory category,
    required BugSeverity severity,
    List<String> attachments = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to submit a bug report');
      }

      print('Submitting bug report for user: ${user.uid}');
      print('Title: $title');
      print('Category: ${category.name}, Severity: ${severity.name}');

      // Check rate limit (currently disabled for testing)
      final canSubmit = await canSubmitBugReport();
      if (!canSubmit) {
        throw Exception(
          'Rate limit exceeded. You can only submit 2 bug reports per day.',
        );
      }

      // Get device and app information
      final deviceInfo = await _getDeviceInfo();
      final appVersion = await _getAppVersion();

      print('Device info: $deviceInfo');
      print('App version: $appVersion');

      // Create bug report
      final bugReport = BugReport(
        id: _firestore.collection(_collectionName).doc().id,
        userId: user.uid,
        title: title,
        description: description,
        category: category.name,
        severity: severity.name,
        deviceInfo: deviceInfo,
        appVersion: appVersion,
        attachments: attachments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('Created bug report with ID: ${bugReport.id}');

      // Save to Firebase
      await _firestore
          .collection(_collectionName)
          .doc(bugReport.id)
          .set(bugReport.toMap());

      print('Bug report saved to Firebase successfully');

      // Update rate limit
      await _updateRateLimit(user.uid);

      print('Bug report submitted successfully: ${bugReport.id}');
      return bugReport.id;
    } catch (e) {
      print('Error submitting bug report: $e');
      rethrow;
    }
  }

  // Get bug reports for current user
  static Stream<List<BugReport>> getUserBugReports() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BugReport.fromMap(doc.data()))
                .toList(),
          );
    } catch (e) {
      print('Error getting user bug reports: $e');
      return Stream.value([]);
    }
  }

  // Get all bug reports (admin only)
  static Stream<List<BugReport>> getAllBugReports() {
    try {
      return _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BugReport.fromMap(doc.data()))
                .toList(),
          );
    } catch (e) {
      print('Error getting all bug reports: $e');
      return Stream.value([]);
    }
  }

  // Update bug report status (admin only)
  static Future<void> updateBugReportStatus({
    required String reportId,
    required BugStatus status,
    String? adminNotes,
    String? assignedTo,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(reportId).update({
        'status': status.name,
        'adminNotes': adminNotes,
        'assignedTo': assignedTo,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('Bug report status updated: $reportId to ${status.name}');
    } catch (e) {
      print('Error updating bug report status: $e');
      rethrow;
    }
  }

  // Check if user can submit a bug report (rate limiting)
  static Future<bool> canSubmitBugReport() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated, cannot submit bug report');
        return false;
      }

      // Check rate limit with proper error handling
      final canSubmit = await _checkRateLimit(user.uid);
      print('Rate limit check result: $canSubmit');
      return canSubmit;
    } catch (e) {
      print('Error checking if can submit bug report: $e');
      // Return true on error to allow submission (fail open)
      return true;
    }
  }

  // Get remaining reports for today
  static Future<int> getRemainingReportsToday() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final reportsToday = snapshot.docs.length;
      return _maxReportsPerDay - reportsToday;
    } catch (e) {
      print('Error getting remaining reports today: $e');
      return 0;
    }
  }

  // Private helper methods
  static Future<bool> _checkRateLimit(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print('Checking rate limit for user: $userId');
      print('Date range: $startOfDay to $endOfDay');

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final reportsToday = snapshot.docs.length;
      final canSubmit = reportsToday < _maxReportsPerDay;

      print(
        'Reports today: $reportsToday, Max allowed: $_maxReportsPerDay, Can submit: $canSubmit',
      );

      return canSubmit;
    } catch (e) {
      print('Error checking rate limit: $e');
      // Return true on error to allow submission (fail open)
      return true;
    }
  }

  static Future<void> _updateRateLimit(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      await _firestore
          .collection(_rateLimitCollectionName)
          .doc('${userId}_${startOfDay.millisecondsSinceEpoch}')
          .set({
            'userId': userId,
            'date': Timestamp.fromDate(startOfDay),
            'count': FieldValue.increment(1),
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      print('Error updating rate limit: $e');
    }
  }

  static Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else {
        return 'Web Browser';
      }
    } catch (e) {
      return 'Device info unavailable';
    }
  }

  static Future<String> _getAppVersion() async {
    try {
      return '1.0.0 (1)';
    } catch (e) {
      return 'Version unavailable';
    }
  }

  // Delete bug report (admin only)
  static Future<void> deleteBugReport(String reportId) async {
    try {
      await _firestore.collection(_collectionName).doc(reportId).delete();
      print('Bug report deleted: $reportId');
    } catch (e) {
      print('Error deleting bug report: $e');
      rethrow;
    }
  }

  // Get bug report by ID
  static Future<BugReport?> getBugReportById(String reportId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(reportId)
          .get();
      if (doc.exists) {
        return BugReport.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting bug report by ID: $e');
      return null;
    }
  }

  // Get bug report statistics (admin only)
  static Future<Map<String, int>> getBugReportStats() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final reports = snapshot.docs
          .map((doc) => BugReport.fromMap(doc.data()))
          .toList();

      final stats = <String, int>{
        'total': reports.length,
        'pending': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (final report in reports) {
        stats[report.status] = (stats[report.status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting bug report stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
      };
    }
  }

  // Test method to verify the system is working
  static Future<bool> testBugReportSystem() async {
    try {
      print('Testing bug report system...');

      // Test 1: Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Test failed: User not authenticated');
        return false;
      }
      print('✅ Test passed: User authenticated (${user.uid})');

      // Test 2: Check if can submit
      final canSubmit = await canSubmitBugReport();
      if (!canSubmit) {
        print('❌ Test failed: Cannot submit bug report');
        return false;
      }
      print('✅ Test passed: Can submit bug report');

      // Test 3: Try to submit a test report
      try {
        final testId = await submitBugReport(
          title: 'Test Bug Report',
          description:
              'This is a test bug report to verify the system is working.',
          category: BugCategory.other,
          severity: BugSeverity.low,
        );
        print(
          '✅ Test passed: Successfully submitted test bug report (ID: $testId)',
        );
        return true;
      } catch (e) {
        print('❌ Test failed: Could not submit test bug report: $e');
        return false;
      }
    } catch (e) {
      print('❌ Test failed: System error: $e');
      return false;
    }
  }
}
