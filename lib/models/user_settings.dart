import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettings {
  final String userId;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final String theme;
  final String language;
  final bool autoSaveEnabled;
  final bool showTutorials;
  final Map<String, dynamic> gameSpecificSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSettings({
    required this.userId,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.notificationsEnabled = true,
    this.theme = 'system',
    this.language = 'en',
    this.autoSaveEnabled = true,
    this.showTutorials = true,
    this.gameSpecificSettings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings.defaults(String userId) {
    final now = DateTime.now();
    return UserSettings(
      userId: userId,
      soundEnabled: true,
      vibrationEnabled: true,
      notificationsEnabled: true,
      theme: 'system',
      language: 'en',
      autoSaveEnabled: true,
      showTutorials: true,
      gameSpecificSettings: {
        'reactionTime': {
          'rounds': 5,
          'showMilliseconds': true,
          'difficulty': 'normal',
        },
        'decisionRisk': {
          'showProbability': true,
          'autoAdvance': false,
        },
        'personalityQuiz': {
          'showProgress': true,
          'saveAnswers': true,
        },
      },
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      userId: map['userId'] as String,
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      vibrationEnabled: map['vibrationEnabled'] as bool? ?? true,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      theme: map['theme'] as String? ?? 'system',
      language: map['language'] as String? ?? 'en',
      autoSaveEnabled: map['autoSaveEnabled'] as bool? ?? true,
      showTutorials: map['showTutorials'] as bool? ?? true,
      gameSpecificSettings: Map<String, dynamic>.from(
        map['gameSpecificSettings'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'notificationsEnabled': notificationsEnabled,
      'theme': theme,
      'language': language,
      'autoSaveEnabled': autoSaveEnabled,
      'showTutorials': showTutorials,
      'gameSpecificSettings': gameSpecificSettings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserSettings copyWith({
    String? userId,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    String? theme,
    String? language,
    bool? autoSaveEnabled,
    bool? showTutorials,
    Map<String, dynamic>? gameSpecificSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      showTutorials: showTutorials ?? this.showTutorials,
      gameSpecificSettings: gameSpecificSettings ?? this.gameSpecificSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for game-specific settings
  Map<String, dynamic> getGameSettings(String gameType) {
    return gameSpecificSettings[gameType] as Map<String, dynamic>? ?? {};
  }

  UserSettings updateGameSettings(String gameType, Map<String, dynamic> settings) {
    final newGameSettings = Map<String, dynamic>.from(gameSpecificSettings);
    newGameSettings[gameType] = settings;
    
    return copyWith(
      gameSpecificSettings: newGameSettings,
      updatedAt: DateTime.now(),
    );
  }

  // Theme helpers
  bool get isDarkMode => theme == 'dark';
  bool get isLightMode => theme == 'light';
  bool get isSystemTheme => theme == 'system';

  // Language helpers
  bool get isEnglish => language == 'en';
  bool get isSpanish => language == 'es';
  bool get isFrench => language == 'fr';
  bool get isGerman => language == 'de';

  @override
  String toString() {
    return 'UserSettings(userId: $userId, soundEnabled: $soundEnabled, theme: $theme, language: $language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettings &&
        other.userId == userId &&
        other.soundEnabled == soundEnabled &&
        other.vibrationEnabled == vibrationEnabled &&
        other.notificationsEnabled == notificationsEnabled &&
        other.theme == theme &&
        other.language == language &&
        other.autoSaveEnabled == autoSaveEnabled &&
        other.showTutorials == showTutorials;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        soundEnabled.hashCode ^
        vibrationEnabled.hashCode ^
        notificationsEnabled.hashCode ^
        theme.hashCode ^
        language.hashCode ^
        autoSaveEnabled.hashCode ^
        showTutorials.hashCode;
  }
}
