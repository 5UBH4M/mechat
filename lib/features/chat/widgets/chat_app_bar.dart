import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/image_helper.dart';
import '../../../domain/entities/user_entity.dart';
import '../user_info_screen.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isNotesToSelf;
  final UserEntity? receiverUser;
  final UserEntity? currentUser;
  final bool isOtherTyping;
  final bool isConnectionEstablished;
  final bool hidePhoto;
  final bool hideName;
  final bool isSearching;
  final String searchQuery;
  final int currentMatchIndex;
  final List<int> matchIndices;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final VoidCallback onStartSearch;
  final VoidCallback onStopSearch;
  final VoidCallback onPreviousMatch;
  final VoidCallback onNextMatch;
  final VoidCallback onBack;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;
  final VoidCallback onDisconnect;
  final String disconnectLabel;

  const ChatAppBar({
    super.key,
    required this.isNotesToSelf,
    required this.receiverUser,
    required this.currentUser,
    required this.isOtherTyping,
    required this.isConnectionEstablished,
    required this.hidePhoto,
    required this.hideName,
    required this.isSearching,
    required this.searchQuery,
    required this.currentMatchIndex,
    required this.matchIndices,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onStartSearch,
    required this.onStopSearch,
    required this.onPreviousMatch,
    required this.onNextMatch,
    required this.onBack,
    required this.onAudioCall,
    required this.onVideoCall,
    required this.onDisconnect,
    required this.disconnectLabel,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: onBack,
        ),
      ),
      title: isSearching ? _buildSearchTitle(theme) : _buildChatTitle(context, theme),
      actions: isSearching
          ? [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onStopSearch,
              ),
            ]
          : _buildActions(theme),
    );
  }

  Widget _buildSearchTitle(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            autofocus: true,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search messages...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
            onChanged: onSearchChanged,
            onSubmitted: onSearchSubmitted,
          ),
        ),
        if (searchQuery.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
                icon: const Icon(Icons.clear, size: 20),
                onPressed: onClearSearch,
              ),
              if (matchIndices.isNotEmpty && currentMatchIndex != -1)
                Text(
                  '${currentMatchIndex + 1} / ${matchIndices.length}',
                  style: const TextStyle(fontSize: 12),
                ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: onPreviousMatch,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: onNextMatch,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildChatTitle(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        GestureDetector(
          onTap: (!isNotesToSelf && receiverUser != null)
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserInfoScreen(user: receiverUser!),
                    ),
                  );
                }
              : null,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: isNotesToSelf || hidePhoto
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.colorScheme.surface,
            backgroundImage:
                isNotesToSelf || receiverUser == null || hidePhoto
                ? null
                : (receiverUser!.profilePictureUrl.isNotEmpty
                      ? getBase64ImageProvider(
                          receiverUser!.profilePictureUrl,
                        )
                      : null),
            child: isNotesToSelf
                ? Icon(
                    Icons.bookmark_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  )
                : (hidePhoto ||
                          receiverUser == null ||
                          receiverUser!.profilePictureUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 20,
                        )
                      : null),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNotesToSelf
                    ? AppConstants.notesToSelfName
                    : (hideName
                          ? 'Contact'
                          : (receiverUser?.displayName ?? 'Loading...')),
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              if (!isNotesToSelf && receiverUser != null)
                _buildStatusText(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(ThemeData theme) {
    if (isOtherTyping) {
      return Text(
        'typing...',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 11,
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final bothAllowLastSeen =
        currentUser != null &&
        currentUser!.lastSeenVisible &&
        receiverUser!.lastSeenVisible;
    if (!bothAllowLastSeen) return const SizedBox.shrink();

    final isOnlineNow = receiverUser!.isOnline &&
        DateTime.now().difference(receiverUser!.lastSeen).inSeconds < 180;

    return Text(
      isOnlineNow
          ? 'online'
          : 'last seen ${DateFormatter.formatShort(receiverUser!.lastSeen)}',
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 11,
        color: isOnlineNow ? Colors.green : null,
        fontWeight: isOnlineNow ? FontWeight.bold : null,
      ),
    );
  }

  List<Widget> _buildActions(ThemeData theme) {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: onStartSearch,
      ),
      if (!isNotesToSelf &&
          receiverUser != null &&
          isConnectionEstablished) ...[
        IconButton(
          icon: const Icon(Icons.call_rounded),
          onPressed: onAudioCall,
        ),
        IconButton(
          icon: const Icon(Icons.videocam_rounded),
          onPressed: onVideoCall,
        ),
      ],
      if (!isNotesToSelf)
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'disconnect') onDisconnect();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'disconnect',
              child: Text(disconnectLabel),
            ),
          ],
        ),
    ];
  }
}
