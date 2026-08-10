import 'package:flutter/material.dart';

class AdminFraudDetectionScreen extends StatefulWidget {
  const AdminFraudDetectionScreen({super.key});

  @override
  State<AdminFraudDetectionScreen> createState() =>
      _AdminFraudDetectionScreenState();
}

class _AdminFraudDetectionScreenState extends State<AdminFraudDetectionScreen> {
  String _filterStatus = 'All';
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Verified',
    'Dismissed',
  ];

  final List<Map<String, dynamic>> _fraudReports = [
    {
      'id': '1',
      'reportedUser': 'John Doe',
      'reportedBy': 'Jane Smith',
      'reason': 'Fake Profile',
      'description': 'Using someone else\'s photos and fake credentials',
      'status': 'pending',
      'riskLevel': 'high',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'evidence': ['screenshot1.jpg', 'screenshot2.jpg'],
      'aiAnalysis': {
        'confidence': 0.92,
        'flags': ['Suspicious Email', 'Fake Photo', 'Inconsistent Info'],
      },
    },
    {
      'id': '2',
      'reportedUser': 'Franck',
      'reportedBy': 'Mike Johnson',
      'reason': 'Scam Attempt',
      'description': 'Requested payment outside the platform',
      'status': 'investigating',
      'riskLevel': 'high',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      'evidence': ['chat_screenshot.jpg'],
      'aiAnalysis': {
        'confidence': 0.88,
        'flags': ['Off-platform Payment Request', 'Suspicious Links'],
      },
    },
    {
      'id': '3',
      'reportedUser': 'Junior',
      'reportedBy': 'Alice Brown',
      'reason': 'Fake Reviews',
      'description': 'Professional creating fake reviews for themselves',
      'status': 'dismissed',
      'riskLevel': 'low',
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      'evidence': [],
      'aiAnalysis': {'confidence': 0.25, 'flags': []},
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredReports = _filteredReports(_fraudReports);

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: filteredReports.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    return _buildFraudCard(filteredReports[index]);
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
            child: Row(
              children: [
                Icon(Icons.security, color: Color(0xFF00C853)),
                SizedBox(width: 8),
                Text(
                  'Fraud Detection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
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

  List<Map<String, dynamic>> _filteredReports(
    List<Map<String, dynamic>> reports,
  ) {
    if (_filterStatus == 'All') return reports;
    return reports
        .where((r) => r['status'] == _filterStatus.toLowerCase())
        .toList();
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No fraud reports found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudCard(Map<String, dynamic> report) {
    final statusColor = _getStatusColor(report['status']);
    final riskColor = _getRiskColor(report['riskLevel']);

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
                    color: riskColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning, color: riskColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report #${report['id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${report['reason']} • ${report['reportedUser']} vs ${report['reportedBy']}',
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
                    color: riskColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report['riskLevel'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report['status'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(report['description'], style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            if (report['aiAnalysis'] != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    size: 16,
                    color: Color(0xFF00C853),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI Analysis: ${(report['aiAnalysis']['confidence'] * 100).toInt()}% confidence',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: (report['aiAnalysis']['confidence'] * 100) >= 80
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...List<String>.from(report['aiAnalysis']['flags']).map((
                    flag,
                  ) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        flag,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade700,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (report['evidence'] != null && report['evidence'].isNotEmpty)
              Wrap(
                spacing: 8,
                children: report['evidence'].map((evidence) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.attach_file,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(evidence, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (report['status'] == 'pending')
                  ElevatedButton(
                    onPressed: () => _verifyFraudReport(report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      minimumSize: const Size(100, 36),
                    ),
                    child: const Text('Verify'),
                  ),
                const SizedBox(width: 8),
                if (report['status'] == 'pending' ||
                    report['status'] == 'investigating')
                  TextButton(
                    onPressed: () => _dismissReport(report),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text('Dismiss'),
                  ),
                TextButton(
                  onPressed: () => _viewFraudDetails(report),
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
      case 'pending':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      case 'verified':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
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

  void _verifyFraudReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Fraud Report'),
        content: const Text(
          'After verification, the reported user will be flagged and appropriate actions will be taken.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                report['status'] = 'verified';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fraud report verified. User flagged.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Flag as Fraud'),
          ),
        ],
      ),
    );
  }

  void _dismissReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Report'),
        content: const Text(
          'Are you sure you want to dismiss this fraud report?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                report['status'] = 'dismissed';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report dismissed'),
                  backgroundColor: Colors.grey,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _viewFraudDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fraud Report #${report['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', report['status'].toUpperCase()),
              _buildDetailRow('Risk Level', report['riskLevel'].toUpperCase()),
              _buildDetailRow('Reported User', report['reportedUser']),
              _buildDetailRow('Reported By', report['reportedBy']),
              _buildDetailRow('Reason', report['reason']),
              _buildDetailRow('Created', _formatDate(report['createdAt'])),
              const SizedBox(height: 8),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(report['description']),
              if (report['aiAnalysis'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'AI Analysis',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${(report['aiAnalysis']['confidence'] * 100).toInt()}%',
                ),
                Text('Flags: ${report['aiAnalysis']['flags'].join(', ')}'),
              ],
              if (report['evidence'] != null &&
                  report['evidence'].isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Evidence',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...report['evidence'].map((e) => Text('• $e')),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
