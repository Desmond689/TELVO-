import 'package:flutter/material.dart';
import 'package:telvo/config/routes.dart';

class NotificationBanner extends StatefulWidget {
  final String? imageUrl;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final VoidCallback? onTap;

  const NotificationBanner({
    Key? key,
    this.imageUrl,
    required this.title,
    required this.body,
    this.type,
    this.data,
    this.onTap,
  }) : super(key: key);

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    // Auto-dismiss
    Future.delayed(const Duration(seconds: 4)).then((_) {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'new_job':
      case 'job_update':
        return Icons.work_outline;
      case 'quote_accepted':
      case 'new_quote':
        return Icons.receipt_long;
      case 'payment':
      case 'job_completed':
        return Icons.payment;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return SafeArea(
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      widget.imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(radius: 24, child: Icon(_iconForType(widget.type))),
                    ),
                  )
                else
                  CircleAvatar(radius: 24, child: Icon(_iconForType(widget.type))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(widget.body, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: widget.onTap, icon: Icon(Icons.chevron_right)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
