import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';

class WebBannerAd extends StatelessWidget {
  final double height;

  const WebBannerAd({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    // Ads removed: render nothing
    return const SizedBox.shrink();
  }
}
