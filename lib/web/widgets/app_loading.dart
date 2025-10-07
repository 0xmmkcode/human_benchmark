import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  final Animation<Color?>?
  valueColor; // Optional: for spinner mode compatibility
  final double? strokeWidth; // Optional: for spinner mode compatibility

  const AppLoading({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.valueColor,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final double resolvedWidth = width ?? 37;
    final double resolvedHeight = height ?? 37;

    // If spinner-related params are provided, render a CircularProgressIndicator
    if (valueColor != null || strokeWidth != null) {
      return SizedBox(
        width: resolvedWidth,
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth ?? 4.0,
            valueColor: valueColor,
          ),
        ),
      );
    }

    // Default: show branded loading GIF
    return Image.asset(
      'assets/images/loading_main.gif',
      width: resolvedWidth,
      height: resolvedHeight,
      fit: fit,
    );
  }
}
