class PersonalityAggregates {
  final Map<String, int> counts;
  final Map<String, double> avg;
  final int responses;

  const PersonalityAggregates({
    required this.counts,
    required this.avg,
    required this.responses,
  });

  factory PersonalityAggregates.fromJson(Map<String, dynamic> json) {
    return PersonalityAggregates(
      counts: Map<String, int>.from(json['counts'] as Map),
      avg: Map<String, double>.from(json['avg'] as Map),
      responses: json['responses'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'counts': counts, 'avg': avg, 'responses': responses};
  }

  @override
  String toString() {
    return 'PersonalityAggregates(counts: $counts, avg: $avg, responses: $responses)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonalityAggregates &&
        other.counts == counts &&
        other.avg == avg &&
        other.responses == responses;
  }

  @override
  int get hashCode {
    return counts.hashCode ^ avg.hashCode ^ responses.hashCode;
  }
}
