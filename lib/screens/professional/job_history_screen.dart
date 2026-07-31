import 'package:flutter/material.dart';
import 'package:telvo/models/job_model.dart';

/// Full job list for a professional, reached from the dashboard's
/// "See All" link. Takes the already-loaded job list as route arguments
/// rather than re-querying, since the dashboard just loaded it.
class JobHistoryScreen extends StatelessWidget {
  const JobHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobs =
        ModalRoute.of(context)?.settings.arguments as List<JobModel>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Job History'), elevation: 0),
      body: jobs.isEmpty
          ? Center(
              child: Text(
                'No jobs yet.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) => _buildJobTile(context, jobs[index]),
            ),
    );
  }

  Widget _buildJobTile(BuildContext context, JobModel job) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.work, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.serviceType ?? job.category ?? 'Service',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Status: ${_statusLabel(job.status)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (job.budget != null)
          Text(
            'XAF ${job.budget!.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF00C853),
            ),
          ),
      ],
    ),
  );

  String _statusLabel(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    return status
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
