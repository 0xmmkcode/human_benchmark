import 'package:flutter/material.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:go_router/go_router.dart';

const String kPolicyLastUpdated = String.fromEnvironment(
  'POLICY_LAST_UPDATED',
  defaultValue: 'Today',
);

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top bar (copied from landing page, without primary CTA)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 23),
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [WebTheme.primaryBlue, WebTheme.primaryBlueLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: WebTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      "assets/images/human_benchmark_onlylogo_white.png",
                      height: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Human Benchmark',
                  style: WebTheme.headingMedium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [
                          WebTheme.primaryBlue,
                          WebTheme.primaryBlueLight,
                        ],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: Text('Home', style: WebTheme.bodyLarge),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => context.go('/privacy'),
                      child: Text('Privacy Policy', style: WebTheme.bodyLarge),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => context.go('/terms'),
                      child: Text('Terms', style: WebTheme.bodyLarge),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: WebTheme.headingLarge.copyWith(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Last updated: $kPolicyLastUpdated',
                        style: WebTheme.bodyLarge.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Who we are',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Human Benchmark is a casual cognitive testing app available on mobile and web. This policy explains what data we collect and how we use it.',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Data we collect',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _bullet(
                        'Account info from Google Sign-In: name, email address, and profile picture.',
                      ),
                      _bullet(
                        'Gameplay data: reaction times, scores, attempts, and related statistics.',
                      ),
                      _bullet(
                        'Basic device and app analytics (e.g., crashes, performance metrics).',
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'How we use your data',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _bullet(
                        'Authenticate your account and keep you signed in.',
                      ),
                      _bullet(
                        'Save scores, show leaderboards, and display personal stats like best or average times.',
                      ),
                      _bullet(
                        'Improve app quality, performance, and new feature decisions using aggregated gameplay data.',
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Advertising',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We use Google AdMob to display ads in the mobile app. AdMob may collect device identifiers and other data to provide and measure ads. '
                        'For more details about data collected by Google’s ad products, please see Google’s Privacy Policy and your device’s ad settings.',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Data retention',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We retain account and gameplay data for as long as your account remains active or as needed to provide the service. '
                        'You may request deletion of your data as described below.',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Your choices',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _bullet(
                        'You can sign out at any time from the app settings.',
                      ),
                      _bullet(
                        'You can request account/data deletion by contacting us.',
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Children’s privacy',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Our app is not directed to children under the digital age of consent in your region. If you believe we have collected data from a child, contact us to delete it.',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Contact us',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you have questions or requests about this policy or your data, please reach out to us at: admin@mmkcode.cloud',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Text(
                        'We may update this policy from time to time. Continued use signifies acceptance of the latest version.',
                        style: WebTheme.bodyLarge.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: WebTheme.bodyLarge.copyWith(
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
