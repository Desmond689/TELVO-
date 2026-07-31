import 'package:flutter/material.dart';
import 'package:telvo/widgets/custom_button.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int _selectedPeriod = 0; // 0: Daily, 1: Weekly, 2: Monthly, 3: Yearly

  final List<Map<String, dynamic>> _transactions = [
    {
      'date': '2024-01-15',
      'job': 'Plumbing Repair',
      'amount': 15000,
      'status': 'Completed',
    },
    {
      'date': '2024-01-14',
      'job': 'Electrical Installation',
      'amount': 25000,
      'status': 'Completed',
    },
    {
      'date': '2024-01-13',
      'job': 'House Cleaning',
      'amount': 12000,
      'status': 'Completed',
    },
    {
      'date': '2024-01-12',
      'job': 'Painting Service',
      'amount': 18000,
      'status': 'Pending',
    },
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Earnings'), elevation: 0),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsSummary(),
          const SizedBox(height: 24),
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildChart(),
          const SizedBox(height: 24),
          _buildTransactions(),
        ],
      ),
    ),
  );

  Widget _buildEarningsSummary() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF00C853), Color(0xFF00E676)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total Earnings',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 4),
        const Text(
          'XAF 450,000',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildEarningsStat('This Month', 'XAF 150,000'),
            _buildEarningsStat('This Week', 'XAF 45,000'),
            _buildEarningsStat('Today', 'XAF 25,000'),
          ],
        ),
      ],
    ),
  );

  Widget _buildEarningsStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _buildPeriodSelector() {
    final periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: periods.asMap().entries.map((entry) {
          final index = entry.key;
          final period = entry.value;
          final isSelected = _selectedPeriod == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00C853)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() => Container(
    height: 120,
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text('Earnings Chart', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    ),
  );

  Widget _buildTransactions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              // View all transactions
            },
            child: const Text('See All'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: transaction['status'] == 'Completed'
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    transaction['status'] == 'Completed'
                        ? Icons.check
                        : Icons.hourglass_empty,
                    color: transaction['status'] == 'Completed'
                        ? Colors.green
                        : Colors.orange,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['job'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${transaction['date']} • ${transaction['status']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'XAF ${transaction['amount']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction['status'] == 'Completed'
                        ? const Color(0xFF00C853)
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      CustomButton(
        text: 'Withdraw Earnings',
        onPressed: () {
          _showWithdrawDialog();
        },
      ),
    ],
  );

  void _showWithdrawDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Earnings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter amount to withdraw',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelText: 'Amount (XAF)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawal request submitted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}
