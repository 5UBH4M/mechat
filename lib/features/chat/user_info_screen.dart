import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/image_helper.dart';
import '../../domain/entities/user_entity.dart';
import '../auth/auth_notifier.dart';

class UserInfoScreen extends ConsumerStatefulWidget {
  final UserEntity user;

  const UserInfoScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends ConsumerState<UserInfoScreen> {
  late UserEntity _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _listenToUserUpdates();
  }

  void _listenToUserUpdates() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null && mounted) {
        setState(() {
          _user = UserEntity(
            uid: doc.id,
            phoneNumber: doc.data()?['phoneNumber'] ?? '',
            username: doc.data()?['username'] ?? '',
            displayName: doc.data()?['displayName'] ?? 'User',
            profilePictureUrl: doc.data()?['profilePictureUrl'] ?? '',
            about: doc.data()?['about'] ?? '',
            isOnline: doc.data()?['isOnline'] ?? false,
            lastSeen: (doc.data()?['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
            publicKey: doc.data()?['publicKey'] ?? '',
            blockedUsers: List<String>.from(doc.data()?['blockedUsers'] ?? []),
            pushToken: doc.data()?['pushToken'] ?? '',
            createdAt: (doc.data()?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            lastSeenVisible: doc.data()?['lastSeenVisible'] ?? true,
            disconnectRequested: doc.data()?['disconnectRequested'] ?? false,
            connectedTo: doc.data()?['connectedTo'] ?? '',
            profilePhotoVisible: doc.data()?['profilePhotoVisible'] ?? true,
          );
        });
      }
    });
  }

  Future<void> _toggleBlock() async {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    final db = FirebaseFirestore.instance;
    final myDoc = db.collection('users').doc(currentUser.uid);
    final isBlocked = currentUser.blockedUsers.contains(_user.uid);

    if (isBlocked) {
      await myDoc.update({
        'blockedUsers': FieldValue.arrayRemove([_user.uid]),
      });
    } else {
      await myDoc.update({
        'blockedUsers': FieldValue.arrayUnion([_user.uid]),
      });
    }

    // Refresh auth state
    ref.read(authNotifierProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authNotifierProvider).user;
    final isBlockedByMe = currentUser?.blockedUsers.contains(_user.uid) ?? false;

    final bothAllowLastSeen = currentUser != null &&
        currentUser.lastSeenVisible &&
        _user.lastSeenVisible;

    final isOnlineNow = _user.isOnline &&
        DateTime.now().difference(_user.lastSeen).inSeconds < 90;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Hero profile picture as app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _user.profilePictureUrl.isNotEmpty
                  ? Base64Image(
                      base64String: _user.profilePictureUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 300,
                    )
                  : Container(
                      color: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 120,
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.4),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Name and online status section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: theme.colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user.displayName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_user.username.isNotEmpty)
                        Text(
                          '@${_user.username}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (bothAllowLastSeen)
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isOnlineNow ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOnlineNow
                                  ? 'Online'
                                  : 'Last seen ${DateFormatter.formatShort(_user.lastSeen)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isOnlineNow ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: isOnlineNow ? FontWeight.w600 : null,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // About section
                if (_user.about.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: theme.colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user.about,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Phone number section
                if (_user.phoneNumber.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: theme.colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            const SizedBox(width: 12),
                            Text(
                              _user.phoneNumber,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Block / Unblock action
                Container(
                  width: double.infinity,
                  color: theme.colorScheme.surface,
                  child: ListTile(
                    leading: Icon(
                      isBlockedByMe ? Icons.block : Icons.block_outlined,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      isBlockedByMe ? 'Unblock ${_user.displayName}' : 'Block ${_user.displayName}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(isBlockedByMe ? 'Unblock?' : 'Block?'),
                          content: Text(
                            isBlockedByMe
                                ? 'Are you sure you want to unblock ${_user.displayName}?'
                                : 'Are you sure you want to block ${_user.displayName}? They will not be able to send you messages.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                              ),
                              child: Text(isBlockedByMe ? 'Unblock' : 'Block'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _toggleBlock();
                      }
                    },
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
