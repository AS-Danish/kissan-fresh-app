import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'question': 'What is Kissan Fresh?',
        'answer': 'Kissan Fresh is your ultimate platform for ordering fresh, high-quality groceries, vegetables, and daily essentials straight to your door.'
      },
      {
        'question': 'How do I track my order?',
        'answer': 'You can track your order by going to the "Orders" section in your profile. Tap on your active order to see its live status.'
      },
      {
        'question': 'What are your delivery hours?',
        'answer': 'We deliver from 7 AM to 10 PM everyday. You can also select a specific delivery slot at checkout.'
      },
      {
        'question': 'How can I return an item?',
        'answer': 'If you are not satisfied with a product, you can request a return or refund within 24 hours of delivery from the order details page.'
      },
      {
        'question': 'Do you charge for delivery?',
        'answer': 'Delivery is free for orders above ₹300! For orders below that amount, a nominal delivery fee of ₹30 applies.'
      },
      {
        'question': 'How do I apply a coupon code?',
        'answer': 'At checkout, before making the payment, you will see an "Apply Coupon" section where you can enter any valid promotional codes.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20.0),
        itemCount: faqs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  faq['question']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                iconColor: Theme.of(context).primaryColor,
                collapsedIconColor: Theme.of(context).primaryColor,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                    child: Text(
                      faq['answer']!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
