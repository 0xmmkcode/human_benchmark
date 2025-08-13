class PersonalityResult {
  final String id;
  final String userId;
  final Map<String, double> traitScores;
  final Map<String, double> normalizedScores;
  final DateTime createdAt;
  final int totalQuestions;
  final Map<String, int> questionsPerTrait;

  const PersonalityResult({
    required this.id,
    required this.userId,
    required this.traitScores,
    required this.normalizedScores,
    required this.createdAt,
    required this.totalQuestions,
    required this.questionsPerTrait,
  });

  factory PersonalityResult.fromJson(Map<String, dynamic> json) {
    return PersonalityResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      traitScores: Map<String, double>.from(json['traitScores'] as Map),
      normalizedScores: Map<String, double>.from(
        json['normalizedScores'] as Map,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      totalQuestions: json['totalQuestions'] as int,
      questionsPerTrait: Map<String, int>.from(
        json['questionsPerTrait'] as Map,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'traitScores': traitScores,
      'normalizedScores': normalizedScores,
      'createdAt': createdAt.toIso8601String(),
      'totalQuestions': totalQuestions,
      'questionsPerTrait': questionsPerTrait,
    };
  }

  @override
  String toString() {
    return 'PersonalityResult(id: $id, userId: $userId, traitScores: $traitScores, normalizedScores: $normalizedScores, createdAt: $createdAt, totalQuestions: $totalQuestions, questionsPerTrait: $questionsPerTrait)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonalityResult &&
        other.id == id &&
        other.userId == userId &&
        other.traitScores == traitScores &&
        other.normalizedScores == normalizedScores &&
        other.createdAt == createdAt &&
        other.totalQuestions == totalQuestions &&
        other.questionsPerTrait == questionsPerTrait;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        traitScores.hashCode ^
        normalizedScores.hashCode ^
        createdAt.hashCode ^
        totalQuestions.hashCode ^
        questionsPerTrait.hashCode;
  }
}
