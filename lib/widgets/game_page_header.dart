import 'package:flutter/material.dart';
import 'brain_theme.dart';

class GamePageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBackPressed;
  final Widget? additionalContent;
  final Color? primaryColor;

  const GamePageHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.onBackPressed,
    this.additionalContent,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? BrainTheme.primaryBrain;

    return Column(
      children: [
        // Main header with back button and title
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BrainTheme.brainCard,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed:
                          onBackPressed ?? () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: BrainTheme.brainTitle.copyWith(
                        color: color,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),

              // Subtitle and additional content
              if (subtitle.isNotEmpty || additionalContent != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.05), color.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          BrainTheme.neuralPulse(color: color, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            'Cognitive Science',
                            style: BrainTheme.brainLabel.copyWith(
                              color: color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: BrainTheme.brainSubtitle.copyWith(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                      if (additionalContent != null) ...[
                        const SizedBox(height: 8),
                        additionalContent!,
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
