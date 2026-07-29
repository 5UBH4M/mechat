import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/app_router.dart';
import 'features/auth/auth_notifier.dart';
import 'features/chat/chat_notifier.dart';
import 'domain/entities/chat_entity.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  try {
    await HiveService().init();
  } catch (_) {}

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService().init();
  } catch (_) {}

  // Init SQLite database
  try {
    await AppDatabase.instance.database;
  } catch (_) {}

  initializeRouter();

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

    NotificationService().onNotificationTap = (String? payload) {
      if (payload != null && payload.startsWith('/chat/')) {
        appRouter.go('/home');
        appRouter.push(payload);
      }
    };
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
              final lifecycleState = WidgetsBinding.instance.lifecycleState;
              final isAppInForeground = lifecycleState == null ||
                  lifecycleState == AppLifecycleState.resumed;

              if (!isAppInForeground) {
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

