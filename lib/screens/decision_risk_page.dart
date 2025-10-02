import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:human_benchmark/ad_helper.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import '../providers/decision_providers.dart';
import '../widgets/decision/decision_trial_card.dart';
import '../models/decision_trial.dart';
import '../widgets/game_page_header.dart';

class DecisionRiskPage extends ConsumerStatefulWidget {
  const DecisionRiskPage({super.key});

  @override
  ConsumerState<DecisionRiskPage> createState() => _DecisionRiskPageState();
}

class _DecisionRiskPageState extends ConsumerState<DecisionRiskPage> {
  // AdMob banner ad
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (!kReleaseMode) return;
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    final trialsAsync = ref.watch(decisionTrialsProvider);
    final session = ref.watch(decisionSessionProvider);
    final controller = ref.read(decisionSessionProvider.notifier);

    if (session.completed) {
      final total = session.responses.length;
      final risky = session.responses.where((r) => r.choseRisky).length;
      final timeMs = session.responses
          .map((r) => r.responseTime.inMilliseconds)
          .fold<int>(0, (a, b) => a + b);
      final avgMs = total == 0 ? 0 : (timeMs / total).round();
      final riskPct = total == 0 ? 0 : ((risky / total) * 100).round();
      final totalScore = session.responses.fold<double>(
        0,
        (a, r) => a + r.score,
      );

      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assessment, color: Colors.blue.shade600, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Risk & Decision Speed Summary',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Risk preference: $riskPct% risky choices\nAverage decision time: ${avgMs}ms\nScore: ${totalScore.toStringAsFixed(1)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final repo = ref.read(decisionSessionRepositoryProvider);
                      await repo.saveSession(
                        responses: session.responses,
                        totalTrials: total,
                      );
                      controller.reset();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return trialsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Failed to load trials: $e')),
      ),
      data: (trials) {
        final safeIndex = trials.isEmpty
            ? 0
            : session.currentIndex.clamp(0, trials.length - 1);
        final trial = trials.isEmpty ? null : trials[safeIndex];
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  GamePageHeader(
                    title: 'Decision-Making Speed & Risk',
                    subtitle:
                        'Make quick decisions under time pressure. Choose the option that maximizes your expected value. This test evaluates your risk assessment and decision-making patterns under various scenarios.',
                    additionalContent: trial != null
                        ? Text(
                            'Answer quickly. You have ${trial.timeLimitSeconds}s for each dilemma.',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              color: Colors.blue.shade600,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (trial != null)
                    DecisionTrialCard(
                      trial: trial,
                      onAnswered: (resp) {
                        final option = resp.chosenLabel == 'left'
                            ? trial.left
                            : trial.right;
                        final computedScore = _computeScore(option, resp);
                        controller.recordResponse(
                          DecisionResponse(
                            trialId: resp.trialId,
                            chosenLabel: resp.chosenLabel,
                            choseRisky: resp.choseRisky,
                            responseTime: resp.responseTime,
                            timedOut: resp.timedOut,
                            score: computedScore,
                          ),
                          trials.length,
                        );
                      },
                    ),

                  // Banner Ad at bottom
                  if (kReleaseMode && _isBannerAdReady && _bannerAd != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        height: _bannerAd!.size.height.toDouble(),
                        width: _bannerAd!.size.width.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _computeScore(option, resp) {
    final double base =
        (option.score as double?) ??
        ((option.isRisky
                ? (option.payoff ?? 0) * (option.probability ?? 0)
                : (option.payoff ?? 1)) /
            10.0);
    final double speedBonus =
        (10000 - resp.responseTime.inMilliseconds).clamp(0, 10000) / 10000;
    return base + speedBonus;
  }
}
