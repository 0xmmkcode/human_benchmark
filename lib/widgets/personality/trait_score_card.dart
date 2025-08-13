import 'package:flutter/material.dart';

class TraitScoreCard extends StatelessWidget {
  final String trait;
  final double score;
  final double rawScore;

  const TraitScoreCard({
    super.key,
    required this.trait,
    required this.score,
    required this.rawScore,
  });

  @override
  Widget build(BuildContext context) {
    final MaterialColor traitColor = _getTraitColor(trait);
    final String interpretation = _getInterpretation(score);

    return Card(
      elevation: 4,
      shadowColor: traitColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trait name
            Text(
              trait,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: traitColor.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // Score circle
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [traitColor.shade100, traitColor.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: traitColor.shade300, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${score.toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: traitColor.shade700,
                        ),
                      ),
                      Text(
                        '${rawScore.toStringAsFixed(1)}/5',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: traitColor.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Interpretation
            Text(
              interpretation,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  MaterialColor _getTraitColor(String trait) {
    switch (trait) {
      case 'Openness':
        return Colors.purple;
      case 'Conscientiousness':
        return Colors.green;
      case 'Extraversion':
        return Colors.orange;
      case 'Agreeableness':
        return Colors.pink;
      case 'Neuroticism':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getInterpretation(double score) {
    if (score >= 80) {
      return 'Very High';
    } else if (score >= 60) {
      return 'High';
    } else if (score >= 40) {
      return 'Moderate';
    } else if (score >= 20) {
      return 'Low';
    } else {
      return 'Very Low';
    }
  }
}
