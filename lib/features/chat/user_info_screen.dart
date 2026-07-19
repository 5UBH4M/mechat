import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/image_helper.dart';
import '../../domain/entities/user_entity.dart';
import '../auth/auth_notifier.dart';

class UserInfoScreen extends ConsumerStatefulWidget {
  final UserEntity user;

  const UserInfoScreen({super.key, required this.user});

  @override
  ConsumerState<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends ConsumerState<UserInfoScreen> {
  late UserEntity _user;
  int _sentCount = 0;
  int _receivedCount = 0;
  bool _isLoadingCounts = true;
  Duration _totalCallDuration = Duration.zero;
  List<Map<String, dynamic>> _callLogs = [];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _listenToUserUpdates();
    _fetchMessageCounts();
  }

  Future<void> _fetchMessageCounts() async {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    // We need to calculate the chat ID. The current implementation in chat_notifier is:
    final uid1 = currentUser.uid;
    final uid2 = widget.user.uid;
    final uids = [uid1, uid2]..sort();
    final chatId = uids.join('_');

    try {
      final sentQuery = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: currentUser.uid)
          .count()
          .get();

      final receivedQuery = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: widget.user.uid)
          .count()
          .get();

      final callsQuery1 = await FirebaseFirestore.instance
          .collection('calls')
          .where('callerId', isEqualTo: currentUser.uid)
          .where('receiverId', isEqualTo: widget.user.uid)
          .get();

      final callsQuery2 = await FirebaseFirestore.instance
          .collection('calls')
          .where('callerId', isEqualTo: widget.user.uid)
          .where('receiverId', isEqualTo: currentUser.uid)
          .get();

      List<Map<String, dynamic>> logs = [];
      for (var doc in callsQuery1.docs) {
        logs.add(doc.data());
      }
      for (var doc in callsQuery2.docs) {
        logs.add(doc.data());
      }

      // Sort descending by createdAt
      logs.sort((a, b) {
        final aTime =
            (a['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            (b['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      Duration totalDuration = Duration.zero;
      for (var data in logs) {
        if (data['status'] == 'ended' &&
            data['startedAt'] != null &&
            data['endedAt'] != null) {
          try {
            final start = (data['startedAt'] as Timestamp).toDate();
            final end = (data['endedAt'] as Timestamp).toDate();
            final diff = end.difference(start);
            if (diff.inSeconds > 0) {
              totalDuration += diff;
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _sentCount = sentQuery.count ?? 0;
          _receivedCount = receivedQuery.count ?? 0;
          _totalCallDuration = totalDuration;
          _callLogs = logs;
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ _fetchMessageCounts FAILED: $e');
      if (mounted) {
        setState(() => _isLoadingCounts = false);
      }
    }
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
                email: doc.data()?['email'] ?? '',
                username: doc.data()?['username'] ?? '',
                displayName: doc.data()?['displayName'] ?? 'User',
                profilePictureUrl: doc.data()?['profilePictureUrl'] ?? '',
                about: doc.data()?['about'] ?? '',
                isOnline: doc.data()?['isOnline'] ?? false,
                lastSeen:
                    (doc.data()?['lastSeen'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                publicKey: doc.data()?['publicKey'] ?? '',
                blockedUsers: List<String>.from(
                  doc.data()?['blockedUsers'] ?? [],
                ),
                pushToken: doc.data()?['pushToken'] ?? '',
                createdAt:
                    (doc.data()?['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                lastSeenVisible: doc.data()?['lastSeenVisible'] ?? true,
                disconnectRequested:
                    doc.data()?['disconnectRequested'] ?? false,
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
    final isBlockedByMe =
        currentUser?.blockedUsers.contains(_user.uid) ?? false;

    final bothAllowLastSeen =
        currentUser != null &&
        currentUser.lastSeenVisible &&
        _user.lastSeenVisible;

    final isOnlineNow =
        _user.isOnline &&
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
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
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
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.4,
                        ),
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
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
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
                                color: isOnlineNow
                                    ? Colors.green
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                fontWeight: isOnlineNow
                                    ? FontWeight.w600
                                    : null,
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
                        Text(_user.about, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Email section
                if (_user.email.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: theme.colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 20,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_user.email, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Message Stats section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: theme.colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message Statistics',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _isLoadingCounts
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '$_sentCount',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sent',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '$_receivedCount',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Received',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ],
                  ),
                ),

                // Call Logs Section
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.call_rounded, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Call History',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingCounts)
                        const Center(child: CircularProgressIndicator())
                      else if (_callLogs.isEmpty)
                        const Text(
                          'No previous calls.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Duration',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              DateFormatter.formatDurationReadable(
                                _totalCallDuration.inSeconds,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _callLogs.length,
                          itemBuilder: (context, index) {
                            final log = _callLogs[index];
                            final isVideo = log['isVideo'] == true;
                            final status =
                                (log['status'] as String?) ?? 'unknown';
                            final isCaller =
                                log['callerId'] ==
                                ref.read(authNotifierProvider).user?.uid;

                            final createdAt =
                                (log['createdAt'] as Timestamp?)?.toDate() ??
                                DateTime.now();
                            String durationStr = '';
                            if (log['startedAt'] != null &&
                                log['endedAt'] != null) {
                              try {
                                final start = (log['startedAt'] as Timestamp)
                                    .toDate();
                                final end = (log['endedAt'] as Timestamp)
                                    .toDate();
                                final secs = end.difference(start).inSeconds;
                                if (secs > 0) {
                                  durationStr =
                                      DateFormatter.formatDurationReadable(
                                        secs,
                                      );
                                }
                              } catch (_) {}
                            }

                            IconData iconData;
                            Color iconColor;
                            final isMissed =
                                status == 'rejected' ||
                                status == 'missed' ||
                                (status != 'ended' && status != 'connected');
                            if (isMissed) {
                              iconData = isCaller
                                  ? Icons.call_made_rounded
                                  : Icons.call_missed_rounded;
                              iconColor = Colors.red;
                            } else {
                              iconData = isCaller
                                  ? Icons.call_made_rounded
                                  : Icons.call_received_rounded;
                              iconColor = Colors.green;
                            }

                            String trailingText;
                            if (durationStr.isNotEmpty) {
                              trailingText = durationStr;
                            } else if (isMissed) {
                              trailingText = 'Missed';
                            } else {
                              trailingText = status.toUpperCase();
                            }

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  iconData,
                                  color: iconColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                isMissed
                                    ? 'Missed Call'
                                    : (isVideo ? 'Video Call' : 'Voice Call'),
                              ),
                              subtitle: Text(
                                DateFormatter.formatShort(createdAt),
                              ),
                              trailing: Text(
                                trailingText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMissed ? Colors.red : Colors.grey,
                                  fontWeight: durationStr.isNotEmpty
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  color: theme.colorScheme.surface,
                  child: ListTile(
                    leading: Icon(
                      isBlockedByMe ? Icons.block : Icons.block_outlined,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      isBlockedByMe
                          ? 'Unblock ${_user.displayName}'
                          : 'Block ${_user.displayName}',
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
