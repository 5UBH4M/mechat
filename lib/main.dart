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
          'disableMute': false,
          'disableCameraOff': false,
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

class MeChatApp extends ConsumerWidget {
  const MeChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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
