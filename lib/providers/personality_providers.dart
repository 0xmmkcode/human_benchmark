import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/personality_question.dart';
import '../models/personality_scale.dart';
import '../models/personality_result.dart';
import '../models/personality_aggregates.dart';
import '../models/quiz_state.dart';
import '../repositories/personality_repository.dart';

// Repository provider
final personalityRepositoryProvider = Provider<PersonalityRepository>((ref) {
  return PersonalityRepository();
});

// Questions provider
final questionsProvider = FutureProvider<List<PersonalityQuestion>>((
  ref,
) async {
  final repository = ref.read(personalityRepositoryProvider);
  final all = await repository.getQuestions();
  if (all.length <= 20) return all;
  final shuffled = all.toList()..shuffle();
  return shuffled.take(20).toList();
});

// Scale provider
final scaleProvider = FutureProvider<PersonalityScale>((ref) async {
  final repository = ref.read(personalityRepositoryProvider);
  return await repository.getScale();
});

// Quiz state notifier
class QuizStateNotifier extends StateNotifier<QuizState> {
  QuizStateNotifier() : super(const QuizState());

  void setCurrentQuestion(int index) {
    state = state.copyWith(currentQuestionIndex: index);
  }

  void setAnswer(int questionId, int answer) {
    final newAnswers = Map<int, int>.from(state.answers);
    newAnswers[questionId] = answer;
    state = state.copyWith(answers: newAnswers);
  }

  void setCompleted(bool completed) {
    state = state.copyWith(isCompleted: completed);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const QuizState();
  }

  // Remove hardcoded methods that conflict with dynamic navigation
  // These will be calculated in the UI based on actual loaded questions
}

final quizStateProvider = StateNotifierProvider<QuizStateNotifier, QuizState>((
  ref,
) {
  return QuizStateNotifier();
});

// User results provider
final userResultsProvider = FutureProvider<List<PersonalityResult>>((
  ref,
) async {
  final repository = ref.read(personalityRepositoryProvider);
  return await repository.getUserResults();
});

// Latest result provider
final latestResultProvider = FutureProvider<PersonalityResult?>((ref) async {
  final repository = ref.read(personalityRepositoryProvider);
  return await repository.getLatestResult();
});

// Aggregates provider
final aggregatesProvider = FutureProvider<PersonalityAggregates>((ref) async {
  final repository = ref.read(personalityRepositoryProvider);
  return await repository.getAggregates();
});

// Quiz completion provider
final quizCompletionProvider = Provider<bool>((ref) {
  final quizState = ref.watch(quizStateProvider);
  return quizState.isCompleted;
});
