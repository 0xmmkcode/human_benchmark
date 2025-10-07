import 'package:cloud_firestore/cloud_firestore.dart';

class Rank {
  final String id;
  final String name;
  final String description;
  final int minGlobalScore;
  final int maxGlobalScore;
  final String color; // Hex color code
  final String icon; // Icon name
  final int order; // Display order
  final DateTime createdAt;
  final DateTime updatedAt;

  const Rank({
    required this.id,
    required this.name,
    required this.description,
    required this.minGlobalScore,
    required this.maxGlobalScore,
    required this.color,
    required this.icon,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minGlobalScore': minGlobalScore,
      'maxGlobalScore': maxGlobalScore,
      'color': color,
      'icon': icon,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Rank.fromMap(Map<String, Object?> data) {
    final String id = (data['id'] ?? '') as String;
    final String name = (data['name'] ?? '') as String;
    final String description = (data['description'] ?? '') as String;
    final int minGlobalScore = (data['minGlobalScore'] as num?)?.toInt() ?? 0;
    final int maxGlobalScore = (data['maxGlobalScore'] as num?)?.toInt() ?? 0;
    final String color = (data['color'] ?? '#6B7280') as String;
    final String icon = (data['icon'] ?? 'person') as String;
    final int order = (data['order'] as num?)?.toInt() ?? 0;

    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime updatedAt = DateTime.now();
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    }

    return Rank(
      id: id,
      name: name,
      description: description,
      minGlobalScore: minGlobalScore,
      maxGlobalScore: maxGlobalScore,
      color: color,
      icon: icon,
      order: order,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Check if a global score qualifies for this rank
  bool qualifiesForRank(int globalScore) {
    return globalScore >= minGlobalScore && globalScore <= maxGlobalScore;
  }

  // Calculate progress within this rank (0.0 to 1.0)
  double calculateProgress(int globalScore) {
    if (maxGlobalScore == minGlobalScore) return 1.0;
    final double progress =
        (globalScore - minGlobalScore) / (maxGlobalScore - minGlobalScore);
    return progress.clamp(0.0, 1.0);
  }

  // Create a copy with updates
  Rank copyWith({
    String? id,
    String? name,
    String? description,
    int? minGlobalScore,
    int? maxGlobalScore,
    String? color,
    String? icon,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rank(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      minGlobalScore: minGlobalScore ?? this.minGlobalScore,
      maxGlobalScore: maxGlobalScore ?? this.maxGlobalScore,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Rank(id: $id, name: $name, minGlobalScore: $minGlobalScore, maxGlobalScore: $maxGlobalScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rank && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
