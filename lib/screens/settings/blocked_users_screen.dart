import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/providers/user_provider.dart';
import 'package:telvo/utils/error_messages.dart';
import 'package:telvo/widgets/empty_state.dart';
import 'package:telvo/widgets/safe_avatar.dart';

/// Lists the current user's blocked users (read live from AuthProvider,
/// which already syncs `blockedUsers` from the user's Firestore doc) and
/// lets them unblock. Previously this screen didn't exist at all — the
/// Settings entry just showed a "coming soon" snackbar even though
/// UserProvider.unblockUser() was fully implemented and unused.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _isLoading = true;
  String? _error;
  List<UserModel> _blockedUsers = [];

  // Track ids currently being unblocked so we can show a spinner on just
  // that row and prevent a double-tap from firing two writes.
  final Set<String> _unblockingIds = {};

  List<String>? _lastLoadedIds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final blockedIds = context.watch<AuthProvider>().currentUser?.blockedUsers ?? const [];
    // Reload whenever the set of blocked ids actually changes (e.g. after
    // an unblock elsewhere, or the initial load), not on every rebuild.
    if (_lastLoadedIds == null || !_sameIds(_lastLoadedIds!, blockedIds)) {
      _lastLoadedIds = List<String>.from(blockedIds);
      _loadBlockedUsers(blockedIds);
    }
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    return setA.length == b.toSet().length && setA.containsAll(b);
  }

  Future<void> _loadBlockedUsers(List<String> blockedIds) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (blockedIds.isEmpty) {
      setState(() {
        _blockedUsers = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final userProvider = context.read<UserProvider>();
      final users = await Future.wait(
        blockedIds.map((id) => userProvider.getUserById(id)),
      );
      if (!mounted) return;
      setState(() {
        _blockedUsers = users.whereType<UserModel>().toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = getFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _unblock(UserModel user) async {
    final me = context.read<AuthProvider>().currentUser;
    if (me?.id == null || user.id == null) return;

    setState(() => _unblockingIds.add(user.id!));
    try {
      await context.read<UserProvider>().unblockUser(me!.id!, user.id!);
      if (!mounted) return;
      setState(() {
        _blockedUsers.removeWhere((u) => u.id == user.id);
        _unblockingIds.remove(user.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.fullName ?? 'User'} unblocked')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _unblockingIds.remove(user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unblock: ${getFriendlyErrorMessage(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return EmptyState(
        title: 'Could not load blocked users',
        subtitle: _error!,
        imagePath: 'assets/images/no_connection.png',
        actionText: 'Retry',
        onAction: () => _loadBlockedUsers(_lastLoadedIds ?? const []),
      );
    }

    if (_blockedUsers.isEmpty) {
      return const EmptyState(
        title: 'No Blocked Users',
        subtitle: "You haven't blocked anyone. Blocked users can't message, "
            'call, or send you hire requests.',
        imagePath: 'assets/images/empty_state.png',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = _blockedUsers[index];
        final isUnblocking = _unblockingIds.contains(user.id);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              SafeAvatar(
                imageUrl: user.profilePhoto,
                radius: 24,
                fallback: Text(
                  (user.fullName?.trim().isNotEmpty == true)
                      ? user.fullName!.trim()[0].toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.fullName ?? 'Unknown User',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: isUnblocking ? null : () => _unblock(user),
                  child: isUnblocking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unblock'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
