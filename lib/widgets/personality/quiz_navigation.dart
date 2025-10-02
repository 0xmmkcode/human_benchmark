import 'package:flutter/material.dart';

class QuizNavigation extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onComplete;
  final int currentQuestion;
  final int totalQuestions;

  const QuizNavigation({
    super.key,
    this.onPrevious,
    this.onNext,
    this.onComplete,
    required this.currentQuestion,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Previous button
          if (onPrevious != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onPrevious,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.blue.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Previous',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (onPrevious != null) const SizedBox(width: 16),

          // Next/Complete button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext ?? onComplete,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.blue.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    onComplete != null ? 'Complete Quiz' : 'Next',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onNext != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
