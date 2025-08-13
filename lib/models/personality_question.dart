class PersonalityQuestion {
  final int id;
  final String text;
  final String trait;
  final bool active;

  const PersonalityQuestion({
    required this.id,
    required this.text,
    required this.trait,
    this.active = true,
  });

  factory PersonalityQuestion.fromJson(Map<String, dynamic> json) {
    return PersonalityQuestion(
      id: json['id'] as int,
      text: json['text'] as String,
      trait: json['trait'] as String,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'trait': trait,
      'active': active,
    };
  }

  @override
  String toString() {
    return 'PersonalityQuestion(id: $id, text: $text, trait: $trait, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonalityQuestion &&
        other.id == id &&
        other.text == text &&
        other.trait == trait &&
        other.active == active;
  }

  @override
  int get hashCode {
    return id.hashCode ^ text.hashCode ^ trait.hashCode ^ active.hashCode;
  }
}
