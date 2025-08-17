import 'package:cloud_firestore/cloud_firestore.dart';

class GameManagement {
  final String gameId;
  final String gameName;
  final String gameType;
  final bool isEnabled;
  final String description;
  final String icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;

  const GameManagement({
    required this.gameId,
    required this.gameName,
    required this.gameType,
    required this.isEnabled,
    required this.description,
    required this.icon,
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
  });

  factory GameManagement.fromMap(Map<String, dynamic> map) {
    return GameManagement(
      gameId: map['gameId'] ?? '',
      gameName: map['gameName'] ?? '',
      gameType: map['gameType'] ?? '',
      isEnabled: map['isEnabled'] ?? false,
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      updatedBy: map['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'gameName': gameName,
      'gameType': gameType,
      'isEnabled': isEnabled,
      'description': description,
      'icon': icon,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  GameManagement copyWith({
    String? gameId,
    String? gameName,
    String? gameType,
    bool? isEnabled,
    String? description,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return GameManagement(
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      gameType: gameType ?? this.gameType,
      isEnabled: isEnabled ?? this.isEnabled,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // Predefined games
  static const List<GameManagement> defaultGames = [
    GameManagement(
      gameId: 'reaction_time',
      gameName: 'Reaction Time',
      gameType: 'reaction_time',
      isEnabled: true,
      description: 'Test your reflexes and reaction speed',
      icon: 'timer',
    ),
    GameManagement(
      gameId: 'number_memory',
      gameName: 'Number Memory',
      gameType: 'number_memory',
      isEnabled: true,
      description: 'Test your memory with increasing number sequences',
      icon: 'memory',
    ),
    GameManagement(
      gameId: 'decision_making',
      gameName: 'Decision Making',
      gameType: 'decision_making',
      isEnabled: true,
      description: 'Test your decision-making skills under pressure',
      icon: 'speed',
    ),
    GameManagement(
      gameId: 'personality_quiz',
      gameName: 'Personality Quiz',
      gameType: 'personality_quiz',
      isEnabled: true,
      description: 'Discover your personality traits',
      icon: 'psychology',
    ),
    GameManagement(
      gameId: 'aim_trainer',
      gameName: 'Aim Trainer',
      gameType: 'aim_trainer',
      isEnabled: true,
      description: 'Improve your aim and precision',
      icon: 'gps_fixed',
    ),
    GameManagement(
      gameId: 'verbal_memory',
      gameName: 'Verbal Memory',
      gameType: 'verbal_memory',
      isEnabled: true,
      description: 'Test your verbal memory skills',
      icon: 'record_voice_over',
    ),
    GameManagement(
      gameId: 'visual_memory',
      gameName: 'Visual Memory',
      gameType: 'visual_memory',
      isEnabled: true,
      description: 'Test your visual memory abilities',
      icon: 'visibility',
    ),
    GameManagement(
      gameId: 'typing_speed',
      gameName: 'Typing Speed',
      gameType: 'typing_speed',
      isEnabled: true,
      description: 'Test your typing speed and accuracy',
      icon: 'keyboard',
    ),
    GameManagement(
      gameId: 'sequence_memory',
      gameName: 'Sequence Memory',
      gameType: 'sequence_memory',
      isEnabled: true,
      description: 'Remember and repeat sequences',
      icon: 'format_list_numbered',
    ),
    GameManagement(
      gameId: 'chimp_test',
      gameName: 'Chimp Test',
      gameType: 'chimp_test',
      isEnabled: true,
      description: 'Test your working memory like a chimp',
      icon: 'pets',
    ),
  ];
}
