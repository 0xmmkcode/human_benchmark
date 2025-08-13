class DecisionOption {
  final String label;
  final String description;
  final bool isRisky;
  final double? probability; // 0..1 for risky options
  final double? payoff; // arbitrary units
  final double? score; // optional per-option score contribution

  const DecisionOption({
    required this.label,
    required this.description,
    this.isRisky = false,
    this.probability,
    this.payoff,
    this.score,
  });

  factory DecisionOption.fromJson(Map<String, dynamic> json) {
    return DecisionOption(
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
      isRisky: json['isRisky'] as bool? ?? false,
      probability: (json['probability'] as num?)?.toDouble(),
      payoff: (json['payoff'] as num?)?.toDouble(),
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'description': description,
      'isRisky': isRisky,
      'probability': probability,
      'payoff': payoff,
      'score': score,
    };
  }
}

class DecisionTrial {
  final String id;
  final String prompt;
  final int timeLimitSeconds;
  final DecisionOption left;
  final DecisionOption right;

  const DecisionTrial({
    required this.id,
    required this.prompt,
    required this.timeLimitSeconds,
    required this.left,
    required this.right,
  });

  factory DecisionTrial.fromJson(String id, Map<String, dynamic> json) {
    return DecisionTrial(
      id: id,
      prompt: json['prompt'] as String,
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 10,
      left: DecisionOption.fromJson(json['left'] as Map<String, dynamic>),
      right: DecisionOption.fromJson(json['right'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'timeLimitSeconds': timeLimitSeconds,
      'left': left.toJson(),
      'right': right.toJson(),
    };
  }
}

class DecisionResponse {
  final String trialId;
  final String chosenLabel; // 'left' or 'right'
  final bool choseRisky;
  final Duration responseTime;
  final bool timedOut;
  final double score;

  const DecisionResponse({
    required this.trialId,
    required this.chosenLabel,
    required this.choseRisky,
    required this.responseTime,
    required this.timedOut,
    this.score = 0,
  });
}
