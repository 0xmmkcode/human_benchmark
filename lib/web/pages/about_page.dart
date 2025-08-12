import 'package:flutter/material.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';
import 'package:human_benchmark/web/constants/web_constants.dart';
import 'dart:html' as html;

class AboutPage extends StatelessWidget {
  final VoidCallback? onBackToLanding;

  const AboutPage({
    Key? key,
    this.onBackToLanding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  _buildHeader(context),
                  
                  // Mission Section
                  _buildMissionSection(context),
                  
                  // Team Section
                  _buildTeamSection(context),
                  
                  // Technology Section
                  _buildTechnologySection(context),
                  
                  // Contact Section
                  _buildContactSection(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Text(
            'About Human Benchmark',
            style: WebTheme.headingLarge.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text(
            'Discover the science behind cognitive testing and how we\'re helping people understand their mental capabilities.',
            style: WebTheme.bodyLarge.copyWith(
              fontSize: 18,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Our Mission',
            style: WebTheme.headingLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: WebTheme.grey50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 60,
                        color: WebTheme.primaryBlue,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Advancing Cognitive Science',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'We believe that understanding our cognitive abilities is the first step to improving them. Our platform provides scientifically-validated tests that help users measure and track their mental performance.',
                        style: WebTheme.bodyLarge.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: WebTheme.grey50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.accessibility_new,
                        size: 60,
                        color: WebTheme.primaryBlue,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Accessible to Everyone',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cognitive testing shouldn\'t be limited to research labs. We\'ve made these valuable tools available to everyone through intuitive, engaging, and scientifically-accurate applications.',
                        style: WebTheme.bodyLarge.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Text(
            'Meet the Team',
            style: WebTheme.headingLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text(
            'The minds behind Human Benchmark',
            style: WebTheme.bodyLarge.copyWith(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: WebTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: WebTheme.primaryBlue,
                  ),
                ),
                SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MMKode Team',
                        style: WebTheme.headingMedium.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'A passionate team of developers, designers, and cognitive science enthusiasts dedicated to creating tools that help people understand and improve their mental capabilities.',
                        style: WebTheme.bodyLarge.copyWith(height: 1.6),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Based in Morocco, we\'re committed to making cognitive testing accessible to people worldwide through innovative technology and user-centered design.',
                        style: WebTheme.bodyLarge.copyWith(height: 1.6),
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

  Widget _buildTechnologySection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Technology & Science',
            style: WebTheme.headingLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          Row(
            children: [
              _buildTechCard(
                icon: Icons.flutter_dash,
                title: 'Flutter Framework',
                description: 'Built with Flutter for cross-platform compatibility and smooth performance across all devices.',
              ),
              SizedBox(width: 24),
              _buildTechCard(
                icon: Icons.science,
                title: 'Scientific Validation',
                description: 'Our tests are based on established cognitive science research and validated methodologies.',
              ),
              SizedBox(width: 24),
              _buildTechCard(
                icon: Icons.cloud,
                title: 'Cloud Integration',
                description: 'Firebase-powered backend ensures data security and cross-device synchronization.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: WebTheme.grey50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WebTheme.grey200),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: WebTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 40,
                color: WebTheme.primaryBlue,
              ),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: WebTheme.headingMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              description,
              style: WebTheme.bodyLarge.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Text(
            'Get in Touch',
            style: WebTheme.headingLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text(
            'Have questions or suggestions? We\'d love to hear from you.',
            style: WebTheme.bodyLarge.copyWith(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactItem(
                  icon: Icons.email,
                  title: 'Email',
                  value: 'mmkcode.business@gmail.com',
                  onTap: () {
                    final url = 'mailto:mmkcode.business@gmail.com';
                    html.window.open(url, '_blank');
                  },
                ),
                _buildContactItem(
                  icon: Icons.web,
                  title: 'Website',
                  value: 'mmkcode.com',
                  onTap: () {
                    final url = 'https://mmkcode.com';
                    html.window.open(url, '_blank');
                  },
                ),
                _buildContactItem(
                  icon: Icons.location_on,
                  title: 'Location',
                  value: 'Casablanca, Morocco',
                  onTap: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: onTap != null ? WebTheme.grey50 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: WebTheme.primaryBlue,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: WebTheme.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: WebTheme.bodyLarge.copyWith(
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
