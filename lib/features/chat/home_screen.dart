import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/image_helper.dart';
import '../../domain/entities/chat_entity.dart';
import '../auth/auth_notifier.dart';
import '../calls/call_notifier.dart';
import '../profile/profile_notifier.dart';
import 'chat_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set user online
    ref.read(profileNotifierProvider.notifier).updateOnlinePresence(true);
    // Sync offline queue if items exist
    ref.read(chatNotifierProvider.notifier).syncOffline();
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(profileNotifierProvider.notifier).updateOnlinePresence(true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      ref.read(profileNotifierProvider.notifier).updateOnlinePresence(true);
      ref.read(chatNotifierProvider.notifier).syncOffline();
      _startHeartbeat();
    } else {
      _heartbeatTimer?.cancel();
      ref.read(profileNotifierProvider.notifier).updateOnlinePresence(false);
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatsAsync = ref.watch(recentChatsProvider);
    final currentUser = ref.watch(authNotifierProvider).user;

    // Call state listener: redirect to call page if status ringing, dialing or connected
    ref.listen<CallState>(callNotifierProvider, (previous, next) {
      if (previous?.status != next.status) {
        if (next.status == 'ringing') {
          context.push('/incoming-call');
        } else if (next.status == 'dialing' || next.status == 'connected') {
          // Avoid pushing again if already connected or if we were dialing and are now connected
          if (previous?.status != 'dialing') {
            context.push('/ongoing-call');
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'MeChat',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color:
                    theme.appBarTheme.titleTextStyle?.color ??
                    theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Toggle search bar expansion
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Elegant Search Input
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
              ),
            ),
          ),

          Expanded(
            child: chatsAsync.when(
              data: (chats) {
                // Filter based on search query
                final filteredChats = chats.where((chat) {
                  if (chat.isNotesToSelf) return false;
                  if (_searchQuery.isEmpty) return true;
                  return chat.id.toLowerCase().contains(_searchQuery) ||
                      (chat.lastMessage?.content.toLowerCase().contains(
                            _searchQuery,
                          ) ??
                          false);
                }).toList();

                if (filteredChats.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return ListView.separated(
                  itemCount: filteredChats.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 80,
                    endIndent: 16,
                    color: Color(0x1F808080),
                  ),
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];
                    return _buildChatItem(
                      context,
                      chat,
                      currentUser?.uid,
                      theme,
                    );
                  },
                );
              },
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'MeChat',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'developed by ~ Subham 🤍',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              error: (err, stack) =>
                  Center(child: Text('Error loading chats: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => context.push('/contacts'),
        child: const Icon(Icons.chat_bubble_rounded),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search a user to start direct messaging',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    ChatEntity chat,
    String? currentUid,
    ThemeData theme,
  ) {
    // Determine the user's name/avatar.
    // For 'Notes to Self', we display customizable header.
    // For general participants, we resolve from participants.
    final isNotes = chat.isNotesToSelf;
    final otherUid = chat.participants.firstWhere(
      (id) => id != currentUid,
      orElse: () => currentUid ?? '',
    );

    final int unreadCount = currentUid != null
        ? (chat.unreadCounts[currentUid] ?? 0)
        : 0;
    final bool isTyping = currentUid != null
        ? (chat.typingStatus[otherUid] ?? false)
        : false;

    if (isNotes) {
      return _buildTile(
        context,
        chat,
        theme,
        currentUid,
        otherUid,
        'Notes to Self',
        true,
        '',
        unreadCount,
        isTyping,
        false,
      );
    }

    // Resolve user data dynamically using StreamBuilder for real-time online status
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .snapshots(),
      builder: (context, snapshot) {
        String displayName = 'Loading...';
        String avatarUrl = '';
        bool isOnline = false;
        DateTime lastSeen = DateTime.now();
        bool lastSeenVisible = true;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            displayName = data['displayName'] ?? 'Unknown User';
            avatarUrl = data['profilePictureUrl'] ?? '';
            isOnline = data['isOnline'] ?? false;
            lastSeen =
                (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now();
            lastSeenVisible = data['lastSeenVisible'] ?? true;
          }
        }

        // Determine if user is truly online (isOnline flag AND heartbeat within 90 seconds)
        final currentUser = ref.read(authNotifierProvider).user;
        final bothAllowLastSeen =
            currentUser != null &&
            currentUser.lastSeenVisible &&
            lastSeenVisible;
        final isActuallyOnline =
            isOnline && DateTime.now().difference(lastSeen).inSeconds < 90;
        final showOnlineIndicator = bothAllowLastSeen && isActuallyOnline;

        return _buildTile(
          context,
          chat,
          theme,
          currentUid,
          otherUid,
          displayName,
          false,
          avatarUrl,
          unreadCount,
          isTyping,
          showOnlineIndicator,
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    ChatEntity chat,
    ThemeData theme,
    String? currentUid,
    String otherUid,
    String displayName,
    bool isNotes,
    String avatarUrl,
    int unreadCount,
    bool isTyping,
    bool showOnlineIndicator,
  ) {
    return ListTile(
      onTap: () async {
        final currentUser = ref.read(authNotifierProvider).user;
        if (currentUser == null) return;

        if (currentUser.connectedTo.isNotEmpty &&
            currentUser.connectedTo != otherUid) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'You are already connected to someone else. Please disconnect first.',
                ),
              ),
            );
          }
          return;
        }

        // Check if other user is connected to someone else
        final otherUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUid)
            .get();
        if (otherUserDoc.exists) {
          final otherConnectedTo = otherUserDoc.data()?['connectedTo'] ?? '';
          if (otherConnectedTo.isNotEmpty &&
              otherConnectedTo != currentUser.uid) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User is already connected to someone else.'),
                ),
              );
            }
            return;
          }
        }

        if (context.mounted) {
          context.push('/chat/$otherUid');
        }
      },
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: isNotes
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.colorScheme.surface,
            backgroundImage: avatarUrl.isNotEmpty
                ? getBase64ImageProvider(avatarUrl)
                : null,
            child: isNotes
                ? Icon(Icons.bookmark_rounded, color: theme.colorScheme.primary)
                : (avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null),
          ),
          if (!isNotes && showOnlineIndicator)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green, // Visual indicator online
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            displayName,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
          ),
          if (chat.lastMessage != null)
            Text(
              DateFormatter.formatShort(chat.lastMessage!.timestamp),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Expanded(
              child: isTyping
                  ? Text(
                      'typing...',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Text(
                      chat.lastMessage?.content ?? 'Tap to start conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: unreadCount > 0
                            ? theme.colorScheme.onSurface
                            : null,
                        fontWeight: unreadCount > 0 ? FontWeight.bold : null,
                      ),
                    ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
