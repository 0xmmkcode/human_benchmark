class PersonalityResult {
  final String id;
  final String userId;
  final String? userName;
  final Map<String, double> traitScores;
  final Map<String, double> normalizedScores;
  final DateTime createdAt;
  final int totalQuestions;
  final Map<String, int> questionsPerTrait;

  const PersonalityResult({
    required this.id,
    required this.userId,
    this.userName,
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
      userName: json['userName'] as String?,
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
      'userName': userName,
      'traitScores': traitScores,
      'normalizedScores': normalizedScores,
      'createdAt': createdAt.toIso8601String(),
      'totalQuestions': totalQuestions,
      'questionsPerTrait': questionsPerTrait,
    };
  }

  @override
  String toString() {
    return 'PersonalityResult(id: $id, userId: $userId, userName: $userName, traitScores: $traitScores, normalizedScores: $normalizedScores, createdAt: $createdAt, totalQuestions: $totalQuestions, questionsPerTrait: $questionsPerTrait)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonalityResult &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.traitScores == traitScores &&
        other.normalizedScores == normalizedScores &&
        other.createdAt == createdAt &&
        other.totalQuestions == totalQuestions &&
        other.questionsPerTrait == questionsPerTrait;
  }

  // Get trait score
  double getTraitScore(String trait) {
    return normalizedScores[trait] ?? 0.0;
  }

  // Get trait percentile (simplified calculation)
  double getTraitPercentile(String trait) {
    final score = getTraitScore(trait);
    // This is a simplified percentile calculation
    // In a real app, you'd calculate this based on the actual distribution
    if (score >= 0.8) return 95.0;
    if (score >= 0.6) return 75.0;
    if (score >= 0.4) return 50.0;
    if (score >= 0.2) return 25.0;
    return 5.0;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        (userName?.hashCode ?? 0) ^
        traitScores.hashCode ^
        normalizedScores.hashCode ^
        createdAt.hashCode ^
        totalQuestions.hashCode ^
        questionsPerTrait.hashCode;
  }
}
