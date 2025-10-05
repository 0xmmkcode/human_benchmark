import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/constants/web_constants.dart';
import 'package:human_benchmark/services/web_settings_service.dart';
import 'package:human_benchmark/models/web_settings.dart';
import 'dart:html' as html;
import 'dart:ui';

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

  // GlobalKeys for scrolling to sections
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _personalityKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _mobileKey = GlobalKey();

  // ScrollController for smooth scrolling
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  // Method to scroll to a specific section
  void _scrollToSection(GlobalKey key) {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero).dy;
      final offset =
          _scrollController.offset + position - 100; // Offset for header
      _scrollController.animateTo(
        offset,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // Method to show mobile menu
  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          WebTheme.primaryBlue,
                          WebTheme.primaryBlueLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.menu, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Menu',
                    style: WebTheme.headingMedium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildMobileMenuItem('Home', Icons.home_outlined, () {
                    Navigator.pop(context);
                    _scrollToSection(_heroKey);
                  }),
                  _buildMobileMenuItem('Features', Icons.star_outline, () {
                    Navigator.pop(context);
                    _scrollToSection(_featuresKey);
                  }),
                  _buildMobileMenuItem(
                    'Personality',
                    Icons.psychology_outlined,
                    () {
                      Navigator.pop(context);
                      _scrollToSection(_personalityKey);
                    },
                  ),
                  _buildMobileMenuItem('About', Icons.info_outline, () {
                    Navigator.pop(context);
                    _scrollToSection(_aboutKey);
                  }),
                  _buildMobileMenuItem(
                    'Mobile App',
                    Icons.phone_android_outlined,
                    () {
                      Navigator.pop(context);
                      _scrollToSection(_mobileKey);
                    },
                  ),
                ],
              ),
            ),

            // Bottom section with Get Started button
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: WebTheme.grey50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Text(
                    'Ready to test your limits?',
                    style: WebTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  StreamBuilder<WebSettings>(
                    stream: WebSettingsService.getWebSettingsStream(),
                    builder: (context, snapshot) {
                      final webSettings =
                          snapshot.data ?? WebSettings.defaultSettings;

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            if (webSettings.webGameEnabled) {
                              // Web game is enabled - go to web app
                              widget.onStartApp();
                            } else {
                              // Web game is disabled - go to Play Store
                              final url =
                                  webSettings.playStoreLink ??
                                  'https://play.google.com/store/apps/details?id=xyz.mmkcode.humanbenchmark.human_benchmark';
                              html.window.open(url, '_blank');
                            }
                          },
                          style: WebTheme.largePrimaryButton.copyWith(
                            elevation: MaterialStateProperty.all(8),
                            shadowColor: MaterialStateProperty.all(
                              WebTheme.primaryBlue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Get Started Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMenuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: WebTheme.primaryBlue),
      title: Text(
        title,
        style: WebTheme.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: WebTheme.primaryBlue,
        ),
      ),
      onTap: onTap,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: WebTheme.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildAnimatedHeader(context),
            _buildHeroSection(context),
            _buildFeaturesSection(context),
            _buildPersonalityTestSection(context),
            _buildAboutSection(context),
            _buildMobileShowcase(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 900;
    final bool isMobile = width < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : (isSmall ? 20 : 24),
              vertical: isMobile ? 16 : 23,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1200),
                child: Row(
                  children: [
                    // Animated Logo
                    AnimatedBuilder(
                      animation: _rotateAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotateAnimation.value * 0.1,
                          child: Container(
                            width: isMobile ? 36 : 40,
                            height: isMobile ? 36 : 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  WebTheme.primaryBlue,
                                  WebTheme.primaryBlueLight,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                isMobile ? 10 : 12,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: WebTheme.primaryBlue.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 6 : 8),
                              child: Image.asset(
                                "assets/images/human_benchmark_onlylogo_white.png",
                                height: isMobile ? 16 : 50,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Text(
                      WebConstants.appName,
                      style: WebTheme.headingMedium.copyWith(
                        fontSize: isMobile ? 18 : (isSmall ? 20 : 24),
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

                    Spacer(),

                    // Navigation
                    Row(
                      children: [
                        if (!isSmall) ...[
                          _buildAnimatedButton(
                            onPressed: () => _scrollToSection(_heroKey),
                            child: Text('Home', style: WebTheme.bodyLarge),
                            delay: 200,
                          ),
                          SizedBox(width: 16),
                          _buildAnimatedButton(
                            onPressed: () => _scrollToSection(_featuresKey),
                            child: Text('Features', style: WebTheme.bodyLarge),
                            delay: 300,
                          ),
                          SizedBox(width: 16),
                          _buildAnimatedButton(
                            onPressed: () => _scrollToSection(_personalityKey),
                            child: Text(
                              'Personality',
                              style: WebTheme.bodyLarge,
                            ),
                            delay: 400,
                          ),
                          SizedBox(width: 16),
                          _buildAnimatedButton(
                            onPressed: () => _scrollToSection(_aboutKey),
                            child: Text('About', style: WebTheme.bodyLarge),
                            delay: 500,
                          ),
                          SizedBox(width: 16),
                          _buildAnimatedButton(
                            onPressed: () => _scrollToSection(_mobileKey),
                            child: Text('Mobile', style: WebTheme.bodyLarge),
                            delay: 600,
                          ),
                          SizedBox(width: 16),
                        ] else ...[
                          // Mobile menu button
                          _buildAnimatedButton(
                            onPressed: () => _showMobileMenu(context),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: WebTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.menu,
                                color: WebTheme.primaryBlue,
                                size: isMobile ? 20 : 24,
                              ),
                            ),
                            delay: 400,
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                        ],
                        StreamBuilder<WebSettings>(
                          stream: WebSettingsService.getWebSettingsStream(),
                          builder: (context, snapshot) {
                            final webSettings =
                                snapshot.data ?? WebSettings.defaultSettings;

                            return _buildAnimatedButton(
                              onPressed: () {
                                if (webSettings.webGameEnabled) {
                                  // Web game is enabled - go to web app
                                  widget.onStartApp();
                                } else {
                                  // Web game is disabled - go to Play Store
                                  final url =
                                      webSettings.playStoreLink ??
                                      'https://play.google.com/store/apps/details?id=xyz.mmkcode.humanbenchmark.human_benchmark';
                                  html.window.open(url, '_blank');
                                }
                              },
                              child: Text(
                                isMobile ? 'Start' : 'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                              isPrimary: true,
                              delay: 800,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    final double width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 900;
    final bool isMobile = width < 600;
    final bool isTiny = width < 400;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        key: _heroKey,
        decoration: BoxDecoration(color: WebTheme.grey50),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isTiny ? 16 : (isMobile ? 20 : (isSmall ? 24 : 100)),
          vertical: isTiny ? 30 : (isMobile ? 40 : (isSmall ? 60 : 100)),
        ),
        child: isSmall
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
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
                              fontSize: isTiny ? 24 : (isMobile ? 28 : 32),
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
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTiny ? 16 : (isMobile ? 20 : 24)),
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
                              fontSize: isTiny ? 14 : (isMobile ? 16 : 18),
                              height: 1.6,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTiny ? 20 : (isMobile ? 24 : 40)),

                  // Animated Buttons
                  isTiny
                      ? Column(
                          children: [
                            StreamBuilder<WebSettings>(
                              stream: WebSettingsService.getWebSettingsStream(),
                              builder: (context, snapshot) {
                                final webSettings =
                                    snapshot.data ??
                                    WebSettings.defaultSettings;

                                return _buildHeroButton(
                                  onPressed: () {
                                    if (webSettings.webGameEnabled) {
                                      // Web game is enabled - go to web app
                                      widget.onStartApp();
                                    } else {
                                      // Web game is disabled - go to Play Store
                                      final url =
                                          webSettings.playStoreLink ??
                                          'https://play.google.com/store/apps/details?id=xyz.mmkcode.humanbenchmark.human_benchmark';
                                      html.window.open(url, '_blank');
                                    }
                                  },
                                  text: 'Start Testing Now',
                                  isPrimary: true,
                                  delay: 400,
                                );
                              },
                            ),
                            SizedBox(height: 16),
                            _buildHeroButton(
                              onPressed: () {},
                              text: 'Learn More',
                              isPrimary: false,
                              delay: 600,
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StreamBuilder<WebSettings>(
                              stream: WebSettingsService.getWebSettingsStream(),
                              builder: (context, snapshot) {
                                final webSettings =
                                    snapshot.data ??
                                    WebSettings.defaultSettings;

                                return _buildHeroButton(
                                  onPressed: () {
                                    if (webSettings.webGameEnabled) {
                                      // Web game is enabled - go to web app
                                      widget.onStartApp();
                                    } else {
                                      // Web game is disabled - go to Play Store
                                      final url =
                                          webSettings.playStoreLink ??
                                          'https://play.google.com/store/apps/details?id=xyz.mmkcode.humanbenchmark.human_benchmark';
                                      html.window.open(url, '_blank');
                                    }
                                  },
                                  text: 'Start Testing Now',
                                  isPrimary: true,
                                  delay: 400,
                                );
                              },
                            ),
                            SizedBox(width: isMobile ? 12 : 20),
                            _buildHeroButton(
                              onPressed: () {},
                              text: 'Learn More',
                              isPrimary: false,
                              delay: 600,
                            ),
                          ],
                        ),
                  SizedBox(height: isTiny ? 20 : 24),
                  Center(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Image.asset(
                          'assets/images/frame_phone.jpg',
                          fit: BoxFit.fitHeight,
                          height: isTiny ? 280 : (isMobile ? 380 : 500),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // (same content as above for large screens)
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
                            StreamBuilder<WebSettings>(
                              stream: WebSettingsService.getWebSettingsStream(),
                              builder: (context, snapshot) {
                                final webSettings =
                                    snapshot.data ??
                                    WebSettings.defaultSettings;

                                return _buildHeroButton(
                                  onPressed: () {
                                    if (webSettings.webGameEnabled) {
                                      // Web game is enabled - go to web app
                                      widget.onStartApp();
                                    } else {
                                      // Web game is disabled - go to Play Store
                                      final url =
                                          webSettings.playStoreLink ??
                                          'https://play.google.com/store/apps/details?id=xyz.mmkcode.humanbenchmark.human_benchmark';
                                      html.window.open(url, '_blank');
                                    }
                                  },
                                  text: 'Start Testing Now',
                                  isPrimary: true,
                                  delay: 400,
                                );
                              },
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
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 40),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Image.asset(
                            'assets/images/frame_phone.jpg',
                            fit: BoxFit.fitHeight,
                            height: 700,
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

  Widget _buildHeroButton({
    required VoidCallback onPressed,
    required String text,
    required bool isPrimary,
    required int delay,
  }) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    final bool isTiny = width < 400;

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
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(
                        horizontal: isTiny ? 20 : (isMobile ? 24 : 32),
                        vertical: isTiny ? 14 : (isMobile ? 16 : 20),
                      ),
                    ),
                  ),
                  child: Text(
                    text,
                    style: WebTheme.bodyLarge.copyWith(
                      fontSize: isTiny ? 16 : (isMobile ? 18 : 20),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: onPressed,
                  style: WebTheme.secondaryButton.copyWith(
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(
                        horizontal: isTiny ? 20 : (isMobile ? 24 : 32),
                        vertical: isTiny ? 14 : (isMobile ? 16 : 20),
                      ),
                    ),
                    side: MaterialStateProperty.all(
                      BorderSide(color: WebTheme.primaryBlue, width: 2),
                    ),
                  ),
                  child: Text(
                    text,
                    style: WebTheme.bodyLarge.copyWith(
                      fontSize: isTiny ? 16 : (isMobile ? 18 : 20),
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
    final double width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 900;
    final bool isMobile = width < 600;
    final bool isTiny = width < 400;

    return Container(
      key: _featuresKey,
      padding: EdgeInsets.symmetric(
        horizontal: isTiny ? 16 : (isMobile ? 20 : (isSmall ? 24 : 100)),
        vertical: isTiny ? 40 : (isMobile ? 60 : (isSmall ? 80 : 100)),
      ),
      decoration: BoxDecoration(color: Colors.white),
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
                      fontSize: isTiny
                          ? 28
                          : (isMobile ? 32 : (isSmall ? 36 : 42)),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isTiny ? 30 : (isMobile ? 40 : (isSmall ? 60 : 80))),

          // Animated Feature Cards
          isSmall
              ? Column(
                  children: [
                    _buildAnimatedFeatureCard(
                      icon: Icons.timer,
                      title: 'Reaction Time',
                      description:
                          'Test your reflexes with our precise reaction time game. Challenge yourself to beat your best score.',
                      delay: 200,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                    SizedBox(height: isTiny ? 20 : 24),
                    _buildAnimatedFeatureCard(
                      icon: Icons.leaderboard,
                      title: 'Global Leaderboard',
                      description:
                          'Compete with players worldwide and see how you rank among the fastest minds.',
                      delay: 400,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                    SizedBox(height: isTiny ? 20 : 24),
                    _buildAnimatedFeatureCard(
                      icon: Icons.devices,
                      title: 'Cross-Platform',
                      description:
                          'Play on mobile, tablet, or desktop. Your progress syncs across all devices.',
                      delay: 600,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildAnimatedFeatureCard(
                      icon: Icons.timer,
                      title: 'Reaction Time',
                      description:
                          'Test your reflexes with our precise reaction time game. Challenge yourself to beat your best score.',
                      delay: 200,
                      isMobile: false,
                      isTiny: false,
                    ),
                    SizedBox(width: 24),
                    _buildAnimatedFeatureCard(
                      icon: Icons.leaderboard,
                      title: 'Global Leaderboard',
                      description:
                          'Compete with players worldwide and see how you rank among the fastest minds.',
                      delay: 400,
                      isMobile: false,
                      isTiny: false,
                    ),
                    SizedBox(width: 24),
                    _buildAnimatedFeatureCard(
                      icon: Icons.devices,
                      title: 'Cross-Platform',
                      description:
                          'Play on mobile, tablet, or desktop. Your progress syncs across all devices.',
                      delay: 600,
                      isMobile: false,
                      isTiny: false,
                    ),
                  ],
                ),
          SizedBox(height: isTiny ? 20 : 24),
        ],
      ),
    );
  }

  Widget _buildAnimatedFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
    bool isMobile = false,
    bool isTiny = false,
    bool expand = true,
  }) {
    final Widget cardContent = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(isTiny ? 20 : (isMobile ? 24 : 32)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isTiny ? 16 : (isMobile ? 20 : 24),
                ),
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
                    width: isTiny ? 80 : (isMobile ? 90 : 100),
                    height: isTiny ? 80 : (isMobile ? 90 : 100),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          WebTheme.primaryBlue.withOpacity(0.1),
                          WebTheme.primaryBlueLight.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        isTiny ? 20 : (isMobile ? 22 : 25),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: isTiny ? 40 : (isMobile ? 45 : 50),
                      color: WebTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: isTiny ? 20 : (isMobile ? 24 : 28)),
                  Text(
                    title,
                    style: WebTheme.headingMedium.copyWith(
                      fontSize: isTiny ? 20 : (isMobile ? 22 : 26),
                      fontWeight: FontWeight.bold,
                      color: WebTheme.primaryBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTiny ? 16 : 20),
                  Text(
                    description,
                    style: WebTheme.bodyLarge.copyWith(
                      fontSize: isTiny ? 13 : (isMobile ? 14 : 16),
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
    );
    return expand ? Expanded(child: cardContent) : cardContent;
  }

  Widget _buildPersonalityTestSection(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 900;
    final bool isMobile = width < 600;
    final bool isTiny = width < 400;

    return Container(
      key: _personalityKey,
      padding: EdgeInsets.symmetric(horizontal: 100, vertical: 100),
      decoration: BoxDecoration(color: WebTheme.grey50),
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
                    'Discover Your Personality',
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
          SizedBox(height: 40),

          // Animated Description
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Text(
                    'Take our scientifically-validated Big Five personality assessment and see how you compare to others worldwide.',
                    textAlign: TextAlign.center,
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
          SizedBox(height: 60),

          // Personality Test Cards
          isSmall
              ? Column(
                  children: [
                    _buildPersonalityTestCard(
                      icon: Icons.psychology,
                      title: 'Big Five Assessment',
                      description:
                          '50 research-grade questions measuring Openness, Conscientiousness, Extraversion, Agreeableness, and Neuroticism.',
                      delay: 200,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                    SizedBox(height: isTiny ? 20 : 24),
                    _buildPersonalityTestCard(
                      icon: Icons.analytics,
                      title: 'Detailed Results',
                      description:
                          'Get comprehensive insights into your personality traits with percentile rankings and detailed explanations.',
                      delay: 400,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                    SizedBox(height: isTiny ? 20 : 24),
                    _buildPersonalityTestCard(
                      icon: Icons.leaderboard,
                      title: 'Global Comparison',
                      description:
                          'See how your personality traits compare to people worldwide and discover what makes you unique.',
                      delay: 600,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildPersonalityTestCard(
                      icon: Icons.psychology,
                      title: 'Big Five Assessment',
                      description:
                          '50 research-grade questions measuring Openness, Conscientiousness, Extraversion, Agreeableness, and Neuroticism.',
                      delay: 200,
                      isMobile: false,
                      isTiny: false,
                    ),
                    SizedBox(width: 24),
                    _buildPersonalityTestCard(
                      icon: Icons.analytics,
                      title: 'Detailed Results',
                      description:
                          'Get comprehensive insights into your personality traits with percentile rankings and detailed explanations.',
                      delay: 400,
                      isMobile: false,
                      isTiny: false,
                    ),
                    SizedBox(width: 24),
                    _buildPersonalityTestCard(
                      icon: Icons.leaderboard,
                      title: 'Global Comparison',
                      description:
                          'See how your personality traits compare to people worldwide and discover what makes you unique.',
                      delay: 600,
                      isMobile: false,
                      isTiny: false,
                    ),
                  ],
                ),
          SizedBox(height: 60),

          // Call to Action Button
          /*TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to personality quiz
                    context.go('/app/personality');
                  },
                  style: WebTheme.largePrimaryButton.copyWith(
                    elevation: MaterialStateProperty.all(12),
                    shadowColor: MaterialStateProperty.all(
                      WebTheme.primaryBlue.withOpacity(0.4),
                    ),
                    backgroundColor: MaterialStateProperty.all(
                      WebTheme.primaryBlue,
                    ),
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    ),
                  ),
                  child: Text(
                    'Take Personality Test Now',
                    style: WebTheme.bodyLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ), */
        ],
      ),
    );
  }

  Widget _buildPersonalityTestCard({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
    bool isMobile = false,
    bool isTiny = false,
    bool expand = true,
  }) {
    final Widget cardContent = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(isTiny ? 20 : (isMobile ? 24 : 32)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isTiny ? 16 : (isMobile ? 20 : 24),
                ),
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
                    width: isTiny ? 80 : (isMobile ? 90 : 100),
                    height: isTiny ? 80 : (isMobile ? 90 : 100),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          WebTheme.primaryBlue.withOpacity(0.1),
                          WebTheme.primaryBlueLight.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        isTiny ? 20 : (isMobile ? 22 : 25),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: isTiny ? 40 : (isMobile ? 45 : 50),
                      color: WebTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: isTiny ? 20 : (isMobile ? 24 : 28)),
                  Text(
                    title,
                    style: WebTheme.headingMedium.copyWith(
                      fontSize: isTiny ? 20 : (isMobile ? 22 : 26),
                      fontWeight: FontWeight.bold,
                      color: WebTheme.primaryBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTiny ? 16 : 20),
                  Text(
                    description,
                    style: WebTheme.bodyLarge.copyWith(
                      fontSize: isTiny ? 13 : (isMobile ? 14 : 16),
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
    );
    return expand ? Expanded(child: cardContent) : cardContent;
  }

  Widget _buildNumberMemorySection(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 900;
    final bool isMobile = width < 600;
    final bool isTiny = width < 400;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 100, vertical: 100),
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
                    'Number Memory',
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
          SizedBox(height: 40),

          // Animated Description
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Text(
                    'Test your ability to remember numbers and sequences. Challenge your memory and concentration. The game continues progressively until you make a mistake. Sign in to play and save your scores.',
                    textAlign: TextAlign.center,
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
          SizedBox(height: 60),

          // Number Memory Cards
          isSmall
              ? Column(
                  children: [
                    _buildNumberMemoryCard(
                      icon: Icons.memory,
                      title: 'Number Recall',
                      description:
                          'Test your ability to recall numbers from a sequence. Challenge your memory and concentration.',
                      delay: 200,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                    SizedBox(height: isTiny ? 20 : 24),
                    _buildNumberMemoryCard(
                      icon: Icons.numbers,
                      title: 'Sequence Memory',
                      description:
                          'Test your ability to remember and repeat a sequence of numbers. Challenge your memory and concentration.',
                      delay: 400,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                    SizedBox(height: isTiny ? 20 : 24),
                    _buildNumberMemoryCard(
                      icon: Icons.leaderboard,
                      title: 'Global Leaderboard',
                      description:
                          'Compete with players worldwide and see how you rank among the fastest minds.',
                      delay: 600,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildNumberMemoryCard(
                      icon: Icons.memory,
                      title: 'Number Recall',
                      description:
                          'Test your ability to recall numbers from a sequence. Challenge your memory and concentration.',
                      delay: 200,
                      isMobile: false,
                      isTiny: false,
                    ),
                    SizedBox(width: 24),
                    _buildNumberMemoryCard(
                      icon: Icons.numbers,
                      title: 'Sequence Memory',
                      description:
                          'Test your ability to remember and repeat a sequence of numbers. Challenge your memory and concentration.',
                      delay: 400,
                      isMobile: false,
                      isTiny: false,
                    ),
                    SizedBox(width: 24),
                    _buildNumberMemoryCard(
                      icon: Icons.leaderboard,
                      title: 'Global Leaderboard',
                      description:
                          'Compete with players worldwide and see how you rank among the fastest minds.',
                      delay: 600,
                      isMobile: false,
                      isTiny: false,
                    ),
                  ],
                ),
          SizedBox(height: 60),

          // Call to Action Button
          /*TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to personality quiz
                    context.go('/app/personality');
                  },
                  style: WebTheme.largePrimaryButton.copyWith(
                    elevation: MaterialStateProperty.all(12),
                    shadowColor: MaterialStateProperty.all(
                      WebTheme.primaryBlue.withOpacity(0.4),
                    ),
                    backgroundColor: MaterialStateProperty.all(
                      WebTheme.primaryBlue,
                    ),
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    ),
                  ),
                  child: Text(
                    'Take Personality Test Now',
                    style: WebTheme.bodyLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ), */
        ],
      ),
    );
  }

  Widget _buildNumberMemoryCard({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
    bool isMobile = false,
    bool isTiny = false,
    bool expand = true,
  }) {
    final Widget cardContent = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(isTiny ? 20 : (isMobile ? 24 : 32)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isTiny ? 16 : (isMobile ? 20 : 24),
                ),
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
                    width: isTiny ? 80 : (isMobile ? 90 : 100),
                    height: isTiny ? 80 : (isMobile ? 90 : 100),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          WebTheme.primaryBlue.withOpacity(0.1),
                          WebTheme.primaryBlueLight.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        isTiny ? 20 : (isMobile ? 22 : 25),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: isTiny ? 40 : (isMobile ? 45 : 50),
                      color: WebTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: isTiny ? 20 : (isMobile ? 24 : 28)),
                  Text(
                    title,
                    style: WebTheme.headingMedium.copyWith(
                      fontSize: isTiny ? 20 : (isMobile ? 22 : 26),
                      fontWeight: FontWeight.bold,
                      color: WebTheme.primaryBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTiny ? 16 : 20),
                  Text(
                    description,
                    style: WebTheme.bodyLarge.copyWith(
                      fontSize: isTiny ? 13 : (isMobile ? 14 : 16),
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
    );
    return expand ? Expanded(child: cardContent) : cardContent;
  }

  Widget _buildAboutSection(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 900;
    final bool isMobile = width < 600;
    final bool isTiny = width < 400;

    return Container(
      key: _aboutKey,
      padding: EdgeInsets.symmetric(horizontal: 100, vertical: 100),
      decoration: BoxDecoration(color: WebTheme.grey50),
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
          isSmall
              ? Column(
                  children: [
                    _buildAnimatedAboutCard(
                      icon: Icons.psychology,
                      title: 'Advancing Cognitive Science',
                      description:
                          'We believe that understanding our cognitive abilities is the first step to improving them. Our platform provides scientifically-validated tests that help users measure and track their mental performance.',
                      delay: 200,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                    SizedBox(height: isTiny ? 20 : 24),
                    _buildAnimatedAboutCard(
                      icon: Icons.accessibility_new,
                      title: 'Accessible to Everyone',
                      description:
                          'Cognitive testing shouldn\'t be limited to research labs. We\'ve made these valuable tools available to everyone through intuitive, engaging, and scientifically-accurate applications.',
                      delay: 400,
                      isMobile: isMobile,
                      isTiny: isTiny,
                      expand: false,
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildAnimatedAboutCard(
                      icon: Icons.psychology,
                      title: 'Advancing Cognitive Science',
                      description:
                          'We believe that understanding our cognitive abilities is the first step to improving them. Our platform provides scientifically-validated tests that help users measure and track their mental performance.',
                      delay: 200,
                      isMobile: false,
                      isTiny: false,
                    ),
                    SizedBox(width: 24),
                    _buildAnimatedAboutCard(
                      icon: Icons.accessibility_new,
                      title: 'Accessible to Everyone',
                      description:
                          'Cognitive testing shouldn\'t be limited to research labs. We\'ve made these valuable tools available to everyone through intuitive, engaging, and scientifically-accurate applications.',
                      delay: 400,
                      isMobile: false,
                      isTiny: false,
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
    bool isMobile = false,
    bool isTiny = false,
    bool expand = true,
  }) {
    final Widget cardContent = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(isTiny ? 20 : (isMobile ? 24 : 32)),
              decoration: BoxDecoration(
                color: WebTheme.primaryBlue.withOpacity(0.02),
                borderRadius: BorderRadius.circular(
                  isTiny ? 16 : (isMobile ? 20 : 24),
                ),
                border: Border.all(
                  color: WebTheme.primaryBlue.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isTiny ? 80 : (isMobile ? 90 : 100),
                    height: isTiny ? 80 : (isMobile ? 90 : 100),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          WebTheme.primaryBlue.withOpacity(0.1),
                          WebTheme.primaryBlueLight.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        isTiny ? 20 : (isMobile ? 22 : 25),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: isTiny ? 40 : (isMobile ? 45 : 50),
                      color: WebTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: isTiny ? 20 : (isMobile ? 24 : 28)),
                  Text(
                    title,
                    style: WebTheme.headingMedium.copyWith(
                      fontSize: isTiny ? 20 : (isMobile ? 22 : 26),
                      fontWeight: FontWeight.bold,
                      color: WebTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: isTiny ? 16 : 20),
                  Text(
                    description,
                    style: WebTheme.bodyLarge.copyWith(
                      fontSize: isTiny ? 13 : (isMobile ? 14 : 16),
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
    );
    return expand ? Expanded(child: cardContent) : cardContent;
  }

  Widget _buildMobileShowcase(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 900;
    final bool isMobile = width < 600;
    final bool isTiny = width < 400;

    return Container(
      key: _mobileKey,
      width: double.infinity,
      decoration: BoxDecoration(color: WebTheme.grey50),
      padding: EdgeInsets.only(
        top: isTiny ? 30 : (isMobile ? 40 : 60),
        left: isTiny ? 16 : (isMobile ? 20 : 60),
        right: isTiny ? 16 : (isMobile ? 20 : 60),
        bottom: isTiny ? 60 : (isMobile ? 80 : 100),
      ),
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
                      fontSize: isTiny ? 28 : (isMobile ? 32 : 42),
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
          SizedBox(height: isTiny ? 16 : 24),

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
                      fontSize: isTiny ? 16 : (isMobile ? 18 : 20),
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isTiny ? 40 : (isMobile ? 50 : 60)),

          // Redesigned Download Section with Animations
          _buildAnimatedDownloadSection(isTiny, isMobile, isSmall),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 900;
    final bool isMobile = width < 600;
    final bool isTiny = width < 400;

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
              padding: EdgeInsets.symmetric(
                horizontal: isTiny ? 16 : (isMobile ? 20 : 24),
                vertical: isTiny ? 30 : (isMobile ? 40 : 50),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: isSmall
                  ? Column(
                      children: [
                        // Copyright and powered by
                        Column(
                          children: [
                            Text(
                              '© 2025 Human Benchmark. All rights reserved.',
                              style: WebTheme.bodyLarge.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: isTiny ? 14 : 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  html.window.open(
                                    'https://mmkcode.xyz',
                                    '_blank',
                                  );
                                },
                                child: Text(
                                  'Powered by MMKCode',
                                  style: WebTheme.bodyLarge.copyWith(
                                    color: WebTheme.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    fontSize: isTiny ? 14 : 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTiny ? 20 : 24),

                        // Educational content
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'About Cognitive Testing',
                                style: WebTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                  fontSize: isTiny ? 14 : 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Our tests are based on established psychological research and help you understand your cognitive abilities. Regular practice can improve mental performance and provide insights into your strengths.',
                                style: WebTheme.bodyLarge.copyWith(
                                  color: Colors.blue.shade700,
                                  fontSize: isTiny ? 12 : 14,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isTiny ? 20 : 24),

                        // Links
                        Column(
                          children: [
                            TextButton(
                              onPressed: () => context.go('/privacy'),
                              child: Text(
                                'Privacy Policy',
                                style: WebTheme.bodyLarge.copyWith(
                                  color: WebTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTiny ? 14 : 16,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.go('/terms'),
                              child: Text(
                                'Terms of Service',
                                style: WebTheme.bodyLarge.copyWith(
                                  color: WebTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTiny ? 14 : 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '© 2025 Human Benchmark. All rights reserved.',
                              style: WebTheme.bodyLarge.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Gap(10),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  html.window.open(
                                    'https://mmkcode.xyz',
                                    '_blank',
                                  );
                                },
                                child: Text(
                                  'Powered by MMKCode',
                                  style: WebTheme.bodyLarge.copyWith(
                                    color: WebTheme.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                'Scientifically-based cognitive assessments',
                                style: WebTheme.bodyLarge.copyWith(
                                  color: Colors.blue.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Gap(20),
                            TextButton(
                              onPressed: () => context.go('/privacy'),
                              child: Text(
                                'Privacy Policy',
                                style: WebTheme.bodyLarge.copyWith(
                                  color: WebTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Gap(10),
                            TextButton(
                              onPressed: () => context.go('/terms'),
                              child: Text(
                                'Terms of Service',
                                style: WebTheme.bodyLarge.copyWith(
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

  Widget _buildAnimatedDownloadSection(
    bool isTiny,
    bool isMobile,
    bool isSmall,
  ) {
    return Container(
      padding: EdgeInsets.all(isTiny ? 24 : (isMobile ? 32 : 40)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, WebTheme.primaryBlue.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(isTiny ? 20 : (isMobile ? 24 : 28)),
        boxShadow: [
          BoxShadow(
            color: WebTheme.primaryBlue.withOpacity(0.15),
            blurRadius: 40,
            offset: Offset(0, 20),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: isSmall
          ? _buildMobileDownloadLayout(isTiny, isMobile)
          : _buildDesktopDownloadLayout(isTiny, isMobile),
    );
  }

  Widget _buildMobileDownloadLayout(bool isTiny, bool isMobile) {
    return Column(
      children: [
        // Text content sliding from left
        TweenAnimationBuilder<double>(
          tween: Tween(begin: -100.0, end: 0.0),
          duration: Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(value, 0),
              child: Opacity(
                opacity: (100 + value) / 100,
                child: Column(
                  children: [
                    // App icon with glow effect
                    Container(
                      width: isTiny ? 80 : (isMobile ? 100 : 120),
                      height: isTiny ? 80 : (isMobile ? 100 : 120),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            WebTheme.primaryBlue.withOpacity(0.2),
                            WebTheme.primaryBlue.withOpacity(0.05),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: WebTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.psychology,
                          size: isTiny ? 40 : (isMobile ? 50 : 60),
                          color: WebTheme.primaryBlue,
                        ),
                      ),
                    ),
                    SizedBox(height: isTiny ? 20 : 24),

                    // Title with gradient text
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          WebTheme.primaryBlue,
                          WebTheme.primaryBlueLight,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Download Now',
                        style: WebTheme.headingLarge.copyWith(
                          fontSize: isTiny ? 28 : (isMobile ? 32 : 36),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isTiny ? 12 : 16),

                    // Subtitle
                    Text(
                      'Free to play • Track progress • Compete globally',
                      style: WebTheme.bodyLarge.copyWith(
                        fontSize: isTiny ? 14 : (isMobile ? 16 : 18),
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTiny ? 8 : 12),

                    // Features list
                    Text(
                      'Cross-platform sync • Offline mode • Detailed analytics',
                      style: WebTheme.bodyMedium.copyWith(
                        fontSize: isTiny ? 12 : (isMobile ? 14 : 16),
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        SizedBox(height: isTiny ? 32 : 40),

        // Buttons sliding from right
        _buildDelayedAnimation(
          delay: Duration(milliseconds: 300),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 100.0, end: 0.0),
            duration: Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(value, 0),
                child: Opacity(
                  opacity: (100 - value) / 100,
                  child: Column(
                    children: [
                      // Primary download button - Google Play
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final url =
                                'https://play.google.com/store/apps/details?id=xyz.mmkcode.humanbenchmark.human_benchmark';
                            html.window.open(url, '_blank');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WebTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTiny ? 24 : 32,
                              vertical: isTiny ? 16 : 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: WebTheme.primaryBlue.withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google.png',
                                height: isTiny ? 16 : 18,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Get it on Google Play',
                                style: WebTheme.bodyLarge.copyWith(
                                  fontSize: isTiny ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isTiny ? 16 : 20),

                      // Web version button (if enabled)
                      StreamBuilder<WebSettings>(
                        stream: WebSettingsService.getWebSettingsStream(),
                        builder: (context, snapshot) {
                          final webSettings =
                              snapshot.data ?? WebSettings.defaultSettings;

                          if (!webSettings.webGameEnabled) {
                            return SizedBox.shrink();
                          }

                          return Container(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: widget.onStartApp,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: WebTheme.primaryBlue,
                                side: BorderSide(
                                  color: WebTheme.primaryBlue,
                                  width: 2,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTiny ? 24 : 32,
                                  vertical: isTiny ? 16 : 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_circle_outline,
                                    size: isTiny ? 18 : 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Use Web Version',
                                    style: WebTheme.bodyLarge.copyWith(
                                      fontSize: isTiny ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopDownloadLayout(bool isTiny, bool isMobile) {
    return Row(
      children: [
        // Left side - Text content sliding from left
        Expanded(
          flex: 1,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -100.0, end: 0.0),
            duration: Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(value, 0),
                child: Opacity(
                  opacity: (100 + value) / 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              WebTheme.primaryBlue.withOpacity(0.2),
                              WebTheme.primaryBlue.withOpacity(0.05),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: WebTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.psychology,
                            size: 40,
                            color: WebTheme.primaryBlue,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            WebTheme.primaryBlue,
                            WebTheme.primaryBlueLight,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Download Now',
                          style: WebTheme.headingLarge.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Subtitle
                      Text(
                        'Free to play • Track progress • Compete globally',
                        style: WebTheme.bodyLarge.copyWith(
                          fontSize: 18,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Features
                      Text(
                        'Cross-platform sync • Offline mode • Detailed analytics',
                        style: WebTheme.bodyMedium.copyWith(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 32),

                      // Buttons - only Google Play and Web Version
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              final url =
                                  'https://play.google.com/store/apps/details?id=xyz.mmkcode.humanbenchmark.human_benchmark';
                              html.window.open(url, '_blank');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WebTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                              shadowColor: WebTheme.primaryBlue.withOpacity(
                                0.3,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/google.png',
                                  height: 18,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Get it on Google Play',
                                  style: WebTheme.bodyLarge.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StreamBuilder<WebSettings>(
                            stream: WebSettingsService.getWebSettingsStream(),
                            builder: (context, snapshot) {
                              final webSettings =
                                  snapshot.data ?? WebSettings.defaultSettings;

                              if (!webSettings.webGameEnabled) {
                                return SizedBox.shrink();
                              }

                              return OutlinedButton(
                                onPressed: widget.onStartApp,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: WebTheme.primaryBlue,
                                  side: BorderSide(
                                    color: WebTheme.primaryBlue,
                                    width: 2,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_circle_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Use Web Version',
                                      style: WebTheme.bodyLarge.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(width: 40),

        // Right side - Phone mockup sliding from right
        Expanded(
          flex: 1,
          child: _buildDelayedAnimation(
            delay: Duration(milliseconds: 300),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 100.0, end: 0.0),
              duration: Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(value, 0),
                  child: Opacity(
                    opacity: (100 - value) / 100,
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 400,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              offset: Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(
                            children: [
                              // Phone screen content
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      WebTheme.primaryBlue.withOpacity(0.1),
                                      WebTheme.primaryBlue.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.psychology,
                                      size: 60,
                                      color: WebTheme.primaryBlue,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Human Benchmark',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: WebTheme.primaryBlue,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Test Your Brain',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Phone bezel
                              Positioned(
                                top: 20,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 4,
                                  margin: EdgeInsets.symmetric(horizontal: 60),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDelayedAnimation({
    required Duration delay,
    required Widget child,
  }) {
    return FutureBuilder<void>(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return child;
        }
        return SizedBox.shrink();
      },
    );
  }
}
