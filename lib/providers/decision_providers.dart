import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/decision_trial.dart';
import '../repositories/decision_repository.dart';
import '../repositories/decision_session_repository.dart';

final decisionRepositoryProvider = Provider<DecisionRepository>((ref) {
  return DecisionRepository();
});

final decisionSessionRepositoryProvider = Provider<DecisionSessionRepository>((
  ref,
) {
  return DecisionSessionRepository();
});

final decisionTrialsProvider = FutureProvider<List<DecisionTrial>>((ref) async {
  final repo = ref.read(decisionRepositoryProvider);
  final all = await repo.getTrials();
  // Shuffle and take 10
  final rng = Random();
  final shuffled = List<DecisionTrial>.from(all)..shuffle(rng);
  return shuffled.take(10).toList();
});

class DecisionSessionState {
  final int currentIndex;
  final List<DecisionResponse> responses;
  final bool completed;

  const DecisionSessionState({
    this.currentIndex = 0,
    this.responses = const [],
    this.completed = false,
  });

  DecisionSessionState copyWith({
    int? currentIndex,
    List<DecisionResponse>? responses,
    bool? completed,
  }) {
    return DecisionSessionState(
      currentIndex: currentIndex ?? this.currentIndex,
      responses: responses ?? this.responses,
      completed: completed ?? this.completed,
    );
  }
}

class DecisionSessionNotifier extends StateNotifier<DecisionSessionState> {
  DecisionSessionNotifier() : super(const DecisionSessionState());

  void recordResponse(DecisionResponse response, int totalTrials) {
    final updated = List<DecisionResponse>.from(state.responses)..add(response);
    final nextIndex = state.currentIndex + 1;
    state = state.copyWith(
      responses: updated,
      currentIndex: nextIndex,
      completed: nextIndex >= totalTrials,
    );
  }

  void reset() {
    state = const DecisionSessionState();
  }
}

final decisionSessionProvider =
    StateNotifierProvider<DecisionSessionNotifier, DecisionSessionState>((ref) {
      return DecisionSessionNotifier();
    });
