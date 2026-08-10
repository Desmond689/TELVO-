import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/providers/job_provider.dart';
import 'package:telvo/utils/error_messages.dart';
import 'package:telvo/widgets/empty_state.dart';
import 'package:telvo/widgets/loading_indicator.dart';

/// Screen where professionals can view and Accept / Decline hire requests.
class HireRequestsScreen extends StatefulWidget {
  const HireRequestsScreen({super.key});

  @override
  State<HireRequestsScreen> createState() => _HireRequestsScreenState();
}

class _HireRequestsScreenState extends State<HireRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await context.read<JobProvider>().loadHireRequests(userId);
  }

  Future<void> _respond(HireRequestModel hire, bool accept) async {
    final jobProvider = context.read<JobProvider>();
    try {
      await jobProvider.respondToHireRequest(hire.id!, accept);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Hire request accepted' : 'Hire request declined'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getFriendlyErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobProvider = context.watch<JobProvider>();
    final requests = jobProvider.hireRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hire Requests'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: jobProvider.isLoading && requests.isEmpty
          ? const LoadingIndicator()
          : requests.isEmpty
              ? const EmptyState(
                  title: 'No hire requests',
                  subtitle: 'When customers hire you directly, requests appear here.',
                  imagePath: 'assets/images/empty_state.png',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final hire = requests[index];
                      final status = (hire.status ?? 'pending').toLowerCase();
                      final isPending = status == 'pending';

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      hire.category ?? 'Service request',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  _StatusChip(status: status),
                                ],
                              ),
                              if (hire.description != null &&
                                  hire.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  hire.description!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 8),
                              if (hire.budget != null)
                                Text(
                                  'Budget: ${hire.budget!.toStringAsFixed(0)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (hire.address != null && hire.address!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 16,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          hire.address!,
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isPending) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _respond(hire, false),
                                        child: const Text('Decline'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () => _respond(hire, true),
                                        child: const Text('Accept'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'accepted':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case 'rejected':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
      default:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
