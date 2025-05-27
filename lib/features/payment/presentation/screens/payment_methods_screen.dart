import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAddPaymentMethod(context),
          const SizedBox(height: 24),
          _buildSavedPaymentMethods(context),
        ],
      ),
    );
  }

  Widget _buildAddPaymentMethod(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.add),
        ),
        title: const Text('Add Payment Method'),
        subtitle: const Text('Add a new credit card or payment method'),
        onTap: () {
          // TODO: Implement add payment method
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add payment method coming soon')),
          );
        },
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildSavedPaymentMethods(BuildContext context) {
    // Mock data for saved payment methods
    final paymentMethods = [
      {
        'type': 'Credit Card',
        'last4': '4242',
        'expiry': '12/24',
        'isDefault': true,
      },
      {
        'type': 'Credit Card',
        'last4': '1234',
        'expiry': '06/25',
        'isDefault': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saved Payment Methods',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...paymentMethods
            .map((method) => _buildPaymentMethodCard(context, method)),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
      BuildContext context, Map<String, dynamic> method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  method['type'] == 'Credit Card'
                      ? Icons.credit_card
                      : Icons.payment,
                  color: const Color(0xFF184C55),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${method['type']} ending in ${method['last4']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Expires ${method['expiry']}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (method['isDefault'])
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: Color(0xFF184C55),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  child: const Text('Remove'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // TODO: Implement edit payment method
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Edit payment method coming soon')),
                    );
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: const Text(
          'Are you sure you want to remove this payment method?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment method removed')),
              );
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
