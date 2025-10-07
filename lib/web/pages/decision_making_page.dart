import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';
import 'package:human_benchmark/web/widgets/auth_required_wrapper.dart';
import 'package:human_benchmark/web/components/web_ad_banner.dart';

class WebDecisionMakingPage extends StatefulWidget {
  const WebDecisionMakingPage({super.key});

  @override
  State<WebDecisionMakingPage> createState() => _WebDecisionMakingPageState();
}

class _WebDecisionMakingPageState extends State<WebDecisionMakingPage> {
  @override
  Widget build(BuildContext context) {
    return AuthRequiredWrapper(
      title: 'Decision Making Test',
      subtitle:
          'Sign in to access the Decision Making Test when it becomes available.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              title: 'Decision Making Test',
              subtitle:
                  'A quick task to measure speed and accuracy under simple choices.',
            ),
            const Gap(24),
            // AdSense Banner
            WebAdBanner(height: 100, position: 'decision_game'),
            const Gap(24),
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 64,
                    color: Colors.blue[400],
                  ),
                  const Gap(16),
                  Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'This module will be available shortly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
