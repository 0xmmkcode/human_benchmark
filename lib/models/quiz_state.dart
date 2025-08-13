class QuizState {
  final int currentQuestionIndex;
  final Map<int, int> answers;
  final bool isCompleted;
  final bool isLoading;
  final String? error;

  const QuizState({
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.isCompleted = false,
    this.isLoading = false,
    this.error,
  });

  QuizState copyWith({
    int? currentQuestionIndex,
    Map<int, int>? answers,
    bool? isCompleted,
    bool? isLoading,
    String? error,
  }) {
    return QuizState(
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'QuizState(currentQuestionIndex: $currentQuestionIndex, answers: $answers, isCompleted: $isCompleted, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizState &&
        other.currentQuestionIndex == currentQuestionIndex &&
        other.answers == answers &&
        other.isCompleted == isCompleted &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return currentQuestionIndex.hashCode ^
        answers.hashCode ^
        isCompleted.hashCode ^
        isLoading.hashCode ^
        error.hashCode;
  }
}
