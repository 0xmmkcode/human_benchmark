import 'package:flutter/material.dart';

class WebBannerAd extends StatelessWidget {
  final double height;

  const WebBannerAd({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, width: double.infinity);
  }
}
