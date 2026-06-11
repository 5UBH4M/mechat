import 'dart:developer' as dev;
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
