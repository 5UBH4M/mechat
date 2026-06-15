import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/app_router.dart';
import 'features/auth/auth_notifier.dart';
import 'features/chat/chat_notifier.dart';
import 'domain/entities/chat_entity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive Local Storage Cache
  final hiveService = HiveService();
  await hiveService.init();

  // 2. Initialize Firebase (defensively wrapped for development safety)
  try {
    await Firebase.initializeApp();
    
    // Initialize Push Notifications
    final notificationService = NotificationService();
    await notificationService.init();

    // Create john_doe test user
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc('test_john_doe').get();
      if (!doc.exists) {
        await FirebaseFirestore.instance.collection('users').doc('test_john_doe').set({
          'uid': 'test_john_doe',
          'phoneNumber': '+11234567890',
          'username': 'john_doe',
          'displayName': 'John Doe',
          'profilePictureUrl': '',
          'about': 'Hey there! I am John Doe.',
          'isOnline': false,
          'lastSeen': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'publicKey': 'fake_public_key',
          'blockedUsers': [],
          'pushToken': '',
          'readReceiptsEnabled': true,
          'lastSeenVisible': true,
          'profilePhotoVisible': true,
          'connectedTo': '',
          'disconnectRequested': false,
          'previouslyConnected': [],
          'showPreviousConnectionsVisible': true,
          'autoAcceptCalls': true,
          'disableMute': true,
          'disableCameraOff': true,
        });
      }
    } catch (_) {}
  } catch (e) {
    dev.log("Firebase Initialization warning: $e");
    dev.log("The application will continue to run with local caching offline support.");
  }

  runApp(
    const ProviderScope(
      child: MeChatApp(),
    ),
  );
}

class MeChatApp extends ConsumerStatefulWidget {
  const MeChatApp({super.key});

  @override
  ConsumerState<MeChatApp> createState() => _MeChatAppState();
}

class _MeChatAppState extends ConsumerState<MeChatApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Global listener for incoming messages to show notifications
    ref.listen(recentChatsProvider, (previous, next) {
      final currentUser = ref.read(authNotifierProvider).user;
      if (currentUser == null) return;

      final oldChats = previous?.value;
      if (oldChats == null) return; // Prevent notifying for all messages on app startup
      final newChats = next.value ?? [];

      for (var newChat in newChats) {
        final oldChat = oldChats.firstWhere(
          (c) => c.id == newChat.id, 
          orElse: () => ChatEntity(
            id: newChat.id,
            participants: newChat.participants,
            lastMessage: null,
            unreadCounts: const {},
            typingStatus: newChat.typingStatus,
            isNotesToSelf: newChat.isNotesToSelf,
          ),
        );
        
        final newLastMsg = newChat.lastMessage;
        final oldLastMsg = oldChat.lastMessage;

        // If there's a new message and we didn't send it
        if (newLastMsg != null && newLastMsg.senderId != currentUser.uid) {
          if (oldLastMsg == null || newLastMsg.id != oldLastMsg.id) {
            
            // Check if we are currently in the chat screen for this chat
            final currentRoute = appRouter.routerDelegate.currentConfiguration.last.matchedLocation;
            final isChatScreenActive = currentRoute == '/chat/${newLastMsg.senderId}' || 
              currentRoute == '/chat/${newChat.participants.firstWhere((id) => id != currentUser.uid, orElse: () => '')}';
            
            final lifecycleState = WidgetsBinding.instance.lifecycleState;
            final inBackground = lifecycleState != AppLifecycleState.resumed;

            // Only notify if we are NOT in the chat screen or app is in background
            if (!isChatScreenActive || inBackground) {
              String bodyText = newLastMsg.type == 'text' ? newLastMsg.content : '📸 Media message';
              if (newLastMsg.content.isEmpty && newLastMsg.type == 'text') {
                 // For deleted messages or similar empty cases, do nothing or handle specially
                 if(newLastMsg.fileUrl.isEmpty) continue; 
              }

              NotificationService().showCustomNotification(
                id: newLastMsg.id.hashCode,
                title: 'New Message',
                body: bodyText,
                payload: '/chat/${newLastMsg.senderId}',
              );
            }
          }
        }
      }
    });

    return MaterialApp.router(
      title: 'MeChat',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
