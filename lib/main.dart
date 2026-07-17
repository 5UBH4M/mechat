import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/app_router.dart';
import 'features/auth/auth_notifier.dart';
import 'features/chat/chat_notifier.dart';
import 'domain/entities/chat_entity.dart';
import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Whether Firebase was successfully initialized on this platform.
bool firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  try {
    final hiveService = HiveService();
    await hiveService.init();
  } catch (e) {
    debugPrint('HiveService init failed: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    firebaseInitialized = false;
  }

  if (firebaseInitialized) {
    try {
      final notificationService = NotificationService();
      await notificationService.init();
    } catch (_) {}
  }

  runApp(const ProviderScope(child: MeChatApp()));
}

class MeChatApp extends ConsumerStatefulWidget {
  const MeChatApp({super.key});

  @override
  ConsumerState<MeChatApp> createState() => _MeChatAppState();
}

class _MeChatAppState extends ConsumerState<MeChatApp>
    with WidgetsBindingObserver {
  /// Cache of userId -> displayName for notification sender names
  final Map<String, String> _userNameCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (firebaseInitialized) {
      // Set up notification tap handler to navigate to the chat
      NotificationService().onNotificationTap = (String? payload) {
        if (payload != null && payload.startsWith('/chat/')) {
          appRouter.go('/home');
          appRouter.push(payload);
        }
      };
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Look up a user's display name, with in-memory caching
  Future<String> _getSenderName(String uid) async {
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final name = doc.data()?['displayName'] as String? ?? 'Someone';
      _userNameCache[uid] = name;
      return name;
    } catch (_) {
      return 'Someone';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!firebaseInitialized) {
      return MaterialApp(
        title: 'MeChat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _UnsupportedPlatformScreen(),
      );
    }

    ref.listen(recentChatsProvider, (previous, next) {
      final currentUser = ref.read(authNotifierProvider).user;
      if (currentUser == null) return;

      final oldChats = previous?.value;
      if (oldChats == null) {
        return; // Prevent notifying for all messages on app startup
      }
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

        if (newLastMsg != null && newLastMsg.senderId != currentUser.uid) {
          if (oldLastMsg == null || newLastMsg.id != oldLastMsg.id) {
            final currentRoute = appRouter
                .routerDelegate
                .currentConfiguration
                .last
                .matchedLocation;
            final isChatScreenActive =
                currentRoute == '/chat/${newLastMsg.senderId}' ||
                currentRoute ==
                    '/chat/${newChat.participants.firstWhere((id) => id != currentUser.uid, orElse: () => '')}';

            // Don't show notifications when the app is in the foreground
            final lifecycleState = WidgetsBinding.instance.lifecycleState;
            final isAppInForeground = lifecycleState == null ||
                lifecycleState == AppLifecycleState.resumed;

            if (!isChatScreenActive && !isAppInForeground) {
              final hideSender = currentUser.hideNotificationSender;
              final hideMessage = currentUser.hideNotificationMessage;

              String bodyText;
              switch (newLastMsg.type) {
                case 'image':
                  bodyText = '📷 Photo';
                  break;
                case 'video':
                  bodyText = '📹 Video';
                  break;
                case 'audio':
                  bodyText = '🎵 Voice message';
                  break;
                case 'document':
                  bodyText = '📄 Document';
                  break;
                default:
                  bodyText = newLastMsg.content;
              }

              if (newLastMsg.content.isEmpty && newLastMsg.type == 'text') {
                if (newLastMsg.fileUrl.isEmpty) continue;
              }

              final chatRoute = '/chat/${newLastMsg.senderId}';

              _getSenderName(newLastMsg.senderId).then((senderName) {
                NotificationService().showMessageNotification(
                  id: newLastMsg.id.hashCode,
                  senderName: senderName,
                  messageBody: bodyText,
                  chatRoute: chatRoute,
                  hideSender: hideSender,
                  hideMessage: hideMessage,
                );
              });
            }
          }
        }
      }
    });

    final advTheme = ref.watch(advancedThemeProvider(null));
    final globalThemeId = ref.watch(themeControllerProvider).globalThemeId;

    final customThemeKeys = ['terminal', 'cyberpunk', 'oldphone', 'material3'];
    final useAdvancedGlobal = !customThemeKeys.contains(globalThemeId);

    final themeModeType = ref.watch(themeModeProvider);

    ThemeData lightTheme = AppTheme.lightTheme;
    ThemeData darkTheme = AppTheme.darkTheme;
    ThemeMode activeMode = ThemeMode.system;

    switch (themeModeType) {
      case AppThemeType.light:
        activeMode = ThemeMode.light;
        break;
      case AppThemeType.dark:
        activeMode = ThemeMode.dark;
        break;
      case AppThemeType.terminal:
        lightTheme = AppTheme.terminalTheme;
        darkTheme = AppTheme.terminalTheme;
        activeMode = ThemeMode.dark;
        break;
      case AppThemeType.oldPhone:
        lightTheme = AppTheme.oldPhoneTheme;
        darkTheme = AppTheme.oldPhoneTheme;
        activeMode = ThemeMode.dark;
        break;
      case AppThemeType.cyberpunk:
        lightTheme = AppTheme.cyberpunkTheme;
        darkTheme = AppTheme.cyberpunkTheme;
        activeMode = ThemeMode.dark;
        break;
      default:
        break;
    }

    return MaterialApp.router(
      title: 'MeChat',
      debugShowCheckedModeBanner: false,
      theme: useAdvancedGlobal
          ? advTheme.toThemeData(Brightness.light)
          : lightTheme,
      darkTheme: useAdvancedGlobal
          ? advTheme.toThemeData(Brightness.dark)
          : darkTheme,
      themeMode: activeMode,
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: appRouter,
    );
  }
}

/// Fallback screen shown when Firebase is unavailable (Linux desktop).
class _UnsupportedPlatformScreen extends StatelessWidget {
  const _UnsupportedPlatformScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.desktop_windows_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'MeChat',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Linux desktop is not yet supported.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Firebase (which MeChat depends on for authentication, '
                'messaging, and storage) does not provide native Linux '
                'plugins. Please use the Android, iOS, or Web version '
                'of MeChat instead.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Tip: Run "flutter run -d chrome" to use the web version locally.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
