import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'contacts_notifier.dart';
import '../../core/utils/image_helper.dart';
import '../../domain/entities/user_entity.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();
    ref.read(contactsNotifierProvider.notifier).searchUser(_searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contactsNotifierProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('New Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search User by Username',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              
              // Username Input Field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter username (e.g. john_doe)',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: state.status == ContactOpsStatus.loading ? null : _search,
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(56, 56),
                    ),
                    icon: state.status == ContactOpsStatus.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              const Divider(thickness: 0.5),
              const SizedBox(height: 24),
              
              // Search Results display
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.status == ContactOpsStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == ContactOpsStatus.error && state.errorMessage != null) {
                      return Center(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                        ),
                      );
                    }
                    if (state.searchResult != null) {
                      final user = state.searchResult!;
                      return Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: user.profilePictureUrl.isNotEmpty
                                        ? getBase64ImageProvider(user.profilePictureUrl)
                                        : null,
                                    child: user.profilePictureUrl.isEmpty
                                        ? const Icon(Icons.person, size: 30)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName,
                                          style: theme.textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '@${user.username}',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.about,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.pushReplacement('/chat/${user.uid}');
                                  },
                                  icon: const Icon(Icons.message_rounded),
                                  label: const Text('Start Chat'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () => _showOptionsDialog(context, user.uid, theme),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  minimumSize: const Size(52, 52),
                                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                                ),
                                child: Icon(Icons.more_vert, color: theme.colorScheme.error),
                              ),
                            ],
                          )
                        ],
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contacts_rounded, size: 60, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                          const SizedBox(height: 12),
                          const Text('Search for your contacts to start chatting'),
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, String uid, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  ref.read(contactsNotifierProvider.notifier).blockUser(uid);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text('Report User'),
                onTap: () {
                  ref.read(contactsNotifierProvider.notifier).reportUser(uid, 'Inappropriate behavior');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User reported')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
