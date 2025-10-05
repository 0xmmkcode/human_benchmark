import 'package:flutter/material.dart';
import 'package:human_benchmark/services/auth_service.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:human_benchmark/web/widgets/app_loading.dart';

class AuthRequiredWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? customSignInPrompt;
  final bool showLoadingIndicator;

  const AuthRequiredWrapper({
    Key? key,
    required this.child,
    this.title,
    this.subtitle,
    this.customSignInPrompt,
    this.showLoadingIndicator = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final bool isAuthenticated = snapshot.data != null;
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        if (isLoading && showLoadingIndicator) {
          return Scaffold(
            backgroundColor: WebTheme.grey50,
            body: const Center(child: AppLoading()),
          );
        }

        if (!isAuthenticated) {
          return customSignInPrompt ?? _buildDefaultSignInPrompt(context);
        }

        return child;
      },
    );
  }

  Widget _buildDefaultSignInPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [WebTheme.primaryBlue, WebTheme.primaryBlueLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  title ?? 'Sign In Required',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  subtitle ??
                      'Please sign in to access this feature and save your progress.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final cred = await AuthService.signInWithGoogle();
                        if (context.mounted && cred != null) {
                          // Replace the sign-in prompt route to avoid back-stack errors
                          Navigator.of(context).maybePop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sign in failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WebTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google.png',
                          height: 20,
                          width: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
