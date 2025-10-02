import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'About Human Benchmark',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey[800],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(context),
            const Gap(20),
            _buildMissionSection(context),
            const Gap(20),
            _buildCognitiveTestsSection(context),
            const Gap(20),
            _buildScientificBasisSection(context),
            const Gap(20),
            _buildBenefitsSection(context),
            const Gap(20),
            _buildResearchSection(context),
            const Gap(20),
            _buildPrivacySection(context),
            const Gap(20),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final iconSize = isMobile ? 48.0 : 64.0;
    final titleSize = isMobile ? 24.0 : 32.0;
    final subtitleSize = isMobile ? 14.0 : 18.0;
    final padding = isMobile ? 16.0 : 24.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: isMobile ? 12 : 20,
            offset: Offset(0, isMobile ? 6 : 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.psychology, size: iconSize, color: Colors.white),
          Gap(isMobile ? 12 : 16),
          Text(
            'Human Benchmark',
            style: GoogleFonts.montserrat(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(isMobile ? 6 : 8),
          Text(
            'Comprehensive Cognitive Assessment Platform',
            style: GoogleFonts.montserrat(
              fontSize: subtitleSize,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final titleSize = isMobile ? 20.0 : 24.0;
    final textSize = isMobile ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: isMobile ? 8 : 12,
            offset: Offset(0, isMobile ? 3 : 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.blue.shade600, size: iconSize),
              Gap(isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Our Mission',
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          Gap(isMobile ? 12 : 16),
          Text(
            'Human Benchmark is dedicated to providing accessible, scientifically-based cognitive assessments that help individuals understand and improve their mental capabilities. Our platform offers a comprehensive suite of tests designed to measure various aspects of cognitive function, from reaction time and memory to decision-making and personality traits.',
            style: GoogleFonts.montserrat(
              fontSize: textSize,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          Gap(isMobile ? 8 : 12),
          Text(
            'We believe that understanding your cognitive strengths and areas for improvement is the first step toward personal growth and enhanced mental performance.',
            style: GoogleFonts.montserrat(
              fontSize: textSize,
              color: Colors.grey[700],
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCognitiveTestsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final titleSize = isMobile ? 20.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: isMobile ? 8 : 12,
            offset: Offset(0, isMobile ? 3 : 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz, color: Colors.green.shade600, size: iconSize),
              Gap(isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Cognitive Tests Available',
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          Gap(isMobile ? 12 : 16),
          _buildTestItem(
            context,
            'Reaction Time Test',
            'Measures how quickly you can respond to visual stimuli. Essential for driving, sports, and daily decision-making.',
            Icons.timer,
            Colors.blue,
          ),
          Gap(isMobile ? 8 : 12),
          _buildTestItem(
            context,
            'Number Memory Test',
            'Evaluates working memory capacity by testing your ability to remember and recall number sequences.',
            Icons.memory,
            Colors.orange,
          ),
          Gap(isMobile ? 8 : 12),
          _buildTestItem(
            context,
            'Chimp Test',
            'Based on research showing chimpanzees can outperform humans in certain working memory tasks.',
            Icons.pets,
            Colors.amber,
          ),
          Gap(isMobile ? 8 : 12),
          _buildTestItem(
            context,
            'Personality Assessment',
            'Comprehensive Big Five personality test measuring openness, conscientiousness, extraversion, agreeableness, and neuroticism.',
            Icons.psychology,
            Colors.purple,
          ),
          Gap(isMobile ? 8 : 12),
          _buildTestItem(
            context,
            'Decision Making Test',
            'Evaluates risk assessment and decision-making patterns under various scenarios.',
            Icons.analytics,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTestItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 12.0 : 16.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final titleSize = isMobile ? 14.0 : 16.0;
    final descriptionSize = isMobile ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: iconSize),
          Gap(isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Gap(isMobile ? 2 : 4),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: descriptionSize,
                    color: color,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificBasisSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final titleSize = isMobile ? 20.0 : 24.0;
    final textSize = isMobile ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: isMobile ? 8 : 12,
            offset: Offset(0, isMobile ? 3 : 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: Colors.indigo.shade600,
                size: iconSize,
              ),
              Gap(isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Scientific Foundation',
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          Gap(isMobile ? 12 : 16),
          Text(
            'Our cognitive assessments are based on established psychological and neuroscientific research:',
            style: GoogleFonts.montserrat(
              fontSize: textSize,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          Gap(isMobile ? 8 : 12),
          _buildBulletPoint(
            context,
            'Reaction time tests are standardized measures used in clinical and research settings',
          ),
          _buildBulletPoint(
            context,
            'Working memory assessments follow validated protocols from cognitive psychology',
          ),
          _buildBulletPoint(
            context,
            'Personality tests are based on the widely-accepted Big Five model (OCEAN)',
          ),
          _buildBulletPoint(
            context,
            'Decision-making tests incorporate behavioral economics principles',
          ),
          _buildBulletPoint(
            context,
            'All tests are designed to be reliable, valid, and culturally appropriate',
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final textSize = isMobile ? 12.0 : 14.0;
    final dotSize = isMobile ? 4.0 : 6.0;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              top: isMobile ? 6 : 8,
              right: isMobile ? 8 : 12,
            ),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: Colors.indigo.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: textSize,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final titleSize = isMobile ? 20.0 : 24.0;
    final textSize = isMobile ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: isMobile ? 8 : 12,
            offset: Offset(0, isMobile ? 3 : 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.green.shade600,
                size: iconSize,
              ),
              Gap(isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Benefits of Cognitive Testing',
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          Gap(isMobile ? 12 : 16),
          Text(
            'Regular cognitive assessment and training can provide numerous benefits:',
            style: GoogleFonts.montserrat(
              fontSize: textSize,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          Gap(isMobile ? 8 : 12),
          _buildBenefitItem(
            context,
            'Enhanced Mental Performance',
            'Improved focus, memory, and processing speed',
          ),
          _buildBenefitItem(
            context,
            'Better Decision Making',
            'Sharper analytical skills and risk assessment',
          ),
          _buildBenefitItem(
            context,
            'Increased Self-Awareness',
            'Understanding your cognitive strengths and weaknesses',
          ),
          _buildBenefitItem(
            context,
            'Personal Development',
            'Targeted areas for improvement and growth',
          ),
          _buildBenefitItem(
            context,
            'Academic & Professional Success',
            'Better performance in learning and work environments',
          ),
          _buildBenefitItem(
            context,
            'Healthy Aging',
            'Maintaining cognitive function as you age',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    String title,
    String description,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 12.0 : 16.0;
    final iconSize = isMobile ? 16.0 : 20.0;
    final titleSize = isMobile ? 14.0 : 16.0;
    final descriptionSize = isMobile ? 12.0 : 14.0;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 6,
            offset: Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: iconSize,
          ),
          Gap(isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Gap(isMobile ? 2 : 4),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: descriptionSize,
                    color: Colors.green.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResearchSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final titleSize = isMobile ? 20.0 : 24.0;
    final textSize = isMobile ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: isMobile ? 8 : 12,
            offset: Offset(0, isMobile ? 3 : 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article, color: Colors.teal.shade600, size: iconSize),
              Gap(isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Research & Development',
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          Gap(isMobile ? 12 : 16),
          Text(
            'Our platform is continuously updated based on the latest research in cognitive science, psychology, and neuroscience. We collaborate with researchers and incorporate findings from peer-reviewed studies to ensure our assessments remain current and effective.',
            style: GoogleFonts.montserrat(
              fontSize: textSize,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          Gap(isMobile ? 8 : 12),
          Text(
            'Key research areas we follow include:',
            style: GoogleFonts.montserrat(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Gap(isMobile ? 6 : 8),
          _buildBulletPoint(context, 'Cognitive training and neuroplasticity'),
          _buildBulletPoint(
            context,
            'Individual differences in cognitive abilities',
          ),
          _buildBulletPoint(
            context,
            'Personality and cognitive performance relationships',
          ),
          _buildBulletPoint(
            context,
            'Age-related cognitive changes and interventions',
          ),
          _buildBulletPoint(
            context,
            'Technology-enhanced cognitive assessment',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final titleSize = isMobile ? 20.0 : 24.0;
    final textSize = isMobile ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: isMobile ? 8 : 12,
            offset: Offset(0, isMobile ? 3 : 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip,
                color: Colors.blue.shade600,
                size: iconSize,
              ),
              Gap(isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Privacy & Data Protection',
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          Gap(isMobile ? 12 : 16),
          Text(
            'We are committed to protecting your privacy and ensuring the security of your personal data. All test results and personal information are handled according to strict privacy standards and applicable data protection regulations.',
            style: GoogleFonts.montserrat(
              fontSize: textSize,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          Gap(isMobile ? 8 : 12),
          Text(
            'Your data is used solely for:',
            style: GoogleFonts.montserrat(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Gap(isMobile ? 6 : 8),
          _buildBulletPoint(
            context,
            'Providing personalized test results and insights',
          ),
          _buildBulletPoint(
            context,
            'Improving our platform and test accuracy',
          ),
          _buildBulletPoint(
            context,
            'Conducting anonymous research (with your consent)',
          ),
          _buildBulletPoint(
            context,
            'Never sold to third parties or used for advertising',
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final titleSize = isMobile ? 20.0 : 24.0;
    final textSize = isMobile ? 14.0 : 16.0;
    final thankYouSize = isMobile ? 16.0 : 18.0;
    final taglineSize = isMobile ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: isMobile ? 8 : 12,
            offset: Offset(0, isMobile ? 3 : 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_support,
                color: Colors.purple.shade600,
                size: iconSize,
              ),
              Gap(isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Contact & Support',
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          Gap(isMobile ? 12 : 16),
          Text(
            'We value your feedback and are here to help. If you have questions, suggestions, or need support, please don\'t hesitate to reach out.',
            style: GoogleFonts.montserrat(
              fontSize: textSize,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          Gap(isMobile ? 12 : 16),
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.08),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Thank you for using Human Benchmark!',
                  style: GoogleFonts.montserrat(
                    fontSize: thankYouSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                Gap(isMobile ? 6 : 8),
                Text(
                  'Together, we can unlock the potential of the human mind.',
                  style: GoogleFonts.montserrat(
                    fontSize: taglineSize,
                    color: Colors.purple.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
