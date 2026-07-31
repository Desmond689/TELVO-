import 'package:flutter/material.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  String _filterStatus = 'All';
  final List<String> _statusOptions = [
    'All',
    'Open',
    'Investigating',
    'Resolved',
    'Closed',
  ];

  final List<Map<String, dynamic>> _disputes = [
    {
      'id': '1',
      'title': 'Payment Dispute',
      'customer': 'John Doe',
      'professional': 'Emmanuel',
      'status': 'open',
      'priority': 'high',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'description': 'Customer claims work was not completed to satisfaction',
      'messages': [
        {
          'sender': 'Customer',
          'message': 'I am not satisfied with the work',
          'time': DateTime.now().subtract(const Duration(hours: 5)),
        },
        {
          'sender': 'Professional',
          'message': 'I did everything as requested',
          'time': DateTime.now().subtract(const Duration(hours: 4)),
        },
      ],
    },
    {
      'id': '2',
      'title': 'Quality Issue',
      'customer': 'Jane Smith',
      'professional': 'Franck',
      'status': 'investigating',
      'priority': 'medium',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      'description': 'Professional used substandard materials',
      'messages': [
        {
          'sender': 'Customer',
          'message': 'The quality is not what was agreed',
          'time': DateTime.now().subtract(const Duration(hours: 2)),
        },
        {
          'sender': 'Admin',
          'message': 'We are investigating this issue',
          'time': DateTime.now().subtract(const Duration(hours: 1)),
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredDisputes = _filteredDisputes(_disputes);

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: filteredDisputes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDisputes.length,
                  itemBuilder: (context, index) {
                    return _buildDisputeCard(filteredDisputes[index]);
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
          const Expanded(
            child: Text(
              'Dispute Resolution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
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
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filteredDisputes(
    List<Map<String, dynamic>> disputes,
  ) {
    if (_filterStatus == 'All') return disputes;
    return disputes
        .where((d) => d['status'] == _filterStatus.toLowerCase())
        .toList();
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gavel_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No disputes found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> dispute) {
    final statusColor = _getStatusColor(dispute['status']);
    final priorityColor = _getPriorityColor(dispute['priority']);

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
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.gavel, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dispute['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '#${dispute['id']} • ${dispute['customer']} vs ${dispute['professional']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dispute['status'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dispute['priority'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(dispute['description'], style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            if (dispute['messages'] != null && dispute['messages'].isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: dispute['messages'].take(2).map<Widget>((msg) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '${msg['sender']}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              msg['message'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            _formatTime(msg['time']),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (dispute['status'] != 'closed' &&
                    dispute['status'] != 'resolved')
                  TextButton(
                    onPressed: () => _resolveDispute(dispute),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00C853),
                    ),
                    child: const Text('Resolve'),
                  ),
                TextButton(
                  onPressed: () => _viewDisputeDetails(dispute),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.red;
      case 'investigating':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  void _resolveDispute(Map<String, dynamic> dispute) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Dispute'),
        content: const Text('How would you like to resolve this dispute?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                dispute['status'] = 'resolved';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dispute resolved successfully'),
                  backgroundColor: Color(0xFF00C853),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  void _viewDisputeDetails(Map<String, dynamic> dispute) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dispute #${dispute['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', dispute['status'].toUpperCase()),
              _buildDetailRow('Priority', dispute['priority'].toUpperCase()),
              _buildDetailRow('Customer', dispute['customer']),
              _buildDetailRow('Professional', dispute['professional']),
              _buildDetailRow('Created', _formatDate(dispute['createdAt'])),
              const SizedBox(height: 8),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(dispute['description']),
              if (dispute['messages'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Messages',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...dispute['messages'].map(
                  (msg) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                msg['sender'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatTime(msg['time']),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          Text(msg['message']),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
        children: [
          SizedBox(
            width: 100,
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
