import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/widgets/remote_image.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  String _filterType = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _verificationRequests = [];
  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Verified',
    'Rejected',
    'Required',
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadVerificationRequests();
  }

  Future<void> _loadVerificationRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snap = await _firestore
          .collection('verifications')
          .orderBy('submittedAt', descending: true)
          .get();

      final requests = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        String name = 'Unknown';
        String type = 'professional';
        String verificationStatus = 'unverified';
        DateTime? submittedAt;
        String? rejectedReason;
        if (data['submittedAt'] is Timestamp) {
          submittedAt = (data['submittedAt'] as Timestamp).toDate();
        }

        if (userId != null) {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null) {
              name = userData['fullName'] as String? ?? name;
              type = userData['userType'] as String? ?? type;
              verificationStatus = userData['verificationStatus'] as String? ?? verificationStatus;
              rejectedReason = userData['verificationRejectedReason'] as String?;
            }
          }
        }

        final photos = List<String>.from(data['photos'] ?? []);

        requests.add({
          'id': doc.id,
          'userId': userId,
          'name': name,
          'type': type,
          'status': (data['status'] as String?)?.toLowerCase() ?? 'pending',
          'verificationStatus': verificationStatus.toLowerCase(),
          'submittedAt': submittedAt,
          'photos': photos,
          'rejectedReason': rejectedReason,
        });
      }

      setState(() {
        _verificationRequests = requests;
      });
    } catch (_) {
      // Intentionally ignore so screen still renders with empty state.
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _filteredRequests(_verificationRequests);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Requests'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'Filter by status',
                      border: OutlineInputBorder(),
                    ),
                    items: _filterOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _filterType = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filteredRequests.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredRequests.length,
                          itemBuilder: (context, index) => _buildVerificationCard(filteredRequests[index]),
                        ),
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
      case 'Pending':
        return requests.where((r) => r['status'] == 'pending').toList();
      case 'Verified':
        return requests.where((r) => r['status'] == 'verified').toList();
      case 'Rejected':
        return requests.where((r) => r['status'] == 'rejected').toList();
      case 'Required':
        return requests.where((r) => r['verificationStatus'] == 'required').toList();
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
    final status = request['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final photos = List<String>.from(request['photos'] ?? []);

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
                      : status == 'verified'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                  child: Text(
                    (request['name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(
                      color: isPending
                          ? Colors.orange
                          : status == 'verified'
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['name'] as String? ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        (request['type'] as String?)?.toUpperCase() ?? 'PROFESSIONAL',
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
            if (photos.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final photoUrl = photos[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: RemoteImage(
                        imageUrl: photoUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.document_scanner, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (photos.isNotEmpty) const SizedBox(height: 12),
            Text(
              'Submitted: ${_formatDate(request['submittedAt'] as DateTime?)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (request['rejectedReason'] != null && status == 'rejected') ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${request['rejectedReason']}',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      onPressed: () => _showApproveDialog(request),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      isOutlined: true,
                      backgroundColor: Colors.red,
                      onPressed: () => _showRejectDialog(request),
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

  void _showApproveDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Verification'),
        content: Text(
          'Are you sure you want to verify ${request['name']}?'
          ' This will mark their identity as verified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _approveRequest(request);
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

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final userId = request['userId'] as String?;
    final requestId = request['id'] as String?;
    if (userId == null || requestId == null) return;

    try {
      await _firestore.collection('verifications').doc(requestId).update({
        'status': 'verified',
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verificationStatus': 'verified',
        'verificationRejectedReason': null,
        'verificationRejectionReason': null,
        'verificationRejectedAt': null,
        'isIdVerified': true,
        'isSelfieVerified': true,
      });
      await _loadVerificationRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification approved successfully'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to approve verification. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(Map<String, dynamic> request) {
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
            onPressed: () async {
              Navigator.pop(context);
              await _rejectRequest(request, reasonController.text.trim());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRequest(Map<String, dynamic> request, String reason) async {
    final userId = request['userId'] as String?;
    final requestId = request['id'] as String?;
    if (userId == null || requestId == null) return;

    try {
      await _firestore.collection('verifications').doc(requestId).update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });
      await _firestore.collection('users').doc(userId).update({
        'isVerified': false,
        'verificationStatus': 'rejected',
        'verificationRejectedReason': reason.isNotEmpty ? reason : null,
        'verificationRejectionReason': reason.isNotEmpty ? reason : null,
        'verificationRejectedAt': FieldValue.serverTimestamp(),
        'verificationRejectedCount': FieldValue.increment(1),
        'isIdVerified': false,
        'isSelfieVerified': false,
      });
      await _loadVerificationRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification rejected'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to reject verification. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
