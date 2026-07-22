import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/image_helper.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/theme_provider.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_entity.dart';

import '../auth/auth_notifier.dart';
import '../calls/call_notifier.dart';
import '../../core/services/service_providers.dart';
import 'chat_media_notifier.dart';
import 'chat_notifier.dart';
import 'chat_search_notifier.dart';
import '../profile/profile_notifier.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String receiverId;

  const ChatScreen({super.key, required this.receiverId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final FocusNode _messageFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  UserEntity? _receiverUser;
  bool _isNotesToSelf = false;
  bool _isRecording = false;
  String? _audioPath;
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;
  Timer? _typingDebouncer;
  Timer? _heartbeatTimer;
  MessageEntity? _replyingToMessage;
  int _lastMessageCount = 0;
  bool _showScrollToBottom = false;
  String? _highlightedMessageId;

  StreamSubscription<DocumentSnapshot>? _receiverSub;

  @override
  void initState() {
    super.initState();
    _isNotesToSelf = widget.receiverId == 'notes_to_self';
    _loadReceiverProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatNotifierProvider.notifier)
          .resetUnreadCount(widget.receiverId);
    });

    _startHeartbeat();

    _itemPositionsListener.itemPositions.addListener(() {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;
      final bottomItem = positions.where((p) => p.index == 0).firstOrNull;
      if (bottomItem != null && bottomItem.itemLeadingEdge < 0.1) {
        if (_showScrollToBottom) setState(() => _showScrollToBottom = false);
      } else {
        if (!_showScrollToBottom) setState(() => _showScrollToBottom = true);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(profileNotifierProvider.notifier).updateOnlinePresence(true);
    });
  }

  void _loadReceiverProfile() {
    if (_isNotesToSelf) return;
    _receiverSub = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(widget.receiverId)
        .snapshots()
        .listen((doc) {
          final data = doc.data();
          if (doc.exists && data != null && mounted) {
            setState(() {
              _receiverUser = UserEntity(
                uid: doc.id,
                email: data['email'] ?? '',
                username: data['username'] ?? '',
                displayName: data['displayName'] ?? 'User',
                profilePictureUrl: data['profilePictureUrl'] ?? '',
                about: data['about'] ?? '',
                isOnline: data['isOnline'] ?? false,
                lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
                publicKey: data['publicKey'] ?? '',
                blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
                pushToken: data['pushToken'] ?? '',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                lastSeenVisible: data['lastSeenVisible'] ?? true,
                disconnectRequested: data['disconnectRequested'] ?? false,
                connectedTo: data['connectedTo'] ?? '',
              );
            });
          }
        });
  }

  @override
  void dispose() {
    _receiverSub?.cancel();
    _messageController.dispose();
    _searchController.dispose();
    _audioRecorder.dispose();
    _messageFocusNode.dispose();
    _typingDebouncer?.cancel();
    _heartbeatTimer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  bool _hasText = false;

  void _onTextChanged(String text) {
    final hasTextNow = text.trim().isNotEmpty;
    if (hasTextNow != _hasText) {
      setState(() => _hasText = hasTextNow);
    }
    if (_isNotesToSelf) return;

    ref
        .read(chatNotifierProvider.notifier)
        .setTypingStatus(widget.receiverId, true);

    _typingDebouncer?.cancel();
    _typingDebouncer = Timer(const Duration(seconds: 2), () {
      ref
          .read(chatNotifierProvider.notifier)
          .setTypingStatus(widget.receiverId, false);
    });
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    ref
        .read(chatNotifierProvider.notifier)
        .setTypingStatus(widget.receiverId, false);

    final replyId = _replyingToMessage?.id ?? '';
    String replyContent = _replyingToMessage?.content ?? '';
    if (replyContent.isEmpty && _replyingToMessage != null) {
      switch (_replyingToMessage!.type) {
        case 'image': replyContent = '📷 Photo'; break;
        case 'video': replyContent = '🎬 Video'; break;
        case 'audio': replyContent = '🎵 Audio'; break;
        case 'document': replyContent = '📄 ${_replyingToMessage!.fileName}'; break;
        default: replyContent = _replyingToMessage!.fileName;
      }
    }
    setState(() {
      _replyingToMessage = null;
    });

    await ref
        .read(chatNotifierProvider.notifier)
        .sendTextMessage(
          receiverId: widget.receiverId,
          content: text,
          repliedToMessageId: replyId,
          repliedToMessageContent: replyContent,
        );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToMessage(String messageId, List<MessageEntity> messagesList) {
    final index = messagesList.indexWhere((m) => m.id == messageId);
    if (index == -1 || !_itemScrollController.isAttached) return;

    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );

    setState(() => _highlightedMessageId = messageId);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  Future<void> _startRecording() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      _audioPath =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: _audioPath!);
      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {});
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  void _sendLocation() {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    final msg = MessageEntity(
      id: const Uuid().v4(),
      senderId: currentUser.uid,
      receiverId: widget.receiverId,
      content: '37.422,-122.084',
      type: 'location',
      timestamp: DateTime.now(),
      status: 'sending',
    );
    ref.read(chatNotifierProvider.notifier).sendMessage(msg, widget.receiverId);
  }

  void _sendContact() {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    final msg = MessageEntity(
      id: const Uuid().v4(),
      senderId: currentUser.uid,
      receiverId: widget.receiverId,
      content: '${currentUser.displayName}\n${currentUser.email}',
      type: 'contact',
      timestamp: DateTime.now(),
      status: 'sending',
    );
    ref.read(chatNotifierProvider.notifier).sendMessage(msg, widget.receiverId);
  }

  Future<void> _stopRecording(bool shouldSend) async {
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
      });

      if (shouldSend && path != null && _recordingStartTime != null) {
        final duration = DateTime.now()
            .difference(_recordingStartTime!)
            .inSeconds;
        final int size;
        if (kIsWeb) {
          size = 0;
        } else {
          size = await File(path).length();
        }

        await ref
            .read(chatNotifierProvider.notifier)
            .sendFileMessage(
              receiverId: widget.receiverId,
              filePath: path,
              fileName:
                  'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
              fileSize: size,
              type: 'audio',
              duration: duration,
            );
        _scrollToBottom();
      }
    } catch (_) {}
  }
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final user = ref.read(authNotifierProvider).user;
      final int targetQuality = (user?.alwaysSendHD == true) ? 100 : 70;

      final pickedList = await picker.pickMultiImage(
        imageQuality: targetQuality,
      );

      for (var picked in pickedList) {
        final int size;
        if (kIsWeb) {
          size = 0;
        } else {
          size = await File(picked.path).length();
        }
        await ref
            .read(chatNotifierProvider.notifier)
            .sendFileMessage(
              receiverId: widget.receiverId,
              filePath: picked.path,
              fileName: picked.name,
              fileSize: size,
              type: 'image',
            );
      }
      if (pickedList.isNotEmpty) {
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final user = ref.read(authNotifierProvider).user;
      final int targetQuality = (user?.alwaysSendHD == true) ? 100 : 70;

      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: targetQuality,
      );

      if (picked != null) {
        final int size;
        if (kIsWeb) {
          size = 0;
        } else {
          size = await File(picked.path).length();
        }
        await ref
            .read(chatNotifierProvider.notifier)
            .sendFileMessage(
              receiverId: widget.receiverId,
              filePath: picked.path,
              fileName: picked.name,
              fileSize: size,
              type: 'image',
            );
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _pickGenericFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.path != null) {
            final size = file.size;
            final path = file.path!;
            String type = 'document';
            final ext = file.extension?.toLowerCase();
            if (ext == 'mp4' || ext == 'mov' || ext == 'mkv') {
              type = 'video';
            } else if (ext == 'mp3' || ext == 'wav' || ext == 'm4a') {
              type = 'audio';
            }

            await ref
                .read(chatNotifierProvider.notifier)
                .sendFileMessage(
                  receiverId: widget.receiverId,
                  filePath: path,
                  fileName: file.name,
                  fileSize: size,
                  type: type,
                );
          }
        }
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _handleDisconnect() async {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    final db = FirebaseFirestore.instance;
    final myDoc = db.collection('users').doc(currentUser.uid);
    final remoteDoc = db.collection('users').doc(widget.receiverId);

    if (!currentUser.disconnectRequested) {
      if (_receiverUser?.disconnectRequested == true) {
        final batch = db.batch();
        batch.update(myDoc, {'connectedTo': '', 'disconnectRequested': false});
        batch.update(remoteDoc, {
          'connectedTo': '',
          'disconnectRequested': false,
        });

        final chatId = ref
            .read(chatNotifierProvider.notifier)
            .getChatId(currentUser.uid, widget.receiverId);
        final chatDoc = db.collection('chats').doc(chatId);
        batch.update(chatDoc, {
          'isConnectionEstablished': false,
          'connectionRequestedBy': '',
        });

        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Disconnected successfully.')),
          );
          context.pop();
        }
      } else {
        await myDoc.update({'disconnectRequested': true});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Disconnect requested. Waiting for partner.'),
            ),
          );
        }
      }
    } else {

      await myDoc.update({'disconnectRequested': false});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnect request cancelled.')),
        );
      }
    }
  }

  Future<void> _handleLeaveChat() async {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    final db = FirebaseFirestore.instance;
    final myDoc = db.collection('users').doc(currentUser.uid);
    final remoteDoc = db.collection('users').doc(widget.receiverId);

    final batch = db.batch();
    if (currentUser.connectedTo == widget.receiverId) {
      batch.update(myDoc, {'connectedTo': '', 'disconnectRequested': false});
    }
    if (_receiverUser?.connectedTo == currentUser.uid) {
      batch.update(remoteDoc, {
        'connectedTo': '',
        'disconnectRequested': false,
      });
    }

    await batch.commit();
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _handleRequestConnection() async {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;
    final chatId = ref
        .read(chatNotifierProvider.notifier)
        .getChatId(currentUser.uid, widget.receiverId);
    final db = FirebaseFirestore.instance;
    await db.collection('chats').doc(chatId).update({
      'connectionRequestedBy': currentUser.uid,
    });
  }

  Future<void> _handleAcceptConnection() async {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    final db = FirebaseFirestore.instance;
    final chatId = ref
        .read(chatNotifierProvider.notifier)
        .getChatId(currentUser.uid, widget.receiverId);

    final myDoc = db.collection('users').doc(currentUser.uid);
    final remoteDoc = db.collection('users').doc(widget.receiverId);
    final chatDoc = db.collection('chats').doc(chatId);

    final batch = db.batch();

    batch.update(chatDoc, {
      'isConnectionEstablished': true,
      'connectionRequestedBy': '',
    });

    batch.update(myDoc, {
      'connectedTo': widget.receiverId,
      'disconnectRequested': false,
    });
    batch.update(remoteDoc, {
      'connectedTo': currentUser.uid,
      'disconnectRequested': false,
    });

    batch.update(myDoc, {
      'previouslyConnected': FieldValue.arrayUnion([widget.receiverId]),
    });
    batch.update(remoteDoc, {
      'previouslyConnected': FieldValue.arrayUnion([currentUser.uid]),
    });

    await batch.commit();
  }

  Widget _buildConnectionRequestUI(
    ThemeData theme,
    String requestedBy,
    String currentUid,
  ) {
    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Message Limit Reached',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have exchanged 5 messages. To continue chatting and unlock calls, you must establish a connection.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (requestedBy.isEmpty)
            ElevatedButton(
              onPressed: _handleRequestConnection,
              child: const Text('Request Connection'),
            )
          else if (requestedBy == currentUid)
            const Text(
              'Connection request sent. Waiting for partner...',
              style: TextStyle(fontStyle: FontStyle.italic),
            )
          else
            ElevatedButton(
              onPressed: _handleAcceptConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Accept Connection'),
            ),
        ],
      ),
    );
  }

  Widget _buildDisconnectRequestUI(ThemeData theme) {
    return Container(
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Disconnect Requested',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your partner has requested to disconnect. If you accept, the connection will be broken.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _handleDisconnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Accept Disconnect'),
          ),
        ],
      ),
    );
  }

  void _startWebRTCCall(bool isVideo) {
    if (_receiverUser == null) return;

    ref
        .read(callNotifierProvider.notifier)
        .makeCall(
          receiverId: _receiverUser!.uid,
          receiverName: _receiverUser!.displayName,
          isVideo: isVideo,
        );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider).user;
    final searchState = ref.watch(chatSearchProvider);
    final searchNotifier = ref.read(chatSearchProvider.notifier);

    final chatId = ref
        .read(chatNotifierProvider.notifier)
        .getChatId(currentUser?.uid ?? '', widget.receiverId);

    final advTheme = ref.watch(advancedThemeProvider(chatId));
    final globalThemeMode = ref.watch(themeModeProvider);
    final isDark =
        globalThemeMode == AppThemeType.dark ||
        globalThemeMode == AppThemeType.terminal ||
        globalThemeMode == AppThemeType.cyberpunk ||
        globalThemeMode == AppThemeType.oldPhone;

    final customThemeKeys = ['terminal', 'cyberpunk', 'oldphone', 'material3'];
    final useAdvancedThemeData = !customThemeKeys.contains(advTheme.id);

    final theme = useAdvancedThemeData
        ? advTheme.toThemeData(isDark ? Brightness.dark : Brightness.light)
        : Theme.of(context);

    final messagesAsync = ref.watch(chatMessagesProvider(chatId));

    final chatEntity = ref.watch(recentChatsProvider.select((chatsAsync) {
      return chatsAsync.value?.where((c) => c.id == chatId).firstOrNull;
    }));
    final streamMessages = messagesAsync.value ?? [];
    final pendingMessages = ref.watch(pendingMessagesProvider);
    final streamIds = streamMessages.map((m) => m.id).toSet();
    final unsyncedPending = pendingMessages.where((m) => !streamIds.contains(m.id)).toList();
    final mergedMessages = [...streamMessages, ...unsyncedPending];
    final messagesList = mergedMessages.reversed.toList();
    if (pendingMessages.isNotEmpty && unsyncedPending.length < pendingMessages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(pendingMessagesProvider.notifier).state = unsyncedPending;
        }
      });
    }
    final isConnectionEstablished =
        chatEntity?.isConnectionEstablished ?? false;
    final connectionRequestedBy = chatEntity?.connectionRequestedBy ?? '';
    final isOtherTyping =
        !_isNotesToSelf && chatEntity != null && _receiverUser != null
        ? (chatEntity.typingStatus[_receiverUser!.uid] ?? false)
        : false;

    final messageCount = mergedMessages.length;
    final limitReached = messageCount >= 5 && !isConnectionEstablished;

    final partnerRequestedDisconnect =
        _receiverUser?.disconnectRequested == true &&
        currentUser?.disconnectRequested == false;
    final isBlockedByMe =
        currentUser != null &&
        _receiverUser != null &&
        currentUser.blockedUsers.contains(_receiverUser!.uid);
    final isBlockedByThem =
        currentUser != null &&
        _receiverUser != null &&
        _receiverUser!.blockedUsers.contains(currentUser.uid);
    final isChatDisabled = isBlockedByMe || isBlockedByThem;
    final globalWallpaper = ref.read(hiveServiceProvider).getChatWallpaper();
    final wallpaperPath = useAdvancedThemeData
        ? (advTheme.backgroundTheme.wallpaperUrl ?? globalWallpaper)
        : globalWallpaper;

    final hidePhoto =
        currentUser?.hideContactPhotoInChat == true && !_isNotesToSelf;
    final hideName =
        currentUser?.hideContactNameInChat == true && !_isNotesToSelf;

    ref.listen<ChatSearchState>(chatSearchProvider, (prev, next) {
      if (next.isSearching &&
          next.currentMatchIndex != -1 &&
          next.matchIndices.isNotEmpty) {
        if (prev?.currentMatchIndex != next.currentMatchIndex ||
            prev?.query != next.query) {
          if (_itemScrollController.isAttached) {
            _itemScrollController.scrollTo(
              index: next.matchIndices[next.currentMatchIndex],
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    });

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: ChatAppBar(
          isNotesToSelf: _isNotesToSelf,
          receiverUser: _receiverUser,
          currentUser: currentUser,
          isOtherTyping: isOtherTyping,
          isChatDisabled: isChatDisabled,
          isConnectionEstablished: isConnectionEstablished,
          hidePhoto: hidePhoto,
          hideName: hideName,
          isSearching: searchState.isSearching,
          searchQuery: searchState.query,
          currentMatchIndex: searchState.currentMatchIndex,
          matchIndices: searchState.matchIndices,
          searchController: _searchController,
          onSearchChanged: (val) => searchNotifier.updateQuery(val, messagesList),
          onSearchSubmitted: (val) {
            if (val.trim().isNotEmpty) searchNotifier.addRecentSearch(val.trim());
          },
          onClearSearch: () {
            _searchController.clear();
            searchNotifier.updateQuery('', messagesList);
          },
          onStartSearch: () => searchNotifier.startSearch(),
          onStopSearch: () {
            _searchController.clear();
            searchNotifier.stopSearch();
          },
          onPreviousMatch: () => searchNotifier.previousMatch(),
          onNextMatch: () => searchNotifier.nextMatch(),
          onBack: () => context.pop(),
          onAudioCall: () => _startWebRTCCall(false),
          onVideoCall: () => _startWebRTCCall(true),
          onDisconnect: () async {
            if (isConnectionEstablished) {
              await _handleDisconnect();
            } else {
              await _handleLeaveChat();
            }
          },
          disconnectLabel: isConnectionEstablished
              ? (currentUser?.disconnectRequested == true
                    ? 'Cancel Disconnect Request'
                    : 'Request Disconnect')
              : 'Leave Chat',
        ),
        body: Container(
          decoration: wallpaperPath != null && !kIsWeb
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(wallpaperPath)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(
                        alpha: 0.5,
                      ),
                      BlendMode.darken,
                    ),
                  ),
                )
              : null,
          child: SafeArea(
            child: Column(
              children: [

                Expanded(
                  child: RepaintBoundary(
                    child: Stack(
                    children: [
                      Positioned.fill(
                        child: messagesAsync.when(
                          skipLoadingOnReload: true,
                          skipLoadingOnRefresh: true,
                          data: (messages) {
                            if (_lastMessageCount > 0 && messages.length > _lastMessageCount) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _scrollToBottom(),
                              );
                            }
                            _lastMessageCount = messages.length;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (currentUser?.readReceiptsEnabled ?? true) {
                                final unreadIds = messages
                                    .where(
                                      (m) =>
                                          m.senderId != currentUser?.uid &&
                                          m.status != 'read',
                                    )
                                    .map((m) => m.id)
                                    .toList();
                                if (unreadIds.isNotEmpty) {
                                  ref
                                      .read(chatNotifierProvider.notifier)
                                      .markAllAsRead(
                                        widget.receiverId,
                                        unreadIds,
                                      );
                                }
                              }
                            });

                            if (messagesList.isEmpty) {
                              return _buildEmptyChatInfo(theme);
                            }

                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => FocusScope.of(context).unfocus(),
                                  child: ScrollablePositionedList.builder(
                                    reverse: true,
                                    itemScrollController: _itemScrollController,
                                    itemPositionsListener:
                                        _itemPositionsListener,
                                    itemCount: messagesList.length,
                                    padding: const EdgeInsets.all(16),
                                    itemBuilder: (context, index) {
                                      final msg = messagesList[index];
                                      final isMe =
                                          msg.senderId == currentUser?.uid;

                                      return RepaintBoundary(
                                        child: MessageBubbleWidget(
                                          msg: msg,
                                          isMe: isMe,
                                          currentUser: currentUser,
                                          theme: theme,
                                          advTheme: advTheme,
                                          useAdvancedThemeData: useAdvancedThemeData,
                                          searchState: searchState,
                                          index: index,
                                          highlightedMessageId: _highlightedMessageId,
                                          messageFocusNode: _messageFocusNode,
                                          receiverId: widget.receiverId,
                                          receiverUser: _receiverUser,
                                          onReply: (msg) {
                                            setState(() {
                                              _replyingToMessage = msg;
                                            });
                                            if (mounted) {
                                              _messageFocusNode.requestFocus();
                                            }
                                          },
                                          onShowActions: _showMessageActions,
                                          onScrollToMessage: _scrollToMessage,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (searchState.isSearching &&
                                    searchState.query.isEmpty &&
                                    searchState.recentSearches.isNotEmpty)
                                  Positioned.fill(
                                    child: Container(
                                      color: theme.colorScheme.surface
                                          .withValues(alpha: 0.95),
                                      child: ListView.builder(
                                        itemCount:
                                            searchState.recentSearches.length,
                                        itemBuilder: (context, index) {
                                          final recentQuery =
                                              searchState.recentSearches[index];
                                          return ListTile(
                                            leading: const Icon(Icons.history),
                                            title: Text(recentQuery),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () => searchNotifier
                                                  .removeRecentSearch(
                                                    recentQuery,
                                                  ),
                                            ),
                                            onTap: () {
                                              _searchController.text =
                                                  recentQuery;
                                              searchNotifier.updateQuery(
                                                recentQuery,
                                                messagesList,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                          loading: () {
                            final cachedMsgs = ref.read(cachedMessagesProvider(chatId));
                            final pending = ref.read(pendingMessagesProvider);
                            final cachedIds = cachedMsgs.map((m) => m.id).toSet();
                            final extraPending = pending.where((m) => !cachedIds.contains(m.id)).toList();
                            final loadingMessages = [...cachedMsgs, ...extraPending].reversed.toList();

                            if (loadingMessages.isNotEmpty) {
                              return GestureDetector(
                                onTap: () => FocusScope.of(context).unfocus(),
                                child: ScrollablePositionedList.builder(
                                  reverse: true,
                                  itemScrollController: _itemScrollController,
                                  itemPositionsListener: _itemPositionsListener,
                                  itemCount: loadingMessages.length,
                                  padding: const EdgeInsets.all(16),
                                  itemBuilder: (context, index) {
                                    final msg = loadingMessages[index];
                                    final isMe = msg.senderId == currentUser?.uid;
                                    return MessageBubbleWidget(
                                      msg: msg,
                                      isMe: isMe,
                                      currentUser: currentUser,
                                      theme: theme,
                                      advTheme: advTheme,
                                      useAdvancedThemeData: useAdvancedThemeData,
                                      searchState: searchState,
                                      index: index,
                                      highlightedMessageId: _highlightedMessageId,
                                      messageFocusNode: _messageFocusNode,
                                      receiverId: widget.receiverId,
                                      receiverUser: _receiverUser,
                                      onReply: (msg) {
                                        setState(() {
                                          _replyingToMessage = msg;
                                        });
                                        if (mounted) {
                                          _messageFocusNode.requestFocus();
                                        }
                                      },
                                      onShowActions: _showMessageActions,
                                      onScrollToMessage: _scrollToMessage,
                                    );
                                  },
                                ),
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                          error: (err, stack) =>
                              Center(child: Text('Error: $err')),
                        ),
                      ),
                      if (_showScrollToBottom)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton.small(
                            onPressed: _scrollToBottom,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            elevation: 2,
                            child: Icon(
                              Icons.keyboard_double_arrow_down_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  ),
                ),
                if (_replyingToMessage != null) _buildReplyingBar(theme),
                if (isChatDisabled)
                  Container(
                    color: theme.colorScheme.surface,
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        isBlockedByMe
                            ? 'You have blocked this user'
                            : 'This contact is unavailable',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (limitReached)
                  _buildConnectionRequestUI(
                    theme,
                    connectionRequestedBy,
                    currentUser?.uid ?? '',
                  )
                else if (partnerRequestedDisconnect && isConnectionEstablished)
                  _buildDisconnectRequestUI(theme)
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer(
                        builder: (context, ref, _) {
                          final uploadProgress = ref.watch(chatNotifierProvider);
                          if (uploadProgress > 0 && uploadProgress < 1.0) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.cloud_upload_outlined, size: 16, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Uploading... ${(uploadProgress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: uploadProgress,
                                    minHeight: 3,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                  ),
                                ),
                              ],
                            );
                          } else if (uploadProgress == -1.0) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Upload failed',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      ChatInputBar(
                        theme: theme,
                        advTheme: advTheme,
                        useAdvancedThemeData: useAdvancedThemeData,
                        messageController: _messageController,
                        messageFocusNode: _messageFocusNode,
                        isRecording: _isRecording,
                        recordingStartTime: _recordingStartTime,
                        onSend: _sendText,
                        onStartRecording: _startRecording,
                        onStopRecording: _stopRecording,
                        onShowMediaOptions: () => _showMediaAttachmentOptions(theme),
                        onTextChanged: _onTextChanged,
                        hasText: _hasText,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChatInfo(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isNotesToSelf
                ? Icons.bookmark_border_rounded
                : Icons.lock_outline_rounded,
            size: 60,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            _isNotesToSelf ? 'Your Private Scratchpad' : 'End-to-End Encrypted',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              _isNotesToSelf
                  ? 'Save notes, links, files, and images here. Only you can access them.'
                  : 'Messages are locked with cryptographic keys. Nobody outside this chat can read them.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildReplyingBar(ThemeData theme) {
    final isImageReply = _replyingToMessage!.type == 'image';
    final isVideoReply = _replyingToMessage!.type == 'video';
    final isAudioReply = _replyingToMessage!.type == 'audio';

    String replyText;
    if (_replyingToMessage!.content.isNotEmpty) {
      replyText = _replyingToMessage!.content;
    } else if (isImageReply) {
      replyText = '📷 Photo';
    } else if (isVideoReply) {
      replyText = '🎬 Video';
    } else if (isAudioReply) {
      replyText = '🎵 Audio';
    } else {
      replyText = _replyingToMessage!.fileName;
    }

    return Container(
      key: const ValueKey('reply_bar'),
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (isImageReply && _replyingToMessage!.fileUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Base64Image(
                  base64String: _replyingToMessage!.fileUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (isImageReply && _replyingToMessage!.localFilePath.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.file(
                  File(_replyingToMessage!.localFilePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              replyText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _replyingToMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showMediaAttachmentOptions(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMediaButton(
                  icon: Icons.camera_alt,
                  color: Colors.pink,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(ctx);
                    _takePhoto();
                  },
                ),
                _buildMediaButton(
                  icon: Icons.image,
                  color: Colors.purple,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage();
                  },
                ),
                _buildMediaButton(
                  icon: Icons.insert_drive_file,
                  color: Colors.blue,
                  label: 'Document',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickGenericFile();
                  },
                ),
                _buildMediaButton(
                  icon: Icons.location_on,
                  color: Colors.green,
                  label: 'Location',
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendLocation();
                  },
                ),
                _buildMediaButton(
                  icon: Icons.person,
                  color: Colors.orange,
                  label: 'Contact',
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendContact();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showMessageActions(
    BuildContext context,
    MessageEntity msg,
    bool isMe,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final currentUser = ref.read(authNotifierProvider).user;
        final isStarred =
            currentUser != null && msg.starredBy.contains(currentUser.uid);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      ['❤️', '😂', '😮', '😢', '👍', '👎'].map((emoji) {
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(chatNotifierProvider.notifier)
                                .addReaction(widget.receiverId, msg.id, emoji);
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        );
                      }).toList()..add(
                        GestureDetector(
                          onTap: () {

                            ref
                                .read(chatNotifierProvider.notifier)
                                .addReaction(widget.receiverId, msg.id, '');
                            Navigator.pop(ctx);
                          },
                          child: const Icon(
                            Icons.remove_circle_outline,
                            size: 28,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  setState(() {
                    _replyingToMessage = msg;
                  });
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(isStarred ? Icons.star : Icons.star_border),
                title: Text(isStarred ? 'Unstar' : 'Star'),
                onTap: () {
                  ref
                      .read(chatNotifierProvider.notifier)
                      .toggleStar(widget.receiverId, msg.id, !isStarred);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Bookmark'),
                onTap: () {
                  ref
                      .read(chatMediaProvider(widget.receiverId).notifier)
                      .toggleBookmark(msg);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showForwardDialog(msg);
                },
              ),
              if (msg.type == 'text')
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.content));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showForwardDialog(MessageEntity msg) {
    showDialog(
      context: context,
      builder: (ctx) {
        final chats = ref.read(recentChatsProvider).value ?? [];
        final currentUser = ref.read(authNotifierProvider).user;
        final theme = Theme.of(context);
        if (currentUser == null) return const SizedBox.shrink();

        return AlertDialog(
          title: const Text('Forward to...'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherUserId = chat.isNotesToSelf
                    ? currentUser.uid
                    : chat.participants.firstWhere(
                        (id) => id != currentUser.uid,
                        orElse: () => '',
                      );
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      chat.isNotesToSelf ? Icons.bookmark : Icons.person,
                    ),
                  ),
                  title: Text(chat.isNotesToSelf ? 'Notes to self' : 'Contact'),
                  subtitle: Text(
                    chat.isNotesToSelf
                        ? 'Forward to your scratchpad'
                        : 'Forward message',
                  ),
                  onTap: () {
                    ref
                        .read(chatNotifierProvider.notifier)
                        .forwardMessage(
                          msg,
                          chat.isNotesToSelf ? 'notes_to_self' : otherUserId,
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message forwarded')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }
}
