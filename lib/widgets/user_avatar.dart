import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final String? displayName;
  final String? email;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? borderWidth;

  const UserAvatar({
    super.key,
    this.photoURL,
    this.displayName,
    this.email,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoURL != null && photoURL!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null && borderWidth != null
            ? Border.all(color: borderColor!, width: borderWidth!)
            : null,
      ),
      child: hasPhoto ? _buildImageAvatar() : _buildInitialsAvatar(),
    );
  }

  // Get the first letter for display
  String getInitials() {
    final hasName = displayName != null && displayName!.isNotEmpty;
    final hasEmail = email != null && email!.isNotEmpty;

    if (hasName) {
      final names = displayName!.trim().split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return displayName![0].toUpperCase();
      }
    } else if (hasEmail) {
      return email![0].toUpperCase();
    }
    return '?';
  }

  // Generate a consistent background color based on the name/email
  Color getBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;

    final hasName = displayName != null && displayName!.isNotEmpty;
    final hasEmail = email != null && email!.isNotEmpty;

    final seed = hasName
        ? displayName!.hashCode
        : (hasEmail ? email!.hashCode : 0);
    final hue = (seed % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.8).toColor();
  }

  // Get text color (white or black based on background brightness)
  Color getTextColor() {
    if (textColor != null) return textColor!;

    final bgColor = getBackgroundColor();
    final luminance = bgColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  Widget _buildImageAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: getBackgroundColor(),
      child: ClipOval(
        child: Image.network(
          photoURL!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to initials if image fails to load
            return _buildInitialsAvatar();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildInitialsAvatar();
          },
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: getBackgroundColor(),
      child: Text(
        getInitials(),
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
          color: getTextColor(),
        ),
      ),
    );
  }
}
