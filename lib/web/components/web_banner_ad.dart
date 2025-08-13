import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';

class WebBannerAd extends StatelessWidget {
  final double height;

  const WebBannerAd({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !kReleaseMode) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      alignment: Alignment.center,
      child: Text('Ad space', style: TextStyle(color: Colors.grey[600])),
    );
  }
}
