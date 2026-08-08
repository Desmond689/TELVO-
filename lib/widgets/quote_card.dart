import 'package:flutter/material.dart';
import 'package:telvo/models/job_model.dart';

class QuoteCard extends StatelessWidget {
  final QuoteModel quote;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const QuoteCard({
    super.key,
    required this.quote,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: (quote.workerImage != null &&
                        quote.workerImage!.isNotEmpty)
                    ? NetworkImage(quote.workerImage!)
                    : null,
                child: (quote.workerImage == null || quote.workerImage!.isEmpty)
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.workerName ?? 'Professional',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '130 jobs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                'XAF ${quote.price?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C853),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quote.message ?? 'No message',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.timer,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                'Est. ${quote.estimatedTime ?? 0} hours',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                'Arrives: ${_formatDate(quote.arrivalTime)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          if (quote.warranty != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Warranty: ${quote.warranty}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
          if (onAccept != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onAccept != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Accept this quote?'),
                            content: const Text(
                              'Only one quote can be accepted. All other quotes will be rejected.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C853),
                                ),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) onAccept!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                if (onAccept != null && onReject != null)
                  const SizedBox(width: 8),
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
