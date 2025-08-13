class PersonalityScale {
  final List<ScaleOption> scale;
  final List<String> traits;
  final int questionsPerTrait;

  const PersonalityScale({
    required this.scale,
    required this.traits,
    required this.questionsPerTrait,
  });

  factory PersonalityScale.fromJson(Map<String, dynamic> json) {
    return PersonalityScale(
      scale: (json['scale'] as List<dynamic>)
          .map((e) => ScaleOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      traits: List<String>.from(json['traits'] as List),
      questionsPerTrait: json['questionsPerTrait'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scale': scale.map((e) => e.toJson()).toList(),
      'traits': traits,
      'questionsPerTrait': questionsPerTrait,
    };
  }

  @override
  String toString() {
    return 'PersonalityScale(scale: $scale, traits: $traits, questionsPerTrait: $questionsPerTrait)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonalityScale &&
        other.scale == scale &&
        other.traits == traits &&
        other.questionsPerTrait == questionsPerTrait;
  }

  @override
  int get hashCode {
    return scale.hashCode ^ traits.hashCode ^ questionsPerTrait.hashCode;
  }
}

class ScaleOption {
  final int value;
  final String label;

  const ScaleOption({
    required this.value,
    required this.label,
  });

  factory ScaleOption.fromJson(Map<String, dynamic> json) {
    return ScaleOption(
      value: json['value'] as int,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }

  @override
  String toString() {
    return 'ScaleOption(value: $value, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScaleOption &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode {
    return value.hashCode ^ label.hashCode;
  }
}
