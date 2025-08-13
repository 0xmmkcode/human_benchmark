import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/personality_question.dart';
import '../models/personality_scale.dart';
import '../models/personality_result.dart';
import '../providers/personality_providers.dart';
import '../widgets/personality/question_card.dart';
import '../widgets/personality/quiz_progress_bar.dart';
import '../widgets/personality/quiz_navigation.dart';
import 'personality_results_page.dart';

class PersonalityQuizPage extends ConsumerStatefulWidget {
  const PersonalityQuizPage({super.key});

  @override
  ConsumerState<PersonalityQuizPage> createState() =>
      _PersonalityQuizPageState();
}

class _PersonalityQuizPageState extends ConsumerState<PersonalityQuizPage> {
  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsProvider);
    final scaleAsync = ref.watch(scaleProvider);
    final quizState = ref.watch(quizStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
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
                  Text(
                    'Big Five Personality Assessment',
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
                    'Discover your personality traits through this scientifically validated assessment',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      color: Colors.blue.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Progress bar
            QuizProgressBar(
              currentQuestion: quizState.currentQuestionIndex + 1,
              totalQuestions: 50,
              progress: quizState.progress,
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    _buildErrorWidget('Failed to load questions: $error'),
              ),
            ),

            // Navigation
            if (questionsAsync.hasValue && scaleAsync.hasValue)
              QuizNavigation(
                onPrevious: quizState.canGoPrevious ? _goToPrevious : null,
                onNext: quizState.canGoNext ? _goToNext : null,
                onComplete: quizState.isLastQuestion ? _completeQuiz : null,
                currentQuestion: quizState.currentQuestionIndex + 1,
                totalQuestions: 50,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent(
    List<PersonalityQuestion> questions,
    PersonalityScale scale,
  ) {
    final quizState = ref.read(quizStateProvider.notifier);
    final currentQuestion = questions[quizState.state.currentQuestionIndex];

    return Column(
      children: [
        Expanded(
          child: QuestionCard(
            question: currentQuestion,
            scale: scale,
            selectedAnswer: quizState.state.answers[currentQuestion.id],
            onAnswerSelected: (answer) {
              quizState.setAnswer(currentQuestion.id, answer);
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
              ref.refresh(questionsProvider);
              ref.refresh(scaleProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _goToPrevious() {
    final quizState = ref.read(quizStateProvider.notifier);
    if (quizState.canGoPrevious) {
      quizState.setCurrentQuestion(quizState.state.currentQuestionIndex - 1);
    }
  }

  void _goToNext() {
    final quizState = ref.read(quizStateProvider.notifier);
    if (quizState.canGoNext) {
      quizState.setCurrentQuestion(quizState.state.currentQuestionIndex + 1);
    }
  }

  void _completeQuiz() async {
    final quizState = ref.read(quizStateProvider.notifier);
    final questionsAsync = ref.read(questionsProvider);
    final scaleAsync = ref.read(scaleProvider);

    if (!questionsAsync.hasValue || !scaleAsync.hasValue) return;

    final questions = questionsAsync.value!;
    final scale = scaleAsync.value!;
    final answers = quizState.state.answers;

    if (answers.length < 50) {
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
      userId: 'current_user', // This should come from auth
      traitScores: traitScores,
      normalizedScores: normalizedScores,
      createdAt: DateTime.now(),
      totalQuestions: 50,
      questionsPerTrait: questionsPerTrait,
    );

    // Save result
    try {
      final repository = ref.read(ref.read(personalityRepositoryProvider));
      await repository.saveResult(result);

      // Navigate to results
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PersonalityResultsPage(result: result),
          ),
        );
      }
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
  }
}
