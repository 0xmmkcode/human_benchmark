import 'package:flutter/material.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/widgets/page_header.dart';
import 'dart:html' as html;

class AboutPage extends StatelessWidget {
  final VoidCallback? onBackToLanding;

  const AboutPage({Key? key, this.onBackToLanding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: WebTheme.grey50,
      body: Column(
        children: [
          // Navigation Header
          if (onBackToLanding != null) _buildNavigationHeader(context),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16.0 : (isTablet ? 24.0 : 32.0),
                      vertical: isMobile ? 40.0 : (isTablet ? 60.0 : 80.0),
                    ),
                    child: PageHeader(
                      title: 'About',
                      subtitle:
                          'Learn about our mission and the science behind cognitive testing.',
                      showBackButton: false,
                    ),
                  ),

                  // Mission Section
                  _buildMissionSection(context, isMobile, isTablet),

                  // Team Section
                  _buildTeamSection(context, isMobile, isTablet),

                  // Technology Section
                  _buildTechnologySection(context, isMobile, isTablet),

                  // Contact Section
                  _buildContactSection(context, isMobile, isTablet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackToLanding,
            icon: Icon(Icons.arrow_back, color: Colors.grey[600]),
            tooltip: 'Back to Landing Page',
          ),
          SizedBox(width: 16),
          Text(
            'About',
            style: WebTheme.headingMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final verticalPadding = isMobile ? 40.0 : (isTablet ? 60.0 : 80.0);
    final titleSize = isMobile ? 28.0 : (isTablet ? 32.0 : 36.0);
    final cardPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final iconSize = isMobile ? 40.0 : (isTablet ? 50.0 : 60.0);
    final cardTitleSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
    final textSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final gapBetweenCards = isMobile ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Our Mission',
            style: WebTheme.headingLarge.copyWith(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 30 : (isTablet ? 40 : 60)),
          isMobile
              ? Column(
                  children: [
                    _buildMissionCard(
                      Icons.psychology,
                      'Advancing Cognitive Science',
                      'We believe that understanding our cognitive abilities is the first step to improving them. Our platform provides scientifically-validated tests that help users measure and track their mental performance.',
                      cardPadding,
                      iconSize,
                      cardTitleSize,
                      textSize,
                    ),
                    SizedBox(height: gapBetweenCards),
                    _buildMissionCard(
                      Icons.accessibility_new,
                      'Accessible to Everyone',
                      'Cognitive testing shouldn\'t be limited to research labs. We\'ve made these valuable tools available to everyone through intuitive, engaging, and scientifically-accurate applications.',
                      cardPadding,
                      iconSize,
                      cardTitleSize,
                      textSize,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildMissionCard(
                        Icons.psychology,
                        'Advancing Cognitive Science',
                        'We believe that understanding our cognitive abilities is the first step to improving them. Our platform provides scientifically-validated tests that help users measure and track their mental performance.',
                        cardPadding,
                        iconSize,
                        cardTitleSize,
                        textSize,
                      ),
                    ),
                    SizedBox(width: gapBetweenCards),
                    Expanded(
                      child: _buildMissionCard(
                        Icons.accessibility_new,
                        'Accessible to Everyone',
                        'Cognitive testing shouldn\'t be limited to research labs. We\'ve made these valuable tools available to everyone through intuitive, engaging, and scientifically-accurate applications.',
                        cardPadding,
                        iconSize,
                        cardTitleSize,
                        textSize,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(
    IconData icon,
    String title,
    String description,
    double padding,
    double iconSize,
    double titleSize,
    double textSize,
  ) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: iconSize, color: WebTheme.primaryBlue),
          SizedBox(height: padding * 0.75),
          Text(
            title,
            style: WebTheme.headingMedium.copyWith(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: padding * 0.5),
          Text(
            description,
            style: WebTheme.bodyLarge.copyWith(fontSize: textSize, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context, bool isMobile, bool isTablet) {
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final verticalPadding = isMobile ? 40.0 : (isTablet ? 60.0 : 80.0);
    final titleSize = isMobile ? 28.0 : (isTablet ? 32.0 : 36.0);
    final subtitleSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final cardPadding = isMobile ? 20.0 : (isTablet ? 30.0 : 40.0);
    final avatarSize = isMobile ? 80.0 : (isTablet ? 100.0 : 120.0);
    final avatarIconSize = isMobile ? 40.0 : (isTablet ? 50.0 : 60.0);
    final teamNameSize = isMobile ? 20.0 : (isTablet ? 24.0 : 28.0);
    final textSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        children: [
          Text(
            'Meet the Team',
            style: WebTheme.headingLarge.copyWith(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Text(
            'The minds behind Human Benchmark',
            style: WebTheme.bodyLarge.copyWith(
              fontSize: subtitleSize,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 30 : (isTablet ? 40 : 60)),
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: isMobile ? 12 : 16,
                  offset: Offset(0, isMobile ? 6 : 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: isMobile
                ? Column(
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: WebTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(avatarSize / 2),
                        ),
                        child: Icon(
                          Icons.person,
                          size: avatarIconSize,
                          color: WebTheme.primaryBlue,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'MMKode Team',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: teamNameSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'A passionate team of developers, designers, and cognitive science enthusiasts dedicated to creating tools that help people understand and improve their mental capabilities.',
                        style: WebTheme.bodyLarge.copyWith(
                          fontSize: textSize,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'We\'re committed to making cognitive testing accessible to people worldwide through innovative technology and user-centered design.',
                        style: WebTheme.bodyLarge.copyWith(
                          fontSize: textSize,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: WebTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(avatarSize / 2),
                        ),
                        child: Icon(
                          Icons.person,
                          size: avatarIconSize,
                          color: WebTheme.primaryBlue,
                        ),
                      ),
                      SizedBox(width: isTablet ? 24 : 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MMKode Team',
                              style: WebTheme.headingMedium.copyWith(
                                fontSize: teamNameSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'A passionate team of developers, designers, and cognitive science enthusiasts dedicated to creating tools that help people understand and improve their mental capabilities.',
                              style: WebTheme.bodyLarge.copyWith(
                                fontSize: textSize,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'We\'re committed to making cognitive testing accessible to people worldwide through innovative technology and user-centered design.',
                              style: WebTheme.bodyLarge.copyWith(
                                fontSize: textSize,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnologySection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final verticalPadding = isMobile ? 40.0 : (isTablet ? 60.0 : 80.0);
    final titleSize = isMobile ? 28.0 : (isTablet ? 32.0 : 36.0);
    final gapBetweenCards = isMobile ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Technology & Science',
            style: WebTheme.headingLarge.copyWith(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 30 : (isTablet ? 40 : 60)),
          isMobile
              ? Column(
                  children: [
                    _buildTechCard(
                      context: context,
                      icon: Icons.flutter_dash,
                      title: 'Flutter Framework',
                      description:
                          'Built with Flutter for cross-platform compatibility and smooth performance across all devices.',
                    ),
                    SizedBox(height: gapBetweenCards),
                    _buildTechCard(
                      context: context,
                      icon: Icons.science,
                      title: 'Scientific Validation',
                      description:
                          'Our tests are based on established cognitive science research and validated methodologies.',
                    ),
                    SizedBox(height: gapBetweenCards),
                    _buildTechCard(
                      context: context,
                      icon: Icons.cloud,
                      title: 'Cloud Integration',
                      description:
                          'Firebase-powered backend ensures data security and cross-device synchronization.',
                    ),
                  ],
                )
              : isTablet
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTechCard(
                            context: context,
                            icon: Icons.flutter_dash,
                            title: 'Flutter Framework',
                            description:
                                'Built with Flutter for cross-platform compatibility and smooth performance across all devices.',
                          ),
                        ),
                        SizedBox(width: gapBetweenCards),
                        Expanded(
                          child: _buildTechCard(
                            context: context,
                            icon: Icons.science,
                            title: 'Scientific Validation',
                            description:
                                'Our tests are based on established cognitive science research and validated methodologies.',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: gapBetweenCards),
                    _buildTechCard(
                      context: context,
                      icon: Icons.cloud,
                      title: 'Cloud Integration',
                      description:
                          'Firebase-powered backend ensures data security and cross-device synchronization.',
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildTechCard(
                      context: context,
                      icon: Icons.flutter_dash,
                      title: 'Flutter Framework',
                      description:
                          'Built with Flutter for cross-platform compatibility and smooth performance across all devices.',
                    ),
                    SizedBox(width: gapBetweenCards),
                    _buildTechCard(
                      context: context,
                      icon: Icons.science,
                      title: 'Scientific Validation',
                      description:
                          'Our tests are based on established cognitive science research and validated methodologies.',
                    ),
                    SizedBox(width: gapBetweenCards),
                    _buildTechCard(
                      context: context,
                      icon: Icons.cloud,
                      title: 'Cloud Integration',
                      description:
                          'Firebase-powered backend ensures data security and cross-device synchronization.',
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildTechCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    final padding = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
    final iconContainerSize = isMobile ? 60.0 : (isTablet ? 70.0 : 80.0);
    final iconSize = isMobile ? 30.0 : (isTablet ? 35.0 : 40.0);
    final titleSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final textSize = isMobile ? 13.0 : (isTablet ? 14.0 : 15.0);
    final borderRadius = isMobile ? 12.0 : 16.0;

    return isMobile
        ? Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: WebTheme.grey50,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: WebTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      iconContainerSize * 0.25,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: WebTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  title,
                  style: WebTheme.headingMedium.copyWith(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  description,
                  style: WebTheme.bodyLarge.copyWith(
                    fontSize: textSize,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : Expanded(
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: WebTheme.grey50,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: WebTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        iconContainerSize * 0.25,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: WebTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    title,
                    style: WebTheme.headingMedium.copyWith(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    description,
                    style: WebTheme.bodyLarge.copyWith(
                      fontSize: textSize,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildContactSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final verticalPadding = isMobile ? 40.0 : (isTablet ? 60.0 : 80.0);
    final titleSize = isMobile ? 28.0 : (isTablet ? 32.0 : 36.0);
    final subtitleSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final cardPadding = isMobile ? 20.0 : (isTablet ? 30.0 : 40.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        children: [
          Text(
            'Get in Touch',
            style: WebTheme.headingLarge.copyWith(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Text(
            'Have questions or suggestions? We\'d love to hear from you.',
            style: WebTheme.bodyLarge.copyWith(
              fontSize: subtitleSize,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 30 : (isTablet ? 40 : 60)),
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: isMobile ? 12 : 16,
                  offset: Offset(0, isMobile ? 6 : 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: isMobile
                ? Column(
                    children: [
                      _buildContactItem(
                        context: context,
                        icon: Icons.email,
                        title: 'Email',
                        value: 'admin@mmkcode.cloud',
                        onTap: () {
                          final url = 'mailto:admin@mmkcode.cloud';
                          html.window.open(url, '_blank');
                        },
                      ),
                      SizedBox(height: 16),
                      _buildContactItem(
                        context: context,
                        icon: Icons.web,
                        title: 'Website',
                        value: 'humanbenchmark.xyz',
                        onTap: () {
                          final url = 'https://humanbenchmark.xyz';
                          html.window.open(url, '_blank');
                        },
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContactItem(
                        context: context,
                        icon: Icons.email,
                        title: 'Email',
                        value: 'admin@mmkcode.cloud',
                        onTap: () {
                          final url = 'mailto:admin@mmkcode.cloud';
                          html.window.open(url, '_blank');
                        },
                      ),
                      _buildContactItem(
                        context: context,
                        icon: Icons.web,
                        title: 'Website',
                        value: 'humanbenchmark.xyz',
                        onTap: () {
                          final url = 'https://humanbenchmark.xyz';
                          html.window.open(url, '_blank');
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final padding = isMobile ? 16.0 : 24.0;
    final iconSize = isMobile ? 30.0 : 40.0;
    final titleSize = isMobile ? 14.0 : 16.0;
    final valueSize = isMobile ? 12.0 : 14.0;
    final borderRadius = isMobile ? 12.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: onTap != null ? WebTheme.grey50 : Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: iconSize, color: WebTheme.primaryBlue),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              title,
              style: WebTheme.headingSmall.copyWith(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              value,
              style: WebTheme.bodyLarge.copyWith(
                fontSize: valueSize,
                color: onTap != null ? WebTheme.primaryBlue : Colors.grey[600],
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
