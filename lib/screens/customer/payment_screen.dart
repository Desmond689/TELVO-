// lib/screens/customer/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/widgets/custom_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = '';
  final double _amount = 15000.0;

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod('Cash', Icons.money, 'Pay with cash'),
    PaymentMethod('MTN MoMo', Icons.phone_android, 'Pay with MTN Mobile Money'),
    PaymentMethod('Orange Money', Icons.phone_iphone, 'Pay with Orange Money'),
    PaymentMethod('Card Payment', Icons.credit_card, 'Pay with Credit Card'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payment')),
    body: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobCompleted(),
                const SizedBox(height: 24),
                const Text(
                  'How would you like to pay?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._paymentMethods.map((method) => _buildPaymentMethod(method)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: 'Pay XAF ${_amount.toStringAsFixed(0)}',
            onPressed: _selectedMethod.isEmpty ? null : _processPayment,
          ),
        ),
      ],
    ),
  );

  Widget _buildJobCompleted() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
        const SizedBox(width: 12),
        const Text(
          'Job Completed!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _buildPaymentMethod(PaymentMethod method) {
    final isSelected = _selectedMethod == method.name;
    final isComingSoon = method.name != 'Cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF00C853) : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          if (isComingSoon) {
            _showComingSoonDialog();
          } else {
            setState(() {
              _selectedMethod = method.name;
            });
          }
        },
        leading: Icon(
          method.icon,
          color: isSelected ? const Color(0xFF00C853) : Colors.grey,
          size: 28,
        ),
        title: Text(
          method.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(method.subtitle),
        trailing: isComingSoon
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              )
            : isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF00C853))
            : null,
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text(
          'This payment method will be available soon. Please use Cash for now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: const Text('Your payment has been processed successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class PaymentMethod {
  PaymentMethod(this.name, this.icon, this.subtitle);
  final String name;
  final IconData icon;
  final String subtitle;
}
