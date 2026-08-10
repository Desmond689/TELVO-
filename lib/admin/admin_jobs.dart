import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/admin_provider.dart';
import 'package:telvo/models/job_model.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _filterCategory = 'All';
  String _sortBy = 'newest';

  final List<String> _statusOptions = [
    'All',
    'Posted',
    'Notified',
    'Quotes Received',
    'Accepted',
    'Working',
    'Completed',
    'Cancelled',
  ];

  final List<String> _categories = [
    'All',
    'Plumber',
    'Electrician',
    'Cleaner',
    'Painter',
    'Carpenter',
    'Mechanic',
    'Gardener',
    'Tutor',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final jobs = _filteredJobs(adminProvider.jobs);

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : jobs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    return _buildJobCard(jobs[index]);
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
                hintText: 'Search jobs...',
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
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
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
            value: _filterCategory,
            items: _categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filterCategory = value!;
              });
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Newest')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
              DropdownMenuItem(value: 'budget', child: Text('Budget')),
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

  List<JobModel> _filteredJobs(List<JobModel> jobs) {
    var filtered = jobs;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((job) {
        final description = job.description?.toLowerCase() ?? '';
        final category = job.category?.toLowerCase() ?? '';
        return description.contains(_searchQuery) ||
            category.contains(_searchQuery);
      }).toList();
    }

    if (_filterStatus != 'All') {
      filtered = filtered
          .where(
            (job) => job.status?.toLowerCase() == _filterStatus.toLowerCase(),
          )
          .toList();
    }

    if (_filterCategory != 'All') {
      filtered = filtered
          .where((job) => job.category == _filterCategory)
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
      case 'budget':
        filtered.sort((a, b) => (b.budget ?? 0).compareTo(a.budget ?? 0));
        break;
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No jobs found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(job.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.status?.toUpperCase() ?? 'PENDING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(job.status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.category ?? 'Service',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                if (job.urgency == 'emergency')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🚨 Emergency',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  'XAF ${job.budget?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C853),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.description ?? 'No description',
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.address ?? 'No address',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  job.customerId?.substring(0, 8) ?? 'N/A',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatDate(job.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (job.quotes != null && job.quotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${job.quotes!.length} quotes received',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    if (job.acceptedQuoteId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Accepted',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _viewJobDetails(job),
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 4),
                if (job.status != 'completed' && job.status != 'cancelled')
                  TextButton(
                    onPressed: () => _updateJobStatus(job),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    child: const Text('Update Status'),
                  ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => _deleteJob(job),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
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
      case 'posted':
        return Colors.blue;
      case 'notified':
        return Colors.orange;
      case 'quotes_received':
        return Colors.purple;
      case 'accepted':
        return Colors.green;
      case 'working':
        return Colors.teal;
      case 'completed':
        return Color(0xFF00C853);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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

  void _viewJobDetails(JobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Job Details - ${job.category}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', job.status?.toUpperCase() ?? 'N/A'),
              _buildDetailRow('Category', job.category ?? 'N/A'),
              _buildDetailRow(
                'Budget',
                'XAF ${job.budget?.toStringAsFixed(0) ?? '0'}',
              ),
              _buildDetailRow('Urgency', job.urgency?.toUpperCase() ?? 'N/A'),
              _buildDetailRow('Address', job.address ?? 'N/A'),
              _buildDetailRow('Created', _formatDate(job.createdAt)),
              _buildDetailRow('Description', job.description ?? 'N/A'),
              if (job.quotes != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Quotes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...job.quotes!.map(
                  (quote) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '💰 XAF ${quote.price?.toStringAsFixed(0)} - ${quote.message ?? ''}',
                      style: const TextStyle(fontSize: 13),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

  void _updateJobStatus(JobModel job) {
    final List<String> statuses = [
      'posted',
      'notified',
      'quotes_received',
      'accepted',
      'working',
      'completed',
    ];
    final currentIndex = statuses.indexOf(job.status ?? 'posted');
    final nextStatuses = statuses.sublist(currentIndex + 1);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Job Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select new status:'),
            const SizedBox(height: 8),
            ...nextStatuses.map(
              (status) => ListTile(
                title: Text(status.toUpperCase()),
                onTap: () {
                  context.read<AdminProvider>().updateJobStatus(
                    job.id!,
                    status,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Job status updated to ${status.toUpperCase()}',
                      ),
                      backgroundColor: const Color(0xFF00C853),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _deleteJob(JobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text(
          'Are you sure you want to delete this job? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminProvider>().deleteJob(job.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Job deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
