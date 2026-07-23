import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/advanced_theme_model.dart';
import '../../../../core/widgets/image_viewer_screen.dart';
import '../../../../domain/entities/message_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../auth/auth_notifier.dart';
import '../../../../core/utils/image_helper.dart';
import '../audio_message_player.dart';
import '../chat_media_notifier.dart';
import '../chat_notifier.dart';
import '../chat_search_notifier.dart';

class MessageBubbleWidget extends ConsumerWidget {
  final MessageEntity msg;
  final bool isMe;
  final UserEntity? currentUser;
  final ThemeData theme;
  final AdvancedThemeModel advTheme;
  final bool useAdvancedThemeData;
  final ChatSearchState searchState;
  final int index;
  final String? highlightedMessageId;
  final FocusNode messageFocusNode;
  final String receiverId;
  final UserEntity? receiverUser;
  final Function(MessageEntity msg) onReply;
  final Function(BuildContext context, MessageEntity msg, bool isMe, ThemeData theme) onShowActions;
  final Function(String messageId, List<MessageEntity> messagesList) onScrollToMessage;

  const MessageBubbleWidget({
    super.key,
    required this.msg,
    required this.isMe,
    required this.currentUser,
    required this.theme,
    required this.advTheme,
    required this.useAdvancedThemeData,
    required this.searchState,
    required this.index,
    required this.highlightedMessageId,
    required this.messageFocusNode,
    required this.receiverId,
    required this.receiverUser,
    required this.onReply,
    required this.onShowActions,
    required this.onScrollToMessage,
  });

  bool _containsLink(String text) {
    return RegExp(r'(https?:\/\/[^\s]+)').hasMatch(text);
  }

  String _extractLink(String text) {
    final match = RegExp(r'(https?:\/\/[^\s]+)').firstMatch(text);
    final raw = match?.group(0) ?? '';
    if (raw.isEmpty) return '';
    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return '';
    }
    return raw;
  }

  Future<void> _openLocation(String latLng) async {
    if (!RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(latLng)) {
      return;
    }
    final url = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': latLng},
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    bool isCurrentMatch,
    Color textColor,
  ) {
    if (query.isEmpty) {
      return Text(text, style: TextStyle(color: textColor, fontSize: 15));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(
          TextSpan(
            text: text.substring(start),
            style: TextStyle(color: textColor, fontSize: 15),
          ),
        );
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: TextStyle(color: textColor, fontSize: 15),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            color: Colors.black,
            backgroundColor: isCurrentMatch ? Colors.deepOrange : Colors.yellow,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildMessageStatusIcon(
    String status,
    bool showBlueTicks,
    ThemeData theme, {
    Color? statusColor,
  }) {
    final iconColor = statusColor ?? theme.colorScheme.onSurface.withOpacity(0.7);
    const double iconSize = 14;
    if (status == 'sending') {
      return Icon(Icons.access_time, size: iconSize, color: iconColor);
    }
    if (status == 'sent') {
      return Icon(Icons.check, size: iconSize, color: iconColor);
    }
    if (status == 'delivered' || (status == 'read' && !showBlueTicks)) {
      return Icon(Icons.done_all, size: iconSize, color: iconColor);
    }
    if (status == 'read') {
      return Icon(Icons.done_all, size: iconSize, color: theme.colorScheme.primary);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isMatch =
        searchState.isSearching && searchState.matchIndices.contains(index);
    bool isCurrentMatch =
        isMatch &&
        searchState.matchIndices.isNotEmpty &&
        searchState.currentMatchIndex != -1 &&
        searchState.matchIndices[searchState.currentMatchIndex] == index;

    final bubbleConf = isMe ? advTheme.senderBubble : advTheme.receiverBubble;

    Color baseBubbleColor = Color(bubbleConf.backgroundColor);

    if (isMatch && searchState.isFuzzy) {
      baseBubbleColor = isCurrentMatch ? Colors.deepOrange : Colors.orange;
    }

    final bubbleColor = baseBubbleColor;

    final colorValue = isMe
        ? advTheme.textTheme.senderMessageColor
        : advTheme.textTheme.receiverMessageColor;
    final textColor = Color(colorValue);

    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    double radiusTopLeft = bubbleConf.radiusTopLeft;
    double radiusTopRight = bubbleConf.radiusTopRight;
    double radiusBottomLeft = bubbleConf.radiusBottomLeft;
    double radiusBottomRight = bubbleConf.radiusBottomRight;

    return _SwipeToReply(
      key: ValueKey(msg.id),
      isMe: isMe,
      focusNode: messageFocusNode,
      onReply: () {
        onReply(msg);
        messageFocusNode.requestFocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            GestureDetector(
              onLongPress: () => onShowActions(context, msg, isMe, theme),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: highlightedMessageId == msg.id
                      ? (isMe ? bubbleColor.withValues(alpha: 0.6) : theme.colorScheme.primaryContainer.withValues(alpha: 0.5))
                      : bubbleColor,
                  border: highlightedMessageId == msg.id
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : bubbleConf.borderWidth > 0
                          ? Border.all(color: Color(bubbleConf.borderColor), width: bubbleConf.borderWidth)
                          : null,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radiusTopLeft),
                    topRight: Radius.circular(radiusTopRight),
                    bottomLeft: Radius.circular(radiusBottomLeft),
                    bottomRight: Radius.circular(radiusBottomRight),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: bubbleConf.paddingHorizontal,
                  vertical: bubbleConf.paddingVertical,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.isForwarded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.forward,
                              size: 12,
                              color: isMe
                                  ? textColor.withValues(alpha: 0.7)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Forwarded',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isMe
                                    ? textColor.withValues(alpha: 0.7)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (msg.repliedToMessageId.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          final messagesAsync = ref.read(chatMessagesProvider(
                            ref.read(chatNotifierProvider.notifier)
                                .getChatId(
                              ref.read(authNotifierProvider).user!.uid,
                              receiverId,
                            ),
                          ));
                          final streamMsgs = messagesAsync.value ?? [];
                          final pending = ref.read(pendingMessagesProvider);
                          final ids = streamMsgs.map((m) => m.id).toSet();
                          final extra = pending.where((m) => !ids.contains(m.id)).toList();
                          final allMsgs = [...streamMsgs, ...extra].reversed.toList();
                          onScrollToMessage(msg.repliedToMessageId, allMsgs);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 3,
                                height: 28,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Flexible(
                                child: Builder(
                                  builder: (context) {
                                    final chatId = ref.read(chatNotifierProvider.notifier)
                                        .getChatId(ref.read(authNotifierProvider).user!.uid, receiverId);
                                    final allMsgs = ref.read(chatMessagesProvider(chatId)).value ?? [];
                                    final repliedMsg = allMsgs.where((m) => m.id == msg.repliedToMessageId).firstOrNull;
                                    final isImageReply = repliedMsg?.type == 'image' && (repliedMsg!.fileUrl.isNotEmpty);

                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            msg.repliedToMessageContent,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: isMe
                                                  ? textColor.withValues(alpha: 0.8)
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                        if (isImageReply) ...[
                                          const SizedBox(width: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: Base64Image(
                                                base64String: repliedMsg.fileUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (msg.type == 'image')
                      GestureDetector(
                        onTap: msg.fileUrl.isNotEmpty
                            ? () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder: (context, animation, secondaryAnimation) => ImageViewerScreen(
                                      base64String: msg.fileUrl,
                                      senderName: isMe
                                          ? 'You'
                                          : (receiverUser?.displayName ?? 'User'),
                                      timestamp: msg.timestamp,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: msg.fileUrl.isNotEmpty
                              ? ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 250,
                                    maxHeight: 300,
                                    minWidth: 150,
                                    minHeight: 150,
                                  ),
                                  child: Base64Image(
                                    key: ValueKey(msg.fileUrl),
                                    base64String: msg.fileUrl,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : msg.localFilePath.isNotEmpty
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.file(
                                          File(msg.localFilePath),
                                          fit: BoxFit.cover,
                                          width: 220,
                                          height: 220,
                                          errorBuilder: (_, __, ___) => const SizedBox(
                                            width: 220,
                                            height: 220,
                                            child: Icon(Icons.broken_image, size: 48),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.black45,
                                            child: Consumer(
                                              builder: (context, ref, _) {
                                                final progress = ref.watch(chatNotifierProvider);
                                                return Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 48,
                                                      height: 48,
                                                      child: CircularProgressIndicator(
                                                        value: progress > 0 && progress < 1.0 ? progress : null,
                                                        strokeWidth: 3,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    if (progress > 0 && progress < 1.0) ...[
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        '${(progress * 100).toInt()}%',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox(
                                      width: 220,
                                      height: 220,
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                        ),
                      )
                    else if (msg.type == 'audio')
                      AudioMessagePlayer(
                        audioUrl: msg.fileUrl,
                        duration: msg.duration,
                        isSender: isMe,
                      )
                    else if (msg.type == 'document' || msg.type == 'video')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            msg.type == 'video'
                                ? Icons.video_file
                                : Icons.insert_drive_file,
                            color: isMe ? textColor : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${(msg.fileSize / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? textColor.withValues(alpha: 0.7)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.download,
                              color: isMe ? textColor : null,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      )
                    else if (msg.type == 'location')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: isMe
                                    ? textColor
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Location Shared',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _openLocation(msg.content),
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('Open in Maps'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: isMe
                                  ? theme.colorScheme.primary
                                  : textColor,
                              backgroundColor: isMe
                                  ? textColor
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      )
                    else if (msg.type == 'contact')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundColor: isMe
                                ? textColor.withValues(alpha: 0.24)
                                : theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person,
                              color: isMe
                                  ? textColor
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.content.split('\n').first,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg.content.split('\n').length > 1
                                    ? msg.content.split('\n').last
                                    : '',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMatch &&
                              !searchState.isFuzzy &&
                              searchState.query.isNotEmpty)
                            _buildHighlightedText(
                              msg.content,
                              searchState.query,
                              isCurrentMatch,
                              textColor,
                            )
                          else
                            Text(
                              msg.content,
                              style: TextStyle(color: textColor, fontSize: 15),
                            ),
                          if (msg.type == 'text' &&
                              _containsLink(msg.content)) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: AnyLinkPreview(
                                link: _extractLink(msg.content),
                                displayDirection:
                                    UIDirection.uiDirectionHorizontal,
                                backgroundColor: isMe
                                    ? Colors.white12
                                    : theme.colorScheme.surfaceContainerHighest,
                                bodyStyle: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                ),
                                titleStyle: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                errorWidget: const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (msg.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Wrap(
                  spacing: 4,
                  children: msg.reactions.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        e.value,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(msg.timestamp),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildMessageStatusIcon(
                    msg.status,
                    (currentUser?.readReceiptsEnabled ?? true) &&
                        (receiverUser?.readReceiptsEnabled ?? true),
                    theme,
                    statusColor: Color(advTheme.textTheme.timestampColor),
                  ),
                ],
                if (currentUser != null &&
                    msg.starredBy.contains(currentUser!.uid)) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 12, color: Colors.grey),
                ],
                if (ref
                    .watch(chatMediaProvider(receiverId))
                    .bookmarkedIds
                    .contains(msg.id)) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.bookmark, size: 12, color: Colors.grey),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool isMe;
  final FocusNode? focusNode;

  const _SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    required this.isMe,
    this.focusNode,
  });

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0;
  bool _hasTriggeredHaptic = false;

  static const double _replyThreshold = 60.0;
  static const double _maxDrag = 100.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    setState(() {
      if (widget.isMe) {
        _dragExtent = (_dragExtent - delta).clamp(0.0, _maxDrag);
      } else {
        _dragExtent = (_dragExtent + delta).clamp(0.0, _maxDrag);
      }
    });

    if (_dragExtent >= _replyThreshold && !_hasTriggeredHaptic) {
      HapticFeedback.mediumImpact();
      _hasTriggeredHaptic = true;
    } else if (_dragExtent < _replyThreshold) {
      _hasTriggeredHaptic = false;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragExtent >= _replyThreshold) {
      widget.onReply();
    }

    _animation = Tween<double>(
      begin: _dragExtent,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragExtent = 0;
          _hasTriggeredHaptic = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_dragExtent / _replyThreshold).clamp(0.0, 1.0);
    final translateX = widget.isMe ? -_dragExtent : _dragExtent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          Positioned(
            left: widget.isMe ? null : 8,
            right: widget.isMe ? 8 : null,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.5 + (progress * 0.5),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.reply_rounded,
                      size: 20,
                      color: _hasTriggeredHaptic
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dx = _controller.isAnimating
                  ? (widget.isMe ? -_animation.value : _animation.value)
                  : translateX;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: SizedBox(width: double.infinity, child: widget.child),
          ),
        ],
      ),
    );
  }
}
