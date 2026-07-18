import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/image_helper.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/advanced_theme_model.dart';
import '../../core/widgets/image_viewer_screen.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_entity.dart';

import '../auth/auth_notifier.dart';
import '../calls/call_notifier.dart';
import '../../core/services/service_providers.dart';
import 'audio_message_player.dart';
import 'chat_media_notifier.dart';
import 'chat_notifier.dart';
import 'chat_search_notifier.dart';
import '../profile/profile_notifier.dart';
import 'user_info_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String receiverId; // Can be 'notes_to_self' or a real UID

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
          if (doc.exists && doc.data() != null) {
            if (mounted) {
              setState(() {
                _receiverUser = UserEntity(
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
                );
              });
            }
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

  void _onTextChanged(String text) {
    setState(() {}); // Rebuild to toggle mic/send button
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
    final replyContent = _replyingToMessage?.content ?? '';
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



  // --- Voice Message Recording ---
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
    // Validate that latLng matches a valid coordinate pattern before use.
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

  void _sendLocation() {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    final msg = MessageEntity(
      id: const Uuid().v4(),
      senderId: currentUser.uid,
      receiverId: widget.receiverId,
      content: '37.422,-122.084', // Mock coordinates for Googleplex
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
      content: 'John Doe\n+1 234 567 8900', // Mock contact
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

  // --- Media Uploading ---
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

            // Determine type based on extension
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
        // Mutual disconnect!
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
      // Cancel disconnect
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

    // Update Chat status
    batch.update(chatDoc, {
      'isConnectionEstablished': true,
      'connectionRequestedBy': '',
    });

    // Lock both users
    batch.update(myDoc, {
      'connectedTo': widget.receiverId,
      'disconnectRequested': false,
    });
    batch.update(remoteDoc, {
      'connectedTo': currentUser.uid,
      'disconnectRequested': false,
    });

    // Add to previouslyConnected
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

  // --- Call Launcher Helpers ---
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
    final chatsAsync = ref.watch(recentChatsProvider);

    // Merge stream messages with optimistic pending messages
    final streamMessages = messagesAsync.value ?? [];
    final pendingMessages = ref.watch(pendingMessagesProvider);
    final streamIds = streamMessages.map((m) => m.id).toSet();
    final unsyncedPending = pendingMessages.where((m) => !streamIds.contains(m.id)).toList();
    final mergedMessages = [...streamMessages, ...unsyncedPending];
    final messagesList = mergedMessages.reversed.toList();

    // Auto-clean pending messages that have been confirmed by the stream
    if (pendingMessages.isNotEmpty && unsyncedPending.length < pendingMessages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(pendingMessagesProvider.notifier).state = unsyncedPending;
        }
      });
    }

    // Find the chat entity if it exists
    final chatEntity = chatsAsync.value
        ?.where((c) => c.id == chatId)
        .firstOrNull;
    final isConnectionEstablished =
        chatEntity?.isConnectionEstablished ?? false;
    final connectionRequestedBy = chatEntity?.connectionRequestedBy ?? '';

    // Check if the other user is typing
    final isOtherTyping =
        !_isNotesToSelf && chatEntity != null && _receiverUser != null
        ? (chatEntity.typingStatus[_receiverUser!.uid] ?? false)
        : false;

    final messageCount = mergedMessages.length;
    final limitReached = messageCount >= 5 && !isConnectionEstablished;

    final partnerRequestedDisconnect =
        _receiverUser?.disconnectRequested == true &&
        currentUser?.disconnectRequested == false;

    // Determine Block states
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
        appBar: AppBar(
          leadingWidth: 40,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          title: searchState.isSearching
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search messages...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          searchNotifier.updateQuery(val, messagesList);
                        },
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            searchNotifier.addRecentSearch(val.trim());
                          }
                        },
                      ),
                    ),
                    if (searchState.query.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32),
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              searchNotifier.updateQuery('', messagesList);
                            },
                          ),
                          if (searchState.matchIndices.isNotEmpty &&
                              searchState.currentMatchIndex != -1)
                            Text(
                              '${searchState.currentMatchIndex + 1} / ${searchState.matchIndices.length}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32),
                            icon: const Icon(Icons.keyboard_arrow_up),
                            onPressed: () {
                              searchNotifier.previousMatch();
                            },
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onPressed: () {
                              searchNotifier.nextMatch();
                            },
                          ),
                        ],
                      ),
                  ],
                )
              : Row(
                  children: [
                    GestureDetector(
                      onTap: (!_isNotesToSelf && _receiverUser != null)
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserInfoScreen(user: _receiverUser!),
                                ),
                              );
                            }
                          : null,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: _isNotesToSelf || hidePhoto
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : theme.colorScheme.surface,
                        backgroundImage:
                            _isNotesToSelf || _receiverUser == null || hidePhoto
                            ? null
                            : (_receiverUser!.profilePictureUrl.isNotEmpty
                                  ? getBase64ImageProvider(
                                      _receiverUser!.profilePictureUrl,
                                    )
                                  : null),
                        child: _isNotesToSelf
                            ? Icon(
                                Icons.bookmark_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              )
                            : (hidePhoto ||
                                      _receiverUser == null ||
                                      _receiverUser!.profilePictureUrl.isEmpty
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
                            _isNotesToSelf
                                ? AppConstants.notesToSelfName
                                : (hideName
                                      ? 'Contact'
                                      : (_receiverUser?.displayName ??
                                            'Loading...')),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          if (!_isNotesToSelf && _receiverUser != null)
                            Builder(
                              builder: (context) {
                                // Show typing indicator first, then online/last seen
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
                                    currentUser.lastSeenVisible &&
                                    _receiverUser!.lastSeenVisible;
                                if (!bothAllowLastSeen) {
                                  return const SizedBox.shrink(); // Hide last seen and online status if either disabled
                                }
                                return Text(
                                  (_receiverUser!.isOnline &&
                                          DateTime.now()
                                                  .difference(
                                                    _receiverUser!.lastSeen,
                                                  )
                                                  .inSeconds <
                                              90)
                                      ? 'online'
                                      : 'last seen ${DateFormatter.formatShort(_receiverUser!.lastSeen)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
                                    color:
                                        (_receiverUser!.isOnline &&
                                            DateTime.now()
                                                    .difference(
                                                      _receiverUser!.lastSeen,
                                                    )
                                                    .inSeconds <
                                                90)
                                        ? Colors.green
                                        : null,
                                    fontWeight:
                                        (_receiverUser!.isOnline &&
                                            DateTime.now()
                                                    .difference(
                                                      _receiverUser!.lastSeen,
                                                    )
                                                    .inSeconds <
                                                90)
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
          actions: searchState.isSearching
              ? [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      searchNotifier.stopSearch();
                    },
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      searchNotifier.startSearch();
                    },
                  ),

                  if (!_isNotesToSelf &&
                      _receiverUser != null &&
                      !isChatDisabled &&
                      isConnectionEstablished) ...[
                    IconButton(
                      icon: const Icon(Icons.call_rounded),
                      onPressed: () => _startWebRTCCall(false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam_rounded),
                      onPressed: () => _startWebRTCCall(true),
                    ),
                  ],
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) async {
                      if (value == 'disconnect') {
                        if (isConnectionEstablished) {
                          await _handleDisconnect();
                        } else {
                          // Simply leave chat and clear connectedTo
                          await _handleLeaveChat();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      if (!_isNotesToSelf)
                        PopupMenuItem(
                          value: 'disconnect',
                          child: Text(
                            isConnectionEstablished
                                ? (currentUser?.disconnectRequested == true
                                      ? 'Cancel Disconnect Request'
                                      : 'Request Disconnect')
                                : 'Leave Chat',
                          ),
                        ),
                    ],
                  ),
                ],
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
                      ), // Dim the wallpaper slightly for readability
                      BlendMode.darken,
                    ),
                  ),
                )
              : null,
          child: SafeArea(
            child: Column(
              children: [
                // Message List Area
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: messagesAsync.when(
                          data: (messages) {
                            // Only auto-scroll when new messages arrive, not on every rebuild
                            if (messages.length > _lastMessageCount) {
                              _lastMessageCount = messages.length;
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _scrollToBottom(),
                              );
                            }

                            // Batch update read status to prevent scrolling lag
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

                                      return _buildMessageBubble(
                                        context,
                                        msg,
                                        isMe,
                                        currentUser,
                                        theme,
                                        advTheme,
                                        useAdvancedThemeData,
                                        searchState,
                                        index,
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
                            // Read cached messages from Hive directly
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
                                    return _buildMessageBubble(
                                      context, msg, isMe, currentUser,
                                      theme, advTheme, useAdvancedThemeData,
                                      searchState, index,
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

                // Replying To Preview Bar
                if (_replyingToMessage != null) _buildReplyingBar(theme),

                // Input Bar Area
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
                      _buildInputBar(theme, advTheme, useAdvancedThemeData),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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

  // Message Bubble construction
  Widget _buildMessageBubble(
    BuildContext context,
    MessageEntity msg,
    bool isMe,
    UserEntity? currentUser,
    ThemeData theme,
    AdvancedThemeModel advTheme,
    bool useAdvancedThemeData,
    ChatSearchState searchState,
    int index,
  ) {
    bool isMatch =
        searchState.isSearching && searchState.matchIndices.contains(index);
    bool isCurrentMatch =
        isMatch &&
        searchState.matchIndices.isNotEmpty &&
        searchState.currentMatchIndex != -1 &&
        searchState.matchIndices[searchState.currentMatchIndex] == index;

    final bubbleConf = isMe ? advTheme.senderBubble : advTheme.receiverBubble;

    Color baseBubbleColor;
    if (useAdvancedThemeData) {
      baseBubbleColor = Color(bubbleConf.backgroundColor);
    } else {
      baseBubbleColor = isMe
          ? theme.colorScheme.primary
          : theme.colorScheme.secondaryContainer;
    }

    if (isMatch && searchState.isFuzzy) {
      baseBubbleColor = isCurrentMatch ? Colors.deepOrange : Colors.orange;
    }

    final bubbleColor = baseBubbleColor;

    final Color textColor;
    if (useAdvancedThemeData) {
      // In advanced themes, use the custom text color from the theme model
      final colorValue = isMe
          ? advTheme.textTheme.senderMessageColor
          : advTheme.textTheme.receiverMessageColor;
      textColor = Color(colorValue);
    } else {
      textColor = isMe
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSecondaryContainer;
    }

    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final isTerminal =
        theme.appBarTheme.titleTextStyle?.fontFamily == 'monospace';

    // Extract dynamic bubble radius from theme
    double radiusTopLeft = 16.0;
    double radiusTopRight = 16.0;
    double radiusBottomLeft = isMe ? 16.0 : 0.0;
    double radiusBottomRight = isMe ? 0.0 : 16.0;

    if (useAdvancedThemeData) {
      radiusTopLeft = bubbleConf.radiusTopLeft;
      radiusTopRight = bubbleConf.radiusTopRight;
      radiusBottomLeft = bubbleConf.radiusBottomLeft;
      radiusBottomRight = bubbleConf.radiusBottomRight;
    } else {
      if (theme.cardTheme.shape is RoundedRectangleBorder) {
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        if (shape.borderRadius is BorderRadius) {
          final rad = (shape.borderRadius as BorderRadius).topLeft.x;
          radiusTopLeft = rad;
          radiusTopRight = rad;
          radiusBottomLeft = isMe ? rad : 0.0;
          radiusBottomRight = isMe ? 0.0 : rad;
        }
      }
    }

    return _SwipeToReply(
      key: ValueKey(msg.id),
      isMe: isMe,
      focusNode: _messageFocusNode,
      onReply: () {
        setState(() {
          _replyingToMessage = msg;
        });
        if (mounted) {
          _messageFocusNode.requestFocus();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            GestureDetector(
              onLongPress: () => _showMessageActions(context, msg, isMe, theme),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  border: isTerminal
                      ? Border.all(color: theme.colorScheme.onSurface, width: 1)
                      : null,
                  borderRadius: isTerminal
                      ? BorderRadius.zero
                      : BorderRadius.only(
                          topLeft: Radius.circular(radiusTopLeft),
                          topRight: Radius.circular(radiusTopRight),
                          bottomLeft: Radius.circular(radiusBottomLeft),
                          bottomRight: Radius.circular(radiusBottomRight),
                        ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Forwarded Tag
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

                    // Replying content indicator
                    if (msg.repliedToMessageId.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg.repliedToMessageContent,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isMe
                                ? textColor.withValues(alpha: 0.8)
                                : Colors.grey,
                          ),
                        ),
                      ),

                    // Media renderer
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
                                          : (_receiverUser?.displayName ?? 'User'),
                                      timestamp: msg.timestamp,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: msg.fileUrl.isNotEmpty
                              ? Base64Image(
                                  key: ValueKey(msg.fileUrl),
                                  base64String: msg.fileUrl,
                                  fit: BoxFit.cover,
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
                            onPressed: () {
                              // File download trigger (open in browser / share)
                            },
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

            // Reactions Row
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

            // Message status details
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
                        (_receiverUser?.readReceiptsEnabled ?? true),
                    theme,
                    statusColor: Color(advTheme.textTheme.timestampColor),
                  ),
                ],
                if (currentUser != null &&
                    msg.starredBy.contains(currentUser.uid)) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 12, color: Colors.grey),
                ],
                if (ref
                    .watch(chatMediaProvider(widget.receiverId))
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

  Widget _buildReplyingBar(ThemeData theme) {
    return Container(
      key: const ValueKey('reply_bar'),
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to: ${_replyingToMessage!.content.isNotEmpty ? _replyingToMessage!.content : _replyingToMessage!.fileName}',
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

  Widget _buildInputBar(
    ThemeData theme,
    AdvancedThemeModel advTheme,
    bool useAdvancedThemeData,
  ) {
    final defaultIconColor = useAdvancedThemeData
        ? Color(advTheme.appAppearance.iconColor)
        : theme.colorScheme.primary;
    final defaultInputBg = useAdvancedThemeData
        ? Color(advTheme.appAppearance.inputBackgroundColor)
        : theme.colorScheme.surface;
    final defaultInputText = useAdvancedThemeData
        ? Color(advTheme.appAppearance.inputTextColor)
        : theme.colorScheme.onSurface;

    return Container(
      key: const ValueKey('input_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Media attachments button
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: defaultIconColor,
            ),
            onPressed: () => _showMediaAttachmentOptions(theme),
          ),

          // Main text entry field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: defaultInputBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isRecording
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mic,
                            color: theme.colorScheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recording audio...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: defaultInputText,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _stopRecording(false), // Cancel
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    )
                  : TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      onChanged: _onTextChanged,
                      onTapOutside: (event) {
                        // Prevent keyboard from closing automatically when tapping outside (e.g. starting a swipe).
                        // It will close on drag due to ListView's keyboardDismissBehavior.
                      },
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      style: TextStyle(color: defaultInputText),
                      cursorColor: defaultIconColor,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(
                          color: defaultInputText.withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // Send / Voice Record Button
          Builder(builder: (context) {
            final sendButtonBgColor = useAdvancedThemeData
                ? Color(advTheme.appAppearance.sendButtonColor)
                : theme.colorScheme.secondary;
            final sendIconColor = sendButtonBgColor.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white;
            return GestureDetector(
            onLongPress: _isRecording ? null : _startRecording,
            onLongPressUp: _isRecording ? () => _stopRecording(true) : null,
            child: IconButton.filled(
              onPressed: _isRecording ? null : _sendText,
              style: IconButton.styleFrom(
                backgroundColor: sendButtonBgColor,
                shape: const CircleBorder(),
                minimumSize: const Size(48, 48),
              ),
              icon: _isRecording
                  ? Icon(Icons.stop, color: sendIconColor)
                  : (_messageController.text.trim().isNotEmpty
                        ? Icon(Icons.send, color: sendIconColor)
                        : Icon(Icons.mic, color: sendIconColor)),
            ),
          );
          }),
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
              // Reactions Row
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
                            // Remove reaction
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

/// WhatsApp-style swipe-to-reply widget.
/// Received messages: swipe RIGHT to reply.
/// Sent messages: swipe LEFT to reply.
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
        // Sent messages: swipe LEFT (negative delta)
        _dragExtent = (_dragExtent - delta).clamp(0.0, _maxDrag);
      } else {
        // Received messages: swipe RIGHT (positive delta)
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
    // Sent messages translate left (negative), received translate right (positive)
    final translateX = widget.isMe ? -_dragExtent : _dragExtent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // Reply icon — appears on the correct side
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
          // Animated message content
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
