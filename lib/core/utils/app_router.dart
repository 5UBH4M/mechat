import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/calls/incoming_call_screen.dart';
import '../../features/calls/ongoing_call_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/chat/home_screen.dart';
import '../../features/contacts/contacts_screen.dart';
import '../../features/profile/create_profile_screen.dart';
import '../../features/settings/appearance_screen.dart';
import '../../features/settings/privacy_settings_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/advanced_appearance_screen.dart';
import '../../features/profile/notification_settings_screen.dart';
import '../../features/settings/backup_restore_screen.dart';
import '../services/hive_service.dart';

late final GoRouter appRouter;

void initializeRouter() {
  String initialLoc;
  final user = HiveService().getUser();
  if (user == null) {
    initialLoc = '/login';
  } else if ((user['username'] as String?)?.isEmpty ?? true) {
    initialLoc = '/create-profile';
  } else {
    initialLoc = '/home';
  }

  appRouter = GoRouter(
    initialLocation: initialLoc,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/create-profile',
        builder: (context, state) => const CreateProfileScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: '/chat/:receiverId',
        builder: (context, state) {
          final receiverId = state.pathParameters['receiverId']!;
          return ChatScreen(receiverId: receiverId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy-settings',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/custom-theme',
        builder: (context, state) => const AdvancedAppearanceScreen(),
      ),
      GoRoute(
        path: '/appearance',
        builder: (context, state) => const AppearanceScreen(),
      ),
      GoRoute(
        path: '/incoming-call',
        builder: (context, state) => const IncomingCallScreen(),
      ),
      GoRoute(
        path: '/ongoing-call',
        builder: (context, state) => const OngoingCallScreen(),
      ),
      GoRoute(
        path: '/backup-restore',
        builder: (context, state) => const BackupRestoreScreen(),
      ),
    ],
  );
}
