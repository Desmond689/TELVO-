import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/admin_provider.dart';
import 'package:telvo/models/payment_model.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  String _filterStatus = 'All';
  String _filterMethod = 'All';
  String _sortBy = 'newest';

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Processing',
    'Completed',
    'Failed',
    'Refunded',
  ];

  final List<String> _methodOptions = [
    'All',
    'Cash',
    'MTN MoMo',
    'Orange Money',
    'Card',
    'Escrow',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final payments = _filteredPayments(adminProvider.payments);

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : payments.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    return _buildPaymentCard(payments[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search payments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                // Search logic
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _filterStatus,
            items: _statusOptions.map((status) {
              return DropdownMenuItem(value: status, child: Text(status));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filterStatus = value!;
              });
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _filterMethod,
            items: _methodOptions.map((method) {
              return DropdownMenuItem(value: method, child: Text(method));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filterMethod = value!;
              });
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Newest')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
              DropdownMenuItem(value: 'amount', child: Text('Amount')),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  List<PaymentModel> _filteredPayments(List<PaymentModel> payments) {
    var filtered = payments;

    if (_filterStatus != 'All') {
      filtered = filtered
          .where((p) => p.status?.toLowerCase() == _filterStatus.toLowerCase())
          .toList();
    }

    if (_filterMethod != 'All') {
      filtered = filtered
          .where(
            (p) =>
                p.method?.toLowerCase() ==
                _filterMethod.toLowerCase().replaceAll(' ', '_'),
          )
          .toList();
    }

    switch (_sortBy) {
      case 'newest':
        filtered.sort(
          (a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime.now()) ?? 0,
        );
        break;
      case 'oldest':
        filtered.sort(
          (a, b) => a.createdAt?.compareTo(b.createdAt ?? DateTime.now()) ?? 0,
        );
        break;
      case 'amount':
        filtered.sort((a, b) => (b.amount ?? 0).compareTo(a.amount ?? 0));
        break;
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No payments found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(payment.status).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(payment.status),
                    color: _getStatusColor(payment.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Payment #${payment.id?.substring(0, 8) ?? 'N/A'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                payment.status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              payment.status?.toUpperCase() ?? 'PENDING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(payment.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${payment.method?.toUpperCase() ?? 'N/A'} • ${_formatDate(payment.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'XAF ${payment.amount?.toStringAsFixed(0) ?? '0'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(payment.status),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        payment.customerId?.substring(0, 8) ?? 'N/A',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Professional',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        payment.professionalId?.substring(0, 8) ?? 'N/A',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (payment.transactionId != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transaction ID',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          payment.transactionId!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (payment.status == 'pending' ||
                    payment.status == 'processing')
                  TextButton(
                    onPressed: () => _processPayment(payment),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00C853),
                    ),
                    child: const Text('Process'),
                  ),
                if (payment.status == 'completed')
                  TextButton(
                    onPressed: () => _refundPayment(payment),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    child: const Text('Refund'),
                  ),
                TextButton(
                  onPressed: () => _viewPaymentDetails(payment),
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'refunded':
        return Icons.currency_exchange;
      default:
        return Icons.payment;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  void _processPayment(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payment'),
        content: Text(
          'Are you sure you want to process payment #${payment.id?.substring(0, 8)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Process payment logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment processed successfully'),
                  backgroundColor: Color(0xFF00C853),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  void _refundPayment(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund Payment'),
        content: Text(
          'Are you sure you want to refund XAF ${payment.amount?.toStringAsFixed(0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminProvider>().processRefund(payment.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refund processed successfully'),
                  backgroundColor: Color(0xFF00C853),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Refund'),
          ),
        ],
      ),
    );
  }

  void _viewPaymentDetails(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', payment.id ?? 'N/A'),
              _buildDetailRow(
                'Amount',
                'XAF ${payment.amount?.toStringAsFixed(0)}',
              ),
              _buildDetailRow('Method', payment.method?.toUpperCase() ?? 'N/A'),
              _buildDetailRow('Status', payment.status?.toUpperCase() ?? 'N/A'),
              _buildDetailRow('Customer ID', payment.customerId ?? 'N/A'),
              _buildDetailRow(
                'Professional ID',
                payment.professionalId ?? 'N/A',
              ),
              _buildDetailRow('Transaction ID', payment.transactionId ?? 'N/A'),
              _buildDetailRow('Reference', payment.reference ?? 'N/A'),
              _buildDetailRow('Created', _formatDate(payment.createdAt)),
              if (payment.completedAt != null)
                _buildDetailRow('Completed', _formatDate(payment.completedAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
