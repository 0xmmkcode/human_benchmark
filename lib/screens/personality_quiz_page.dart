import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/personality_question.dart';
import '../models/personality_scale.dart';
import '../models/personality_result.dart';
import '../providers/personality_providers.dart';
import '../widgets/personality/question_card.dart';
import '../widgets/personality/quiz_progress_bar.dart';
import '../widgets/personality/quiz_navigation.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/personality/personality_radar_chart.dart';
import '../widgets/personality/trait_score_card.dart';
import '../widgets/personality_leaderboard.dart';

class PersonalityQuizPage extends ConsumerStatefulWidget {
  const PersonalityQuizPage({super.key});

  @override
  ConsumerState<PersonalityQuizPage> createState() =>
      _PersonalityQuizPageState();
}

class _PersonalityQuizPageState extends ConsumerState<PersonalityQuizPage> {
  PersonalityResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final bool isAuthenticated = snapshot.data != null;
        if (!isAuthenticated) {
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in required',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please sign in to take the personality assessment and save your results.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Sign in with Google'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final cred = await AuthService.signInWithGoogle();
                            if (mounted && cred != null) {
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final questionsAsync = ref.watch(questionsProvider);
        final scaleAsync = ref.watch(scaleProvider);
        final quizState = ref.watch(quizStateProvider);

        // Derive totals and navigation flags safely based on loaded questions
        final int totalQuestions = questionsAsync.asData?.value.length ?? 20;
        final int currentIndex = quizState.currentQuestionIndex;
        final int maxIndex = (totalQuestions > 0) ? totalQuestions - 1 : 0;
        final bool canGoPrevious = currentIndex > 0;
        final bool canGoNext = currentIndex < maxIndex;
        final bool isLastQuestion = currentIndex == maxIndex;
        final double progress = totalQuestions > 0
            ? (quizState.answers.length.clamp(0, totalQuestions) /
                  totalQuestions)
            : 0.0;

        // Show results inline after completion
        if (quizState.isCompleted && _lastResult != null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildResultsContent(_lastResult!),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
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
                                'Big Five Personality Assessment',
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
                          'Discover your personality traits through this scientifically validated assessment',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            color: Colors.blue.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Intentionally hide logged-in user details on this page
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress bar
                  QuizProgressBar(
                    currentQuestion: currentIndex + 1,
                    totalQuestions: totalQuestions,
                    progress: progress,
                  ),
                  const SizedBox(height: 24),

                  // Main content
                  Expanded(
                    child: questionsAsync.when(
                      data: (questions) => scaleAsync.when(
                        data: (scale) => _buildQuizContent(questions, scale),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            _buildErrorWidget('Failed to load scale: $error'),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          _buildErrorWidget('Failed to load questions: $error'),
                    ),
                  ),

                  // Navigation
                  if (questionsAsync.hasValue && scaleAsync.hasValue)
                    QuizNavigation(
                      onPrevious: canGoPrevious ? _goToPrevious : null,
                      onNext: canGoNext ? _goToNext : null,
                      onComplete: isLastQuestion ? _completeQuiz : null,
                      currentQuestion: currentIndex + 1,
                      totalQuestions: totalQuestions,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizContent(
    List<PersonalityQuestion> questions,
    PersonalityScale scale,
  ) {
    final quizNotifier = ref.read(quizStateProvider.notifier);
    final quizState = ref.read(quizStateProvider);
    if (questions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }

    final int maxIndex = questions.length - 1;
    final int currentIndex = quizState.currentQuestionIndex;
    final int safeIndex = currentIndex < 0
        ? 0
        : (currentIndex > maxIndex ? maxIndex : currentIndex);
    final currentQuestion = questions[safeIndex];

    return Column(
      children: [
        Expanded(
          child: QuestionCard(
            question: currentQuestion,
            scale: scale,
            selectedAnswer: quizState.answers[currentQuestion.id],
            onAnswerSelected: (answer) {
              quizNotifier.setAnswer(currentQuestion.id, answer);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // ignore: unused_result
              ref.refresh(questionsProvider);
              // ignore: unused_result
              ref.refresh(scaleProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _goToPrevious() {
    final quizNotifier = ref.read(quizStateProvider.notifier);
    final quizState = ref.read(quizStateProvider);
    final int currentIndex = quizState.currentQuestionIndex;
    final int newIndex = currentIndex > 0 ? currentIndex - 1 : 0;
    quizNotifier.setCurrentQuestion(newIndex);
  }

  void _goToNext() {
    final quizNotifier = ref.read(quizStateProvider.notifier);
    final quizState = ref.read(quizStateProvider);
    final questions = ref.read(questionsProvider).asData?.value;
    if (questions == null || questions.isEmpty) return;
    final int maxIndex = questions.length - 1;
    final int currentIndex = quizState.currentQuestionIndex;
    final int newIndex = currentIndex < maxIndex ? currentIndex + 1 : maxIndex;
    quizNotifier.setCurrentQuestion(newIndex);
  }

  void _completeQuiz() async {
    final questionsAsync = ref.read(questionsProvider);
    final scaleAsync = ref.read(scaleProvider);

    if (!questionsAsync.hasValue || !scaleAsync.hasValue) return;

    final questions = questionsAsync.value!;
    final scale = scaleAsync.value!;
    final currentQuizState = ref.read(quizStateProvider);
    final answers = currentQuizState.answers;

    // Ensure all questions are answered
    final int totalQuestions = questions.length;
    final bool allAnswered = questions.every((q) => answers.containsKey(q.id));
    if (!allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please answer all questions before completing the quiz.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calculate scores
    final traitScores = <String, double>{};
    final questionsPerTrait = <String, int>{};

    for (final trait in scale.traits) {
      final traitQuestions = questions.where((q) => q.trait == trait).toList();
      final traitAnswers = traitQuestions
          .map((q) => answers[q.id] ?? 0)
          .toList();

      if (traitAnswers.isNotEmpty) {
        traitScores[trait] =
            traitAnswers.reduce((a, b) => a + b) / traitAnswers.length;
        questionsPerTrait[trait] = traitQuestions.length;
      }
    }

    // Normalize scores (convert to percentage)
    final normalizedScores = <String, double>{};
    traitScores.forEach((trait, score) {
      // Convert 1-5 scale to 0-100 percentage
      normalizedScores[trait] = ((score - 1) / 4) * 100;
    });

    // Create result
    final result = PersonalityResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: AuthService.currentUser?.uid ?? 'anonymous',
      traitScores: traitScores,
      normalizedScores: normalizedScores,
      createdAt: DateTime.now(),
      totalQuestions: totalQuestions,
      questionsPerTrait: questionsPerTrait,
    );

    // Save result remotely if authenticated (repository skips when not)
    try {
      final repository = ref.read(personalityRepositoryProvider);
      await repository.saveResult(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save result: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Mark completed and show results inside this page
    if (mounted) {
      ref.read(quizStateProvider.notifier).setCompleted(true);
      setState(() {
        _lastResult = result;
      });
    }
  }

  Widget _buildResultsContent(PersonalityResult result) {
    final String personalityType = _inferPersonalityType(
      result.normalizedScores,
    );
    final double overallScore = result.normalizedScores.values.isEmpty
        ? 0
        : result.normalizedScores.values.reduce((a, b) => a + b) /
              result.normalizedScores.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.purple.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.psychology, size: 64, color: Colors.blue.shade600),
              const SizedBox(height: 12),
              Text(
                'Your Personality Profile',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Overall score: ${overallScore.toStringAsFixed(1)} • Type: $personalityType',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  color: Colors.blue.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Completed on ${_formatDate(result.createdAt)}',
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
        const SizedBox(height: 24),

        // Radar chart
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Trait Overview',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: PersonalityRadarChart(scores: result.normalizedScores),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: Text(
            'Detailed Scores',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: result.normalizedScores.length,
          itemBuilder: (context, index) {
            final trait = result.normalizedScores.keys.elementAt(index);
            final score = result.normalizedScores[trait]!;
            return TraitScoreCard(
              trait: trait,
              score: score,
              rawScore: result.traitScores[trait]!,
            );
          },
        ),
        const SizedBox(height: 24),

        // Personality Leaderboard
        Center(
          child: Text(
            'Compare with Others',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: const PersonalityLeaderboard(showTitle: false, maxItems: 5),
        ),
        const SizedBox(height: 24),

        Center(
          child: SizedBox(
            width: 200,
            child: OutlinedButton(
              onPressed: () {
                // Reset quiz to start over
                ref.read(quizStateProvider.notifier).reset();
                setState(() {
                  _lastResult = null;
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.blue.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Take Quiz Again',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _inferPersonalityType(Map<String, double> normalizedScores) {
    if (normalizedScores.isEmpty) return 'Unknown';
    final sorted = normalizedScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    switch (top.key.toLowerCase()) {
      case 'openness':
        return 'Explorer';
      case 'conscientiousness':
        return 'Organizer';
      case 'extraversion':
        return 'Energizer';
      case 'agreeableness':
        return 'Harmonizer';
      case 'neuroticism':
        return 'Sensitive';
      default:
        return '${top.key} dominant';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
