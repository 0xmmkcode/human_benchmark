import 'package:cloud_firestore/cloud_firestore.dart';

class BugReport {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String severity;
  final String deviceInfo;
  final String appVersion;
  final List<String> attachments; // URLs to uploaded files
  final String status; // 'pending', 'in_progress', 'resolved', 'closed'
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedTo; // Admin user ID

  BugReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.deviceInfo,
    required this.appVersion,
    this.attachments = const [],
    this.status = 'pending',
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
  });

  factory BugReport.fromMap(Map<String, dynamic> map) {
    return BugReport(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      severity: map['severity'] ?? '',
      deviceInfo: map['deviceInfo'] ?? '',
      appVersion: map['appVersion'] ?? '',
      attachments: List<String>.from(map['attachments'] ?? []),
      status: map['status'] ?? 'pending',
      adminNotes: map['adminNotes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      assignedTo: map['assignedTo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'severity': severity,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'attachments': attachments,
      'status': status,
      'adminNotes': adminNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignedTo': assignedTo,
    };
  }

  BugReport copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    String? severity,
    String? deviceInfo,
    String? appVersion,
    List<String>? attachments,
    String? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedTo,
  }) {
    return BugReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}

enum BugCategory {
  uiIssue('UI/UX Issue'),
  performance('Performance'),
  crash('App Crash'),
  featureRequest('Feature Request'),
  dataIssue('Data Issue'),
  loginIssue('Login/Authentication'),
  gameIssue('Game Specific'),
  other('Other');

  const BugCategory(this.displayName);
  final String displayName;
}

enum BugSeverity {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  const BugSeverity(this.displayName);
  final String displayName;
}

enum BugStatus {
  pending('Pending'),
  inProgress('In Progress'),
  resolved('Resolved'),
  closed('Closed');

  const BugStatus(this.displayName);
  final String displayName;
}
