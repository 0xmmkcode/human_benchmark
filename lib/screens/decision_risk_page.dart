import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/decision_providers.dart';
import '../widgets/decision/decision_trial_card.dart';
import '../models/decision_trial.dart';

class DecisionRiskPage extends ConsumerWidget {
  const DecisionRiskPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trialsAsync = ref.watch(decisionTrialsProvider);
    final session = ref.watch(decisionSessionProvider);
    final controller = ref.read(decisionSessionProvider.notifier);

    if (session.completed) {
      final total = session.responses.length;
      final risky = session.responses.where((r) => r.choseRisky).length;
      final timeMs = session.responses
          .map((r) => r.responseTime.inMilliseconds)
          .fold<int>(0, (a, b) => a + b);
      final avgMs = total == 0 ? 0 : (timeMs / total).round();
      final riskPct = total == 0 ? 0 : ((risky / total) * 100).round();
      final totalScore = session.responses.fold<double>(
        0,
        (a, r) => a + r.score,
      );

      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assessment, color: Colors.blue.shade600, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Risk & Decision Speed Summary',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Risk preference: $riskPct% risky choices\nAverage decision time: ${avgMs}ms\nScore: ${totalScore.toStringAsFixed(1)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final repo = ref.read(decisionSessionRepositoryProvider);
                      await repo.saveSession(
                        responses: session.responses,
                        totalTrials: total,
                      );
                      controller.reset();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return trialsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Failed to load trials: $e')),
      ),
      data: (trials) {
        final safeIndex = trials.isEmpty
            ? 0
            : session.currentIndex.clamp(0, trials.length - 1);
        final trial = trials.isEmpty ? null : trials[safeIndex];
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        // Back button and game name header
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.arrow_back, size: 24),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                padding: EdgeInsets.all(12),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Decision-Making Speed & Risk',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          trial == null
                              ? 'No trials available.'
                              : 'Answer quickly. You have ${trial.timeLimitSeconds}s for each dilemma.',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            color: Colors.blue.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (trial != null)
                    DecisionTrialCard(
                      trial: trial,
                      onAnswered: (resp) {
                        final option = resp.chosenLabel == 'left'
                            ? trial.left
                            : trial.right;
                        final computedScore = _computeScore(option, resp);
                        controller.recordResponse(
                          DecisionResponse(
                            trialId: resp.trialId,
                            chosenLabel: resp.chosenLabel,
                            choseRisky: resp.choseRisky,
                            responseTime: resp.responseTime,
                            timedOut: resp.timedOut,
                            score: computedScore,
                          ),
                          trials.length,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _computeScore(option, resp) {
    final double base =
        (option.score as double?) ??
        ((option.isRisky
                ? (option.payoff ?? 0) * (option.probability ?? 0)
                : (option.payoff ?? 1)) /
            10.0);
    final double speedBonus =
        (10000 - resp.responseTime.inMilliseconds).clamp(0, 10000) / 10000;
    return base + speedBonus;
  }
}
