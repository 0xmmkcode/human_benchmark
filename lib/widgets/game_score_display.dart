import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'brain_theme.dart';

class GameScoreDisplay extends StatelessWidget {
  final List<ScoreItem> scores;
  final Color? primaryColor;
  final String? title;

  const GameScoreDisplay({
    super.key,
    required this.scores,
    this.primaryColor,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? BrainTheme.primaryBrain;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BrainTheme.neuralCard,
      child: Column(
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BrainTheme.neuralPulse(color: color, size: 10),
                const SizedBox(width: 6),
                Text(
                  title!,
                  style: BrainTheme.brainLabel.copyWith(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                BrainTheme.neuralPulse(color: color, size: 10),
              ],
            ),
            const Gap(12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: scores
                .map((score) => _buildScoreCard(score, color))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(ScoreItem score, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(score.icon, color: Colors.white, size: 16),
            ),
            const Gap(8),
            Text(
              score.value,
              style: BrainTheme.brainScore.copyWith(color: color, fontSize: 18),
            ),
            const Gap(2),
            Text(
              score.label.toUpperCase(),
              style: BrainTheme.brainLabel.copyWith(
                color: Colors.grey[600],
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreItem {
  final String label;
  final String value;
  final IconData icon;

  const ScoreItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}
