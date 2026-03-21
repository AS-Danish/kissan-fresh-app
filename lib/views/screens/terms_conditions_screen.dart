import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
              'Standard Terms of Use',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'By using KissanFresh, you agree to these terms.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 25),
            _buildSection(
              context,
              '1. Acceptance',
              'By accessing or using the KissanFresh mobile application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
            ),
            _buildSection(
              context,
              '2. Account Responsibility',
              'You are responsible for maintaining the confidentiality of your account login information and are fully responsible for all activities that occur under your account.',
            ),
            _buildSection(
              context,
              '3. Product Availability',
              'While we strive for accuracy, products may occasionally be out of stock or have different packaging than shown. We reserve the right to limit quantities.',
            ),
             _buildSection(
              context,
              '4. Cancellation & Refunds',
              'Orders can be cancelled before preparation/dispatch. Refunds are processed according to our internal policy, usually within 5-7 business days.',
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
