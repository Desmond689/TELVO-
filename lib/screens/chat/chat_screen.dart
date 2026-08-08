import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/chat_provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/services/storage_service.dart';
import 'package:telvo/models/chat_model.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/utils/error_messages.dart';
import 'package:telvo/utils/helpers.dart';
import 'package:telvo/widgets/empty_state.dart';

/// WhatsApp-style chat screen.
/// My messages (senderId == currentUser.uid) appear on the RIGHT.
/// Other user's messages appear on the LEFT.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatThread? _thread;
  UserModel? _otherUser;
  bool _isLoading = true;
  bool _hasMarkedRead = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_thread != null || !_isLoading) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;

    if (args is ChatThread) {
      _thread = args;
      _loadOtherUser();
    } else if (args is String && currentUserId != null) {
      _createThreadFromUserId(currentUserId, args);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createThreadFromUserId(
    String currentUserId,
    String otherUserId,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      _thread = await context.read<ChatProvider>().createChat(
            currentUserId,
            otherUserId,
          );
      if (mounted) {
        await _loadOtherUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOtherUser() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    final otherId = _thread!.user1Id == userId
        ? _thread!.user2Id
        : _thread!.user1Id;

    String? fallbackOtherId;
    if (_thread!.participantIds != null) {
      final found = _thread!.participantIds!
          .where((id) => id != userId)
          .toList();
      fallbackOtherId = found.isNotEmpty ? found.first : null;
    }

    final resolvedOtherId = otherId ?? fallbackOtherId;

    try {
      if (resolvedOtherId == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(resolvedOtherId)
          .get();
      if (doc.exists) {
        _otherUser = UserModel.fromMap({...doc.data()!, 'id': doc.id});
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendMessage() async {
    final me = context.read<AuthProvider>().currentUser;
    final otherId = _otherUser?.id;
    if (me != null && otherId != null) {
      if (me.blockedUsers.contains(otherId) ||
          (_otherUser?.blockedUsers.contains(me.id) ?? false)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot message this user.')),
          );
        }
        return;
      }
    }
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null || _thread == null) return;

    final receiverId = _resolveReceiverId(userId);
    if (receiverId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to determine recipient.')),
        );
      }
      return;
    }

    final message = ChatMessage(
      chatId: _thread!.id,
      senderId: userId,
      receiverId: receiverId,
      message: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      await context.read<ChatProvider>().sendMessage(message);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _attachImage() async {
    final me = context.read<AuthProvider>().currentUser;
    final otherId = _otherUser?.id;
    if (me != null && otherId != null) {
      if (me.blockedUsers.contains(otherId) ||
          (_otherUser?.blockedUsers.contains(me.id) ?? false)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot message this user.')),
          );
        }
        return;
      }
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId == null || _thread == null) return;

    final receiverId = _resolveReceiverId(userId);
    if (receiverId.isEmpty) return;

    try {
      final url = await StorageService().uploadChatImage(
        _thread!.id!,
        picked,
      );
      if (url == null || url.isEmpty) {
        throw Exception('Image upload failed');
      }

      final message = ChatMessage(
        chatId: _thread!.id,
        senderId: userId,
        receiverId: receiverId,
        message: '📷 Photo',
        type: 'image',
        mediaUrl: url,
        timestamp: DateTime.now(),
      );

      await context.read<ChatProvider>().sendMessage(message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _resolveReceiverId(String currentUserId) {
    if (_thread == null) return '';
    final participantIds = _thread!.participantIds;
    if (participantIds != null && participantIds.isNotEmpty) {
      final receiverId = participantIds
          .firstWhere((id) => id != currentUserId, orElse: () => '');
      if (receiverId.isNotEmpty) return receiverId;
    }

    if (_thread!.user1Id != null && _thread!.user2Id != null) {
      return _thread!.user1Id == currentUserId
          ? _thread!.user2Id ?? ''
          : _thread!.user1Id ?? '';
    }

    return '';
  }

  List<_ChatListItem> _buildListItems(List<ChatMessage> messages) {
    final items = <_ChatListItem>[];
    DateTime? lastDate;

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final ts = msg.timestamp ?? DateTime.now();
      final day = DateTime(ts.year, ts.month, ts.day);

      if (lastDate == null || day != lastDate) {
        items.add(_ChatListItem.separator(day));
        lastDate = day;
      }
      items.add(_ChatListItem.message(msg));
    }
    return items;
  }

  String _dateLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    return '${day.day.toString().padLeft(2, '0')}/'
        '${day.month.toString().padLeft(2, '0')}/'
        '${day.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = authProvider.currentUser?.id;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_thread == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Unable to start chat.')),
      );
    }

    final otherName = _otherUser?.fullName ??
        (_thread!.user1Id == userId ? _thread!.user2Name : _thread!.user1Name);
    final otherPhoto = _otherUser?.profilePhoto ??
        (_thread!.user1Id == userId
            ? _thread!.user2Photo
            : _thread!.user1Photo);

    final chatBg = isDark
        ? const Color(0xFF0B141A)
        : const Color(0xFFECE5DD);

    return Scaffold(
      backgroundColor: chatBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2C34) : colorScheme.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage:
                  otherPhoto != null ? NetworkImage(otherPhoto) : null,
              child: otherPhoto == null
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _otherUser?.isOnline == true
                        ? 'online'
                        : _otherUser?.lastActive != null
                            ? 'last seen ${_formatRelativeTime(_otherUser!.lastActive!)}'
                            : 'offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              final phone = _otherUser?.phoneNumber;
              if (phone == null || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No phone number on file for this user.'),
                  ),
                );
                return;
              }
              Helpers.callNumber(context, phone);
            },
            icon: const Icon(Icons.call),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.pushNamed(
                  context,
                  '/professional-profile',
                  arguments: _otherUser,
                );
              } else if (value == 'report') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Reporting isn't available yet."),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('View profile')),
              PopupMenuItem(value: 'report', child: Text('Report')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: context
                  .read<ChatProvider>()
                  .getChatMessages(_thread!.id!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return EmptyState(
                    title: 'Could not load messages',
                    subtitle: getFriendlyErrorMessage(snapshot.error!),
                    imagePath: 'assets/images/no_connection.png',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (!_hasMarkedRead && userId != null && messages.isNotEmpty) {
                  _hasMarkedRead = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<ChatProvider>().markAsRead(_thread!.id!, userId);
                  });
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE1F3FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Say hello! Messages are protected by Firestore rules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  );
                }

                final items = _buildListItems(messages);

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item.isSeparator) {
                      return _DateSeparator(label: _dateLabel(item.day!));
                    }
                    final message = item.message!;
                    final isMe = message.senderId == userId;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      isDark: isDark,
                      colorScheme: colorScheme,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(isDark, colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark, ColorScheme colorScheme) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        color: isDark ? const Color(0xFF1F2C34) : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _attachImage,
              icon: Icon(
                Icons.attach_file,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3942) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sendMessage,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

class _ChatListItem {
  _ChatListItem.message(this.message)
      : isSeparator = false,
        day = null;

  _ChatListItem.separator(this.day)
      : isSeparator = true,
        message = null;

  final bool isSeparator;
  final ChatMessage? message;
  final DateTime? day;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFE1F3FB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
    required this.colorScheme,
  });

  final ChatMessage message;
  final bool isMe;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? colorScheme.primary
        : (isDark ? const Color(0xFF1F2C34) : Colors.white);

    final textColor = isMe
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    final timeColor = isMe
        ? colorScheme.onPrimary.withValues(alpha: 0.75)
        : colorScheme.onSurface.withValues(alpha: 0.55);

    final time = message.timestamp ?? DateTime.now();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isMe ? 48 : 4,
            right: isMe ? 4 : 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.type == 'image' && message.mediaUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    message.mediaUrl!,
                    width: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image,
                      color: textColor,
                    ),
                  ),
                ),
                if ((message.message ?? '').isNotEmpty &&
                    message.message != '📷 Photo')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message.message!,
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                  ),
              ] else
                Text(
                  message.message ?? '',
                  style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 11, color: timeColor),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _statusIcon(message),
                      size: 14,
                      color: message.isRead == true || message.isSeen == true
                          ? const Color(0xFF53BDEB)
                          : timeColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(ChatMessage m) {
    if (m.isRead == true || m.isSeen == true) return Icons.done_all;
    if (m.isDelivered == true) return Icons.done_all;
    return Icons.done;
  }
}
