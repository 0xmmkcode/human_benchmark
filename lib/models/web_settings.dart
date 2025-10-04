import 'package:cloud_firestore/cloud_firestore.dart';

class WebSettings {
  final bool webGameEnabled;
  final String? playStoreLink;
  final DateTime updatedAt;
  final String updatedBy;

  const WebSettings({
    required this.webGameEnabled,
    this.playStoreLink,
    required this.updatedAt,
    required this.updatedBy,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'webGameEnabled': webGameEnabled,
      'playStoreLink': playStoreLink,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  factory WebSettings.fromMap(Map<String, Object?> data) {
    return WebSettings(
      webGameEnabled: data['webGameEnabled'] as bool? ?? false,
      playStoreLink: data['playStoreLink'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'] as String,
    );
  }

  WebSettings copyWith({
    bool? webGameEnabled,
    String? playStoreLink,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return WebSettings(
      webGameEnabled: webGameEnabled ?? this.webGameEnabled,
      playStoreLink: playStoreLink ?? this.playStoreLink,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // Default settings
  static WebSettings get defaultSettings => WebSettings(
    webGameEnabled: true,
    playStoreLink:
        'https://play.google.com/store/apps/details?id=xyz.mmkcode.humanbenchmark.human_benchmark',
    updatedAt: DateTime.now(),
    updatedBy: 'system',
  );
}
