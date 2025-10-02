import 'package:flutter/material.dart';
import '../../models/personality_question.dart';
import '../../models/personality_scale.dart';
import '../brain_theme.dart';

class QuestionCard extends StatelessWidget {
  final PersonalityQuestion question;
  final PersonalityScale scale;
  final int? selectedAnswer;
  final ValueChanged<int> onAnswerSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.scale,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BrainTheme.brainCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trait indicator
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrainTheme.primaryBrain.withOpacity(0.1),
                    BrainTheme.primaryBrain.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: BrainTheme.primaryBrain.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                question.trait,
                style: BrainTheme.brainLabel.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BrainTheme.primaryBrain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Question text
          Text(
            question.text,
            style: BrainTheme.brainTitle.copyWith(
              fontSize: 20,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          Column(
            mainAxisSize: MainAxisSize.min,
            children: scale.scale.map((option) {
              final isSelected = selectedAnswer == option.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: InkWell(
                  onTap: () => onAnswerSelected(option.value),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [
                                BrainTheme.primaryBrain.withOpacity(0.1),
                                BrainTheme.primaryBrain.withOpacity(0.05),
                              ]
                            : [
                                Colors.grey.withOpacity(0.05),
                                Colors.grey.withOpacity(0.02),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? BrainTheme.primaryBrain.withOpacity(0.08)
                              : Colors.grey.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? BrainTheme.primaryBrain
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? BrainTheme.primaryBrain
                                  : Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option.label,
                            style: BrainTheme.brainSubtitle.copyWith(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? BrainTheme.primaryBrain
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
