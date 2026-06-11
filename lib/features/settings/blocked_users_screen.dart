import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/image_helper.dart';
import '../contacts/contacts_notifier.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(contactsNotifierProvider.notifier).loadBlockedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contactsNotifierProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Blocked Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (state.status == ContactOpsStatus.loading && state.blockedUsers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.blockedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No blocked users',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Blocked contacts will appear here'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.blockedUsers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final user = state.blockedUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profilePictureUrl.isNotEmpty
                        ? getBase64ImageProvider(user.profilePictureUrl)
                        : null,
                    child: user.profilePictureUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user.phoneNumber),
                  trailing: TextButton(
                    onPressed: () {
                      ref.read(contactsNotifierProvider.notifier).unblockUser(user.uid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Unblocked ${user.displayName}')),
                      );
                    },
                    child: const Text('UNBLOCK', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
