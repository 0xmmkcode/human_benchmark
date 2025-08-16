import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/models/user_score.dart';
import 'package:human_benchmark/models/game_score.dart';
import 'package:human_benchmark/services/score_service.dart';
import 'package:human_benchmark/widgets/score_display.dart';
import 'package:human_benchmark/screens/comprehensive_leaderboard_page.dart';

class WebDecisionMakingPage extends StatefulWidget {
  const WebDecisionMakingPage({super.key});

  @override
  State<WebDecisionMakingPage> createState() => _WebDecisionMakingPageState();
}

class _WebDecisionMakingPageState extends State<WebDecisionMakingPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Decision Making Test',
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(8),
          Text(
            'A quick task to measure speed and accuracy under simple choices.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
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
    );
  }
}
