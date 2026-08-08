import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/notification_provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/models/notification_model.dart';
import 'package:telvo/widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final userId = authProvider.currentUser?.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              if (userId != null) {
                notificationProvider.markAllAsRead(userId);
              }
            },
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            onPressed: () {
              if (userId != null) {
                notificationProvider.clearNotifications(userId);
              }
            },
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: userId == null
          ? Center(
              child: Text(
                'Please login to view notifications',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            )
          : StreamBuilder<List<NotificationModel>>(
              stream: notificationProvider.getUserNotifications(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const EmptyState(
                    title: 'Could not load notifications',
                    subtitle: 'Please try again later.',
                    imagePath: 'assets/images/no_connection.png',
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data!;
                if (notifications.isEmpty) {
                  return const EmptyState(
                    title: 'No Notifications',
                    subtitle: 'You\'re all caught up!',
                    imagePath: 'assets/images/empty_state.png',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(
                      notification,
                      notificationProvider,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    final isRead = notification.isRead ?? false;
    final icon = _getNotificationIcon(notification.type);

    return GestureDetector(
      onTap: () {
        if (!isRead && notification.id != null) {
          provider.markAsRead(notification.id!);
        }
        _navigateForNotification(notification);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? Theme.of(context).colorScheme.outlineVariant
                : const Color(0xFF00C853),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title ?? '',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (notification.createdAt != null)
                    Text(
                      _formatTime(notification.createdAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00C853),
                  shape: BoxShape.circle,
                ),
              ),
            IconButton(
              onPressed: notification.id != null
                  ? () => provider.deleteNotification(notification.id!)
                  : null,
              icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateForNotification(NotificationModel notification) {
    final type = (notification.type ?? '').toLowerCase();
    final jobId = notification.jobId;
    final hireId = notification.hireId;
    final chatId = notification.chatId;

    if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) {
      final url = notification.actionUrl!;
      if (url.startsWith('/')) {
        Navigator.pushNamed(context, url, arguments: notification.data);
        return;
      }
    }

    if (type.contains('message') || chatId != null) {
      if (chatId != null) {
        Navigator.pushNamed(context, '/chat', arguments: chatId);
      } else {
        Navigator.pushNamed(context, '/chat-list');
      }
      return;
    }

    if (type.contains('hire') || hireId != null) {
      Navigator.pushNamed(context, '/hire-requests');
      return;
    }

    if (type.contains('quote') || type.contains('job') || jobId != null) {
      if (jobId != null && jobId.isNotEmpty) {
        Navigator.pushNamed(context, '/job-details', arguments: jobId);
      } else {
        Navigator.pushNamed(context, '/job-feed');
      }
      return;
    }

    if (type.contains('payment')) {
      Navigator.pushNamed(context, '/payment');
      return;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'job':
        return Icons.work;
      case 'hire':
      case 'hire_request':
        return Icons.handshake;
      case 'quote':
        return Icons.request_quote;
      case 'message':
        return Icons.message;
      case 'payment':
        return Icons.payment;
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'job':
        return Colors.blue;
      case 'message':
        return Colors.green;
      case 'payment':
        return Colors.orange;
      case 'promotion':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
