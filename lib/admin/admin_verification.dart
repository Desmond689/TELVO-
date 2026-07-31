import 'package:flutter/material.dart';
import 'package:telvo/widgets/custom_button.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  String _filterType = 'All';
  final List<String> _filterOptions = [
    'All',
    'Pending Phone',
    'Pending Email',
    'Pending ID',
    'Pending Selfie',
    'Pending Review',
    'Verified',
    'Rejected',
  ];

  final List<Map<String, dynamic>> _verificationRequests = [
    {
      'id': '1',
      'name': 'Emmanuel',
      'type': 'professional',
      'phoneVerified': true,
      'emailVerified': true,
      'idVerified': true,
      'selfieVerified': false,
      'submittedAt': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'pending',
      'documents': [
        {'type': 'National ID', 'url': 'id_front.jpg'},
        {'type': 'National ID Back', 'url': 'id_back.jpg'},
        {'type': 'Selfie', 'url': 'selfie.jpg'},
      ],
    },
    {
      'id': '2',
      'name': 'Franck',
      'type': 'professional',
      'phoneVerified': true,
      'emailVerified': false,
      'idVerified': true,
      'selfieVerified': true,
      'submittedAt': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'pending',
      'documents': [
        {'type': 'Passport', 'url': 'passport.jpg'},
        {'type': 'Selfie', 'url': 'selfie.jpg'},
      ],
    },
    {
      'id': '3',
      'name': 'Junior',
      'type': 'professional',
      'phoneVerified': true,
      'emailVerified': true,
      'idVerified': true,
      'selfieVerified': true,
      'submittedAt': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'verified',
      'documents': [
        {'type': 'National ID', 'url': 'id.jpg'},
        {'type': 'Selfie', 'url': 'selfie.jpg'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _filteredRequests(_verificationRequests);

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: filteredRequests.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    return _buildVerificationCard(filteredRequests[index]);
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
              'Verification Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          DropdownButton<String>(
            value: _filterType,
            items: _filterOptions.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filterType = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filteredRequests(
    List<Map<String, dynamic>> requests,
  ) {
    if (_filterType == 'All') return requests;

    switch (_filterType) {
      case 'Pending Phone':
        return requests.where((r) => !r['phoneVerified']).toList();
      case 'Pending Email':
        return requests.where((r) => !r['emailVerified']).toList();
      case 'Pending ID':
        return requests.where((r) => !r['idVerified']).toList();
      case 'Pending Selfie':
        return requests.where((r) => !r['selfieVerified']).toList();
      case 'Pending Review':
        return requests.where((r) => r['status'] == 'pending').toList();
      case 'Verified':
        return requests.where((r) => r['status'] == 'verified').toList();
      case 'Rejected':
        return requests.where((r) => r['status'] == 'rejected').toList();
      default:
        return requests;
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No verification requests',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> request) {
    final status = request['status'];
    final isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPending
                      ? Colors.orange.shade100
                      : Colors.green.shade100,
                  child: Text(
                    request['name'].substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: isPending ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        request['type'].toUpperCase(),
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
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'verified'
                        ? Colors.green.shade100
                        : status == 'rejected'
                        ? Colors.red.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: status == 'verified'
                          ? Colors.green
                          : status == 'rejected'
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildVerificationBadge('Phone', request['phoneVerified']),
                const SizedBox(width: 8),
                _buildVerificationBadge('Email', request['emailVerified']),
                const SizedBox(width: 8),
                _buildVerificationBadge('ID', request['idVerified']),
                const SizedBox(width: 8),
                _buildVerificationBadge('Selfie', request['selfieVerified']),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Submitted: ${_formatDate(request['submittedAt'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (request['documents'] != null)
              Wrap(
                spacing: 8,
                children: request['documents'].map<Widget>((doc) {
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
                          Icons.description,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(doc['type'], style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      onPressed: () => _approveRequest(request),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      isOutlined: true,
                      backgroundColor: Colors.red,
                      onPressed: () => _rejectRequest(request),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(String label, bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: verified ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.check_circle : Icons.hourglass_empty,
            size: 12,
            color: verified ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: verified ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    }
    return 'Just now';
  }

  void _approveRequest(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Verification'),
        content: Text(
          'Are you sure you want to verify ${request['name']}?'
          ' This will grant them full access to the platform.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                request['status'] = 'verified';
                request['phoneVerified'] = true;
                request['emailVerified'] = true;
                request['idVerified'] = true;
                request['selfieVerified'] = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Professional verified successfully'),
                  backgroundColor: Color(0xFF00C853),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(Map<String, dynamic> request) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to reject ${request['name']}\'s verification?',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                request['status'] = 'rejected';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
