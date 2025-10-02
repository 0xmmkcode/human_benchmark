import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../components/web_sidebar.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static void _onIndexChanged(int index) {
    // No-op for static privacy policy page
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 900;
    final bool isMobile = width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          if (!isSmall)
            const WebSidebar(selectedIndex: 0, onIndexChanged: _onIndexChanged),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isSmall ? double.infinity : 800,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const Gap(32),
                    _buildIntroduction(),
                    const Gap(24),
                    _buildDataCollection(),
                    const Gap(24),
                    _buildDataUsage(),
                    const Gap(24),
                    _buildDataSharing(),
                    const Gap(24),
                    _buildDataSecurity(),
                    const Gap(24),
                    _buildUserRights(),
                    const Gap(24),
                    _buildCookies(),
                    const Gap(24),
                    _buildThirdPartyServices(),
                    const Gap(24),
                    _buildDataRetention(),
                    const Gap(24),
                    _buildChildrenPrivacy(),
                    const Gap(24),
                    _buildChanges(),
                    const Gap(24),
                    _buildContact(),
                    const Gap(32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.privacy_tip, size: 64, color: Colors.white),
          const Gap(16),
          Text(
            'Privacy Policy',
            style: GoogleFonts.montserrat(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(8),
          Text(
            'Last updated: January 2025',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIntroduction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Introduction',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Text(
            'At Human Benchmark, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our cognitive assessment platform.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const Gap(12),
          Text(
            'By using our services, you agree to the collection and use of information in accordance with this policy. We will not use or share your information with anyone except as described in this Privacy Policy.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCollection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information We Collect',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          _buildInfoSection(
            'Personal Information',
            'When you create an account or use our services, we may collect:',
            [
              'Email address (for account creation and communication)',
              'Display name or username',
              'Profile information you choose to provide',
              'Authentication data from third-party providers (Google)',
            ],
          ),
          const Gap(16),
          _buildInfoSection(
            'Test Results and Performance Data',
            'We collect data related to your cognitive assessments:',
            [
              'Test scores and performance metrics',
              'Response times and accuracy rates',
              'Test completion history',
              'Progress tracking data',
              'Anonymous usage patterns for research purposes',
            ],
          ),
          const Gap(16),
          _buildInfoSection(
            'Technical Information',
            'We automatically collect certain technical information:',
            [
              'Device information (type, operating system, browser)',
              'IP address and general location data',
              'Usage logs and analytics data',
              'Cookies and similar tracking technologies',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataUsage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How We Use Your Information',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Text(
            'We use the collected information for the following purposes:',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const Gap(12),
          _buildUsageItem(
            'Service Provision',
            'To provide, maintain, and improve our cognitive assessment services',
            Icons.psychology,
            Colors.blue,
          ),
          _buildUsageItem(
            'Personalization',
            'To personalize your experience and provide relevant content',
            Icons.person,
            Colors.green,
          ),
          _buildUsageItem(
            'Research and Development',
            'To conduct anonymous research and improve our platform',
            Icons.science,
            Colors.orange,
          ),
          _buildUsageItem(
            'Communication',
            'To send important updates, notifications, and support messages',
            Icons.email,
            Colors.purple,
          ),
          _buildUsageItem(
            'Analytics',
            'To analyze usage patterns and optimize platform performance',
            Icons.analytics,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSharing() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information Sharing and Disclosure',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Text(
            'We do not sell, trade, or otherwise transfer your personal information to third parties, except in the following circumstances:',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const Gap(12),
          _buildSharingItem(
            'Service Providers',
            'We may share information with trusted third-party service providers who assist us in operating our platform, conducting business, or serving users.',
            Icons.business,
            Colors.blue,
          ),
          _buildSharingItem(
            'Legal Requirements',
            'We may disclose information when required by law or to protect our rights, property, or safety, or that of our users.',
            Icons.gavel,
            Colors.red,
          ),
          _buildSharingItem(
            'Research Partners',
            'We may share anonymized, aggregated data with research institutions for scientific purposes.',
            Icons.school,
            Colors.green,
          ),
          _buildSharingItem(
            'Business Transfers',
            'In the event of a merger, acquisition, or sale of assets, user information may be transferred as part of the transaction.',
            Icons.business_center,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSecurity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Security',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Text(
            'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. These measures include:',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const Gap(12),
          _buildSecurityItem('Encryption of data in transit and at rest'),
          _buildSecurityItem('Regular security audits and assessments'),
          _buildSecurityItem('Access controls and authentication systems'),
          _buildSecurityItem('Secure data centers and infrastructure'),
          _buildSecurityItem('Employee training on data protection'),
          const Gap(12),
          Text(
            'However, no method of transmission over the internet or electronic storage is 100% secure. While we strive to protect your personal information, we cannot guarantee absolute security.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.orange[700],
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRights() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Rights and Choices',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Text(
            'You have certain rights regarding your personal information:',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const Gap(12),
          _buildRightItem(
            'Access',
            'Request access to your personal information and test results',
            Icons.visibility,
            Colors.blue,
          ),
          _buildRightItem(
            'Correction',
            'Request correction of inaccurate or incomplete information',
            Icons.edit,
            Colors.green,
          ),
          _buildRightItem(
            'Deletion',
            'Request deletion of your personal information',
            Icons.delete,
            Colors.red,
          ),
          _buildRightItem(
            'Portability',
            'Request a copy of your data in a portable format',
            Icons.download,
            Colors.orange,
          ),
          _buildRightItem(
            'Opt-out',
            'Opt out of certain data processing activities',
            Icons.block,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCookies() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cookies and Tracking Technologies',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Text(
            'We use cookies and similar tracking technologies to enhance your experience and analyze platform usage. These technologies help us:',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const Gap(12),
          _buildCookieItem('Remember your preferences and settings'),
          _buildCookieItem('Analyze how you use our platform'),
          _buildCookieItem('Provide personalized content and recommendations'),
          _buildCookieItem('Improve platform performance and functionality'),
          const Gap(12),
          Text(
            'You can control cookie settings through your browser preferences. However, disabling certain cookies may affect platform functionality.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPartyServices() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Third-Party Services',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Text(
            'Our platform integrates with third-party services that may collect information:',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const Gap(12),
          _buildThirdPartyItem(
            'Google Services',
            'Authentication, analytics, and advertising services',
            Icons.login,
            Colors.blue,
          ),
          _buildThirdPartyItem(
            'Firebase',
            'Backend services, database, and user management',
            Icons.cloud,
            Colors.orange,
          ),
          _buildThirdPartyItem(
            'Analytics Providers',
            'Usage tracking and performance monitoring',
            Icons.analytics,
            Colors.green,
          ),
          const Gap(12),
          Text(
            'These third-party services have their own privacy policies. We encourage you to review their policies to understand how they handle your information.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRetention() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Retention',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Text(
            'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this Privacy Policy. Specifically:',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const Gap(12),
          _buildRetentionItem('Account information: Until account deletion'),
          _buildRetentionItem(
            'Test results: Up to 3 years for research purposes',
          ),
          _buildRetentionItem('Usage data: Up to 2 years for analytics'),
          _buildRetentionItem('Communication records: Up to 1 year'),
          const Gap(12),
          Text(
            'We may retain certain information longer if required by law or for legitimate business purposes.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenPrivacy() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Children\'s Privacy',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Text(
            'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const Gap(12),
          Text(
            'If we discover that we have collected personal information from a child under 13, we will take steps to delete such information promptly.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.orange[700],
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChanges() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Changes to This Privacy Policy',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Gap(16),
          Text(
            'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date. We encourage you to review this Privacy Policy periodically for any changes.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const Gap(12),
          Text(
            'Changes to this Privacy Policy are effective when they are posted on this page. Your continued use of our services after any changes constitutes acceptance of the updated Privacy Policy.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContact() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Us',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const Gap(16),
          Text(
            'If you have any questions about this Privacy Policy or our data practices, please contact us:',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.blue.shade700,
              height: 1.6,
            ),
          ),
          const Gap(12),
          _buildContactItem('Email: privacy@humanbenchmark.com'),
          _buildContactItem('Website: humanbenchmark.com/contact'),
          _buildContactItem('Address: [Your Business Address]'),
          const Gap(16),
          Text(
            'We will respond to your inquiry within 30 days of receipt.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.blue.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    String description,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const Gap(8),
        Text(
          description,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        const Gap(8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Gap(4),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
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

  Widget _buildSharingItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Gap(4),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
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

  Widget _buildSecurityItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Gap(4),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
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

  Widget _buildCookieItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPartyItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Gap(4),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
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

  Widget _buildRetentionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.blue.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
