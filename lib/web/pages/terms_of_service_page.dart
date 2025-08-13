import 'package:flutter/material.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:go_router/go_router.dart';

const String kTermsLastUpdated = String.fromEnvironment(
  'TERMS_LAST_UPDATED',
  defaultValue: 'Today',
);

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
                        'Terms of Service',
                        style: WebTheme.headingLarge.copyWith(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Last updated: $kTermsLastUpdated',
                        style: WebTheme.bodyLarge.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Acceptance of terms',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'By using Human Benchmark, you agree to these Terms. If you do not agree, do not use the app.',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Use of the service',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _bullet(
                        'You must comply with applicable laws and not misuse the service.',
                      ),
                      _bullet(
                        'We may update or discontinue features at any time.',
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Accounts and Google Sign-In',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _bullet(
                        'You may sign in using Google. You are responsible for keeping your account secure.',
                      ),
                      _bullet(
                        'We may suspend or terminate accounts for violations of these Terms.',
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'User content and data',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _bullet(
                        'We collect gameplay data (e.g., reaction times, scores) to provide features and statistics.',
                      ),
                      _bullet(
                        'We handle your data as described in our Privacy Policy.',
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
                        'The mobile app displays ads via Google AdMob. Ads may be personalized subject to your device settings and applicable policies.',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Disclaimers',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The service is provided “as is” without warranties. We do not guarantee accuracy, availability, or suitability for any purpose.',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Limitation of liability',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'To the maximum extent permitted by law, we are not liable for any indirect, incidental, or consequential damages arising from use of the service.',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Changes to these Terms',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We may update these Terms over time. Continued use of the service means you accept the updated Terms.',
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
                        'Questions about these Terms? Contact: admin@mmkcode.cloud',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
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
