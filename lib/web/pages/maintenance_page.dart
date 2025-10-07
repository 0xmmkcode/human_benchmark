import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.grey50,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Maintenance Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: WebTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  size: 60,
                  color: WebTheme.primaryBlue,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Under Maintenance',
                style: WebTheme.headingLarge.copyWith(
                  color: WebTheme.grey800,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'We\'re currently working on improving your experience',
                style: WebTheme.bodyLarge.copyWith(
                  color: WebTheme.grey600,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Description
              Text(
                'Our team is performing scheduled maintenance to bring you an even better Human Benchmark experience. We\'ll be back soon with improvements and new features!',
                style: WebTheme.bodyMedium.copyWith(
                  color: WebTheme.grey600,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Progress indicator
              Column(
                children: [
                  LinearProgressIndicator(
                    backgroundColor: WebTheme.primaryBlue.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      WebTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Estimated completion: Soon™',
                    style: WebTheme.caption.copyWith(
                      color: WebTheme.grey600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Contact info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WebTheme.grey200.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Need immediate access?',
                      style: WebTheme.headingSmall.copyWith(
                        color: WebTheme.grey800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact our support team if you need urgent access to your data or have questions.',
                      style: WebTheme.bodyMedium.copyWith(
                        color: WebTheme.grey600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 20,
                          color: WebTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'contact@mmkcode.xyz',
                          style: WebTheme.bodyMedium.copyWith(
                            color: WebTheme.primaryBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Back to landing button
              TextButton(
                onPressed: () {
                  // Navigate back to landing page
                  context.push('/');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Back to Landing Page',
                  style: WebTheme.bodyMedium.copyWith(
                    color: WebTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
