import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import 'profile_notifier.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final notifier = ref.read(profileNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Customize how push notifications appear when the app is closed.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SwitchListTile(
            title: const Text('Show Sender Name'),
            subtitle: const Text(
              'Display the sender\'s name in notifications.',
            ),
            value: !user.hideNotificationSender,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              notifier.updatePrivacySettings(
                readReceiptsEnabled: user.readReceiptsEnabled,
                lastSeenVisible: user.lastSeenVisible,
                profilePhotoVisible: user.profilePhotoVisible,
                hideNotificationSender: !val,
              );
            },
          ),
          SwitchListTile(
            title: const Text('Show Message Content'),
            subtitle: const Text(
              'Because of end-to-end encryption, message content cannot be fully displayed. Turning this off hides the "New message" indicator.',
            ),
            value: !user.hideNotificationMessage,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              notifier.updatePrivacySettings(
                readReceiptsEnabled: user.readReceiptsEnabled,
                lastSeenVisible: user.lastSeenVisible,
                profilePhotoVisible: user.profilePhotoVisible,
                hideNotificationMessage: !val,
              );
            },
          ),
        ],
      ),
    );
  }
}
