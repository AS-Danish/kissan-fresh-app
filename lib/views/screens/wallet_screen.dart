import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Map<String, dynamic>> _wallet;

  @override
  void initState() {
    super.initState();
    _wallet = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final result = await FirebaseFunctions.instance.httpsCallable('getDebugWallet').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  String money(dynamic paise) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 2,
      ).format(((paise as num?) ?? 0) / 100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kissan Fresh Wallet')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _wallet,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load wallet: ${snapshot.error}', textAlign: TextAlign.center),
            ));
          }
          final data = snapshot.data ?? const {};
          final entries = (data['entries'] as List? ?? const [])
              .map((entry) => Map<String, dynamic>.from(entry as Map))
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              final next = _load();
              setState(() => _wallet = next);
              await next;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Available balance'),
                      const SizedBox(height: 8),
                      Text(money(data['balancePaise']),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Can be applied automatically at checkout to pay for your orders.'),
                      const SizedBox(height: 4),
                      const Text(
                        'To transfer wallet balance back to your original bank account, contact Kissan Fresh support.',
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Activity', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (entries.isEmpty) const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No wallet activity yet.')),
                ),
                ...entries.map((entry) {
                  final String type = entry['type'] ?? '';
                  final num amt = (entry['amountPaise'] as num? ?? 0);
                  final bool isCredit = amt >= 0;
                  final bool isBankRefund = type == 'BANK_REFUND_DEBIT';

                  IconData iconData;
                  Color iconColor;
                  String title;
                  String subtitle;

                  if (isBankRefund) {
                    iconData = Icons.account_balance_rounded;
                    iconColor = Colors.deepOrange;
                    title = 'Refunded to Bank (Razorpay)';
                    subtitle = entry['providerRefundId'] != null
                        ? 'Ref: ${entry['providerRefundId']}'
                        : 'Order ${entry['orderId'] ?? '—'}';
                  } else if (type == 'REFUND_CREDIT') {
                    iconData = Icons.add_circle_outline_rounded;
                    iconColor = Colors.green;
                    title = 'Refund credit to wallet';
                    subtitle = 'Order ${entry['orderId'] ?? '—'}';
                  } else {
                    iconData = Icons.shopping_bag_outlined;
                    iconColor = Colors.indigo;
                    title = 'Used on order';
                    subtitle = 'Order ${entry['orderId'] ?? '—'}';
                  }

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withValues(alpha: 0.12),
                      child: Icon(iconData, color: iconColor),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(subtitle),
                    trailing: Text(
                      '${isCredit ? '+' : ''}${money(amt)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isCredit
                            ? Colors.green.shade700
                            : (isBankRefund ? Colors.deepOrange.shade700 : null),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
