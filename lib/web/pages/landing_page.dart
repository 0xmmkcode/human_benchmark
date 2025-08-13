import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/constants/web_constants.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;

class LandingPage extends StatefulWidget {
  final VoidCallback onStartApp;
  final VoidCallback? onAbout;
  final VoidCallback? onFeatures;

  const LandingPage({
    Key? key,
    required this.onStartApp,
    this.onAbout,
    this.onFeatures,
  }) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(Duration(milliseconds: 300));
    _fadeController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _slideController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _scaleController.forward();
    await Future.delayed(Duration(milliseconds: 300));
    _rotateController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.grey50,
      body: Stack(
        children: [
          // Decorative animated background
          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                _buildAnimatedHeader(context),
                _buildHeroSection(context),
                _buildFeaturesSection(context),
                _buildAboutSection(context),
                _buildMobileShowcase(context),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 23),
        decoration: BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value * 0.1,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          WebTheme.primaryBlue,
                          WebTheme.primaryBlueLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: WebTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsetsGeometry.all(8),
                      child: Image.asset(
                        "assets/images/human_benchmark_onlylogo_white.png",
                        height: 18,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: 12),
            Text(
              WebConstants.appName,
              style: WebTheme.headingMedium.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [WebTheme.primaryBlue, WebTheme.primaryBlueLight],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
              ),
            ),

            Spacer(),

            // Navigation
            Row(
              children: [
                _buildAnimatedButton(
                  onPressed: () {},
                  child: Text('About', style: WebTheme.bodyLarge),
                  delay: 400,
                ),
                SizedBox(width: 16),
                _buildAnimatedButton(
                  onPressed: () {},
                  child: Text('Features', style: WebTheme.bodyLarge),
                  delay: 600,
                ),
                SizedBox(width: 16),
                _buildAnimatedButton(
                  onPressed: widget.onStartApp,
                  child: Text('Get Started'),
                  isPrimary: true,
                  delay: 800,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required Widget child,
    bool isPrimary = false,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, childWidget) {
        return Transform.scale(
          scale: value,
          child: isPrimary
              ? ElevatedButton(
                  onPressed: onPressed,
                  style: WebTheme.primaryButton.copyWith(
                    elevation: MaterialStateProperty.all(8),
                    shadowColor: MaterialStateProperty.all(
                      WebTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: child,
                )
              : TextButton(onPressed: onPressed, child: child),
        );
      },
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 100, vertical: 100),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated Title
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(-50 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: Text(
                            'Test Your Cognitive Limits',
                            style: WebTheme.headingLarge.copyWith(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader =
                                    LinearGradient(
                                      colors: [
                                        WebTheme.primaryBlue,
                                        WebTheme.primaryBlueLight,
                                      ],
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 600, 70),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 30),

                  // Animated Description
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(-30 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: Text(
                            'Challenge your reaction time, memory, and cognitive abilities with our scientifically-designed brain training games. Available on mobile and web.',
                            style: WebTheme.bodyLarge.copyWith(
                              fontSize: 20,
                              height: 1.6,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 40),

                  // Animated Buttons
                  Row(
                    children: [
                      _buildHeroButton(
                        onPressed: widget.onStartApp,
                        text: 'Start Testing Now',
                        isPrimary: true,
                        delay: 400,
                      ),
                      SizedBox(width: 20),
                      _buildHeroButton(
                        onPressed: () {},
                        text: 'Learn More',
                        isPrimary: false,
                        delay: 600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Gap(100),
            Expanded(
              flex: 1,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  child: Image.asset(
                    'assets/images/frame_phone.jpg',
                    fit: BoxFit.fitHeight,
                    height: 700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroButton({
    required VoidCallback onPressed,
    required String text,
    required bool isPrimary,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: isPrimary
              ? ElevatedButton(
                  onPressed: onPressed,
                  style: WebTheme.largePrimaryButton.copyWith(
                    elevation: MaterialStateProperty.all(12),
                    shadowColor: MaterialStateProperty.all(
                      WebTheme.primaryBlue.withOpacity(0.4),
                    ),
                    backgroundColor: MaterialStateProperty.all(
                      WebTheme.primaryBlue,
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : OutlinedButton(
                  onPressed: onPressed,
                  style: WebTheme.secondaryButton.copyWith(
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    side: MaterialStateProperty.all(
                      BorderSide(color: WebTheme.primaryBlue, width: 2),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: WebTheme.primaryBlue,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      color: Colors.white,
      child: Column(
        children: [
          // Animated Section Title
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Text(
                    'Why Choose Human Benchmark?',
                    style: WebTheme.headingLarge.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 80),

          // Animated Feature Cards
          Row(
            children: [
              _buildAnimatedFeatureCard(
                icon: Icons.timer,
                title: 'Reaction Time',
                description:
                    'Test your reflexes with our precise reaction time game. Challenge yourself to beat your best score.',
                delay: 200,
              ),
              SizedBox(width: 24),
              _buildAnimatedFeatureCard(
                icon: Icons.leaderboard,
                title: 'Global Leaderboard',
                description:
                    'Compete with players worldwide and see how you rank among the fastest minds.',
                delay: 400,
              ),
              SizedBox(width: 24),
              _buildAnimatedFeatureCard(
                icon: Icons.devices,
                title: 'Cross-Platform',
                description:
                    'Play on mobile, tablet, or desktop. Your progress syncs across all devices.',
                delay: 600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            WebTheme.primaryBlue.withOpacity(0.1),
                            WebTheme.primaryBlueLight.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(icon, size: 50, color: WebTheme.primaryBlue),
                    ),
                    SizedBox(height: 28),
                    Text(
                      title,
                      style: WebTheme.headingMedium.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: WebTheme.primaryBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      description,
                      style: WebTheme.bodyLarge.copyWith(
                        height: 1.6,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          // Animated Section Title
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Text(
                    'About Our Mission',
                    style: WebTheme.headingLarge.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            WebTheme.primaryBlue,
                            WebTheme.primaryBlueLight,
                          ],
                        ).createShader(const Rect.fromLTWH(0, 0, 500, 50)),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 80),

          // Animated About Cards
          Row(
            children: [
              _buildAnimatedAboutCard(
                icon: Icons.psychology,
                title: 'Advancing Cognitive Science',
                description:
                    'We believe that understanding our cognitive abilities is the first step to improving them. Our platform provides scientifically-validated tests that help users measure and track their mental performance.',
                delay: 200,
              ),
              SizedBox(width: 24),
              _buildAnimatedAboutCard(
                icon: Icons.accessibility_new,
                title: 'Accessible to Everyone',
                description:
                    'Cognitive testing shouldn\'t be limited to research labs. We\'ve made these valuable tools available to everyone through intuitive, engaging, and scientifically-accurate applications.',
                delay: 400,
              ),
            ],
          ),

          SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildAnimatedAboutCard({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: WebTheme.grey50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: WebTheme.primaryBlue.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            WebTheme.primaryBlue.withOpacity(0.1),
                            WebTheme.primaryBlueLight.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, size: 40, color: WebTheme.primaryBlue),
                    ),
                    SizedBox(height: 24),
                    Text(
                      title,
                      style: WebTheme.headingMedium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: WebTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      description,
                      style: WebTheme.bodyLarge.copyWith(
                        height: 1.6,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileShowcase(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 40, right: 40, bottom: 100),
      child: Column(
        children: [
          // Animated Section Title
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Text(
                    'Available on Mobile',
                    style: WebTheme.headingLarge.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            WebTheme.primaryBlue,
                            WebTheme.primaryBlueLight,
                          ],
                        ).createShader(const Rect.fromLTWH(0, 0, 500, 50)),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Text(
                    'Download our mobile app for the best experience',
                    style: WebTheme.bodyLarge.copyWith(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 60),

          // Simplified centered download CTA (no phone mockup)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: WebTheme.primaryBlue.withOpacity(0.12),
                          blurRadius: 30,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Download Now',
                          textAlign: TextAlign.center,
                          style: WebTheme.headingMedium.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: WebTheme.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Free to play • Track progress • Compete globally • Cross‑platform sync',
                          textAlign: TextAlign.center,
                          style: WebTheme.bodyLarge.copyWith(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 28),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                final url =
                                    'https://play.google.com/store/apps/details?id=xyz.mmkcode.focusflow';
                                html.window.open(url, '_blank');
                              },
                              style: WebTheme.primaryButton.copyWith(
                                padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                                elevation: MaterialStateProperty.all(8),
                              ),
                              child: Text(
                                'Get Mobile App',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: widget.onStartApp,
                              style: WebTheme.secondaryButton.copyWith(
                                padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                                side: MaterialStateProperty.all(
                                  BorderSide(
                                    color: WebTheme.primaryBlue,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Play on Web',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: WebTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [WebTheme.grey100, WebTheme.grey50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2024 Human Benchmark. All rights reserved.',
                    style: WebTheme.bodyLarge.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => context.go('/privacy'),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: WebTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      TextButton(
                        onPressed: () => context.go('/terms'),
                        child: Text(
                          'Terms of Service',
                          style: TextStyle(
                            color: WebTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DecorBackground extends StatelessWidget {
  const _DecorBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Subtle radial glow top-left
            Positioned(
              left: -80,
              top: -80,
              child: _glowCircle(300, WebTheme.primaryBlue, 0.12),
            ),
            // Subtle radial glow bottom-right
            Positioned(
              right: -100,
              bottom: -100,
              child: _glowCircle(360, WebTheme.primaryBlueLight, 0.10),
            ),
            // Soft blurred band across center
            Positioned.fill(
              top: 220,
              bottom: 420,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      height: 160,
                      width: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            WebTheme.primaryBlue.withOpacity(0.06),
                            Colors.white.withOpacity(0.0),
                            WebTheme.primaryBlueLight.withOpacity(0.06),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowCircle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
