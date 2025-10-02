import 'package:flutter/material.dart';

class QuizProgressBar extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final double progress;

  const QuizProgressBar({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Handle edge cases
    final int safeCurrent = currentQuestion > 0 ? currentQuestion : 1;
    final int safeTotal = totalQuestions > 0 ? totalQuestions : 1;
    final double safeProgress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        // Progress text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question $safeCurrent of $safeTotal',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${(safeProgress * 100).toInt()}% Complete',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: safeProgress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
