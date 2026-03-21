import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Privacy Matters',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Last Updated: March 22, 2026',
              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 25),
            _buildSection(
              context,
              '1. Information We Collect',
              'We collect information you provide directly to us (name, email, phone number, address) and information about your usage of the app to provide and improve our services.',
            ),
            _buildSection(
              context,
              '2. How We Use Information',
              'Your data is used to process orders, manage accounts, and communicate with you about promotions or services that may interest you.',
            ),
            _buildSection(
              context,
              '3. Data Security',
              'We implement industry-standard security measures to protect your personal information from unauthorized access, disclosure, or destruction.',
            ),
            _buildSection(
              context,
              '4. Shared Information',
              'We do not sell your personal data. We only share information with third-party partners essential for delivering our services (like delivery partners).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
