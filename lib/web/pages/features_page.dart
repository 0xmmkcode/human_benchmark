import 'package:flutter/material.dart';
import 'package:human_benchmark/web/theme/web_theme.dart';

class FeaturesPage extends StatelessWidget {
  final VoidCallback? onBackToLanding;

  const FeaturesPage({Key? key, this.onBackToLanding}) : super(key: key);

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

                  // Core Features
                  _buildCoreFeatures(context),

                  // Game Modes
                  _buildGameModes(context),

                  // Advanced Features
                  _buildAdvancedFeatures(context),

                  // Platform Features
                  _buildPlatformFeatures(context),

                  // Coming Soon
                  _buildComingSoon(context),
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
            'Features',
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
            'Features',
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Discover all the powerful tools and features that make Human Benchmark the ultimate cognitive testing platform.',
            style: WebTheme.bodyLarge.copyWith(fontSize: 18, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCoreFeatures(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Core Features',
            style: WebTheme.headingLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          Row(
            children: [
              _buildFeatureCard(
                icon: Icons.timer,
                title: 'Reaction Time Testing',
                description:
                    'Precise measurement of your reflexes with randomized delays and instant feedback.',
                features: [
                  'Randomized delay intervals',
                  'Millisecond precision',
                  'Visual and audio cues',
                  'Immediate results display',
                ],
              ),
              SizedBox(width: 24),
              _buildFeatureCard(
                icon: Icons.leaderboard,
                title: 'Global Leaderboards',
                description:
                    'Compete with players worldwide and track your ranking across different categories.',
                features: [
                  'Real-time rankings',
                  'Category-based competition',
                  'Personal best tracking',
                  'Global statistics',
                ],
              ),
              SizedBox(width: 24),
              _buildFeatureCard(
                icon: Icons.analytics,
                title: 'Progress Analytics',
                description:
                    'Comprehensive tracking of your cognitive performance over time.',
                features: [
                  'Performance trends',
                  'Score history',
                  'Improvement metrics',
                  'Statistical insights',
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: WebTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: WebTheme.primaryBlue),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: WebTheme.headingMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(description, style: WebTheme.bodyLarge.copyWith(height: 1.5)),
            SizedBox(height: 20),
            ...features.map(
              (feature) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: WebTheme.primaryBlue,
                    ),
                    SizedBox(width: 8),
                    Expanded(child: Text(feature, style: WebTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModes(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Text(
            'Game Modes',
            style: WebTheme.headingLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildGameModeCard(
                        icon: Icons.flash_on,
                        title: 'Quick Test',
                        description:
                            'Fast 5-minute sessions for quick cognitive assessment.',
                        duration: '5 min',
                        difficulty: 'Easy',
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _buildGameModeCard(
                        icon: Icons.timer,
                        title: 'Standard Mode',
                        description:
                            'Comprehensive testing with detailed analytics.',
                        duration: '15 min',
                        difficulty: 'Medium',
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _buildGameModeCard(
                        icon: Icons.psychology,
                        title: 'Advanced Mode',
                        description:
                            'In-depth cognitive evaluation with multiple tests.',
                        duration: '30 min',
                        difficulty: 'Hard',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: _buildGameModeCard(
                        icon: Icons.trending_up,
                        title: 'Practice Mode',
                        description:
                            'Unlimited practice sessions to improve your skills.',
                        duration: 'Unlimited',
                        difficulty: 'Variable',
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _buildGameModeCard(
                        icon: Icons.emoji_events,
                        title: 'Challenge Mode',
                        description:
                            'Compete against your previous best scores.',
                        duration: '10 min',
                        difficulty: 'Dynamic',
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _buildGameModeCard(
                        icon: Icons.group,
                        title: 'Multiplayer',
                        description:
                            'Real-time competition with friends and other players.',
                        duration: '20 min',
                        difficulty: 'Competitive',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameModeCard({
    required IconData icon,
    required String title,
    required String description,
    required String duration,
    required String difficulty,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.grey200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: WebTheme.primaryBlue),
          SizedBox(height: 16),
          Text(
            title,
            style: WebTheme.headingMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            description,
            style: WebTheme.bodyMedium.copyWith(height: 1.4),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WebTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  duration,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.primaryBlue,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WebTheme.orange600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.orange600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFeatures(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Advanced Features',
            style: WebTheme.headingLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          Row(
            children: [
              _buildAdvancedFeatureCard(
                icon: Icons.sync,
                title: 'Cross-Platform Sync',
                description:
                    'Your progress and scores automatically sync across all devices.',
                status: 'Available',
                statusColor: WebTheme.green600,
              ),
              SizedBox(width: 24),
              _buildAdvancedFeatureCard(
                icon: Icons.security,
                title: 'Data Privacy',
                description:
                    'Your personal data is encrypted and never shared with third parties.',
                status: 'Available',
                statusColor: WebTheme.green600,
              ),
              SizedBox(width: 24),
              _buildAdvancedFeatureCard(
                icon: Icons.cloud_download,
                title: 'Offline Mode',
                description:
                    'Play without internet connection with basic features.',
                status: 'Available',
                statusColor: WebTheme.green600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required String status,
    required Color statusColor,
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
            Icon(icon, size: 40, color: WebTheme.primaryBlue),
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
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformFeatures(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Text(
            'Platform Features',
            style: WebTheme.headingLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          Row(
            children: [
              _buildPlatformCard(
                icon: Icons.phone_android,
                title: 'Mobile App',
                features: [
                  'Native Android performance',
                  'Touch-optimized interface',
                  'Background sync',
                  'Push notifications',
                ],
                status: 'Available',
                statusColor: WebTheme.green600,
              ),
              SizedBox(width: 24),
              _buildPlatformCard(
                icon: Icons.computer,
                title: 'Web App',
                features: [
                  'Cross-browser compatibility',
                  'Responsive design',
                  'No installation required',
                  'Instant access',
                ],
                status: 'Available',
                statusColor: WebTheme.green600,
              ),
              SizedBox(width: 24),
              _buildPlatformCard(
                icon: Icons.tablet_android,
                title: 'Tablet Support',
                features: [
                  'Optimized layouts',
                  'Touch gestures',
                  'Large screen experience',
                  'Landscape mode',
                ],
                status: 'Available',
                statusColor: WebTheme.green600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard({
    required IconData icon,
    required String title,
    required List<String> features,
    required String status,
    required Color statusColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: WebTheme.primaryBlue),
            SizedBox(height: 24),
            Text(
              title,
              style: WebTheme.headingMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ...features.map(
              (feature) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: WebTheme.primaryBlue,
                    ),
                    SizedBox(width: 8),
                    Expanded(child: Text(feature, style: WebTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoon(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Coming Soon',
            style: WebTheme.headingLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text(
            'Exciting new features we\'re working on',
            style: WebTheme.bodyLarge.copyWith(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          Row(
            children: [
              _buildComingSoonCard(
                icon: Icons.memory,
                title: 'Memory Tests',
                description: 'Advanced memory and recall testing modules.',
                eta: 'Q2 2024',
              ),
              SizedBox(width: 24),
              _buildComingSoonCard(
                icon: Icons.speed,
                title: 'Speed Tests',
                description: 'Reaction time and speed-based cognitive tests.',
                eta: 'Q3 2024',
              ),
              SizedBox(width: 24),
              _buildComingSoonCard(
                icon: Icons.psychology,
                title: 'IQ Tests',
                description: 'Comprehensive intelligence quotient testing.',
                eta: 'Q4 2024',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard({
    required IconData icon,
    required String title,
    required String description,
    required String eta,
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
            Icon(icon, size: 40, color: WebTheme.orange600),
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
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: WebTheme.orange600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                eta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: WebTheme.orange600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
