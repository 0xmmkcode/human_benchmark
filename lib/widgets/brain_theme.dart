import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrainTheme {
  // Brain-themed color palette
  static const Color primaryBrain = Color(0xFF6B46C1); // Deep purple
  static const Color secondaryBrain = Color(0xFF8B5CF6); // Light purple
  static const Color accentBrain = Color(0xFF06B6D4); // Cyan
  static const Color successBrain = Color(0xFF10B981); // Emerald
  static const Color warningBrain = Color(0xFFF59E0B); // Amber
  static const Color errorBrain = Color(0xFFEF4444); // Red

  // Gradient backgrounds
  static const LinearGradient brainGradient = LinearGradient(
    colors: [primaryBrain, secondaryBrain],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neuralGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Brain-themed text styles
  static TextStyle get brainTitle => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryBrain,
    letterSpacing: -0.5,
  );

  static TextStyle get brainSubtitle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.grey[700],
    height: 1.4,
  );

  static TextStyle get brainScore => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryBrain,
  );

  static TextStyle get brainLabel => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.grey[600],
    letterSpacing: 0.5,
  );

  // Brain-themed decorations
  static BoxDecoration get brainCard => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 6,
        offset: const Offset(0, 1),
      ),
    ],
  );

  static BoxDecoration get neuralCard => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );

  // Brain-themed icons and decorations
  static Widget brainIcon({double size = 24, Color? color}) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [primaryBrain, secondaryBrain],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.psychology, color: color ?? Colors.white, size: size),
  );

  static Widget neuralPulse({double size = 20, Color? color}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color ?? accentBrain,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: (color ?? accentBrain).withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    ),
  );

  // Gamification elements
  static Widget levelBadge({required int level, double size = 40}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: brainGradient,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: primaryBrain.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Center(
      child: Text(
        '$level',
        style: GoogleFonts.inter(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );

  static Widget scoreBadge({
    required String score,
    required IconData icon,
    Color? color,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color ?? primaryBrain,
          (color ?? primaryBrain).withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: (color ?? primaryBrain).withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          score,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  // Brain-themed progress indicators
  static Widget neuralProgress({
    required double progress,
    required String label,
    Color? color,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: brainLabel),
      const SizedBox(height: 8),
      Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color ?? primaryBrain, color ?? secondaryBrain],
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
