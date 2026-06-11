import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../profile/profile_notifier.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _readReceipts = true;
  bool _lastSeen = true;
  bool _profilePhoto = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      _readReceipts = user.readReceiptsEnabled;
      _lastSeen = user.lastSeenVisible;
      _profilePhoto = user.profilePhotoVisible;
    }
  }

  void _updateSettings() {
    ref.read(profileNotifierProvider.notifier).updatePrivacySettings(
          readReceiptsEnabled: _readReceipts,
          lastSeenVisible: _lastSeen,
          profilePhotoVisible: _profilePhoto,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Privacy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPrivacyTile(
            title: 'Last Seen and Online',
            subtitle: _lastSeen ? 'Everyone' : 'Nobody',
            icon: Icons.access_time_rounded,
            value: _lastSeen,
            onChanged: (val) {
              setState(() => _lastSeen = val);
              _updateSettings();
            },
            theme: theme,
          ),
          _buildPrivacyTile(
            title: 'Profile Photo',
            subtitle: _profilePhoto ? 'Everyone' : 'Nobody',
            icon: Icons.account_circle_rounded,
            value: _profilePhoto,
            onChanged: (val) {
              setState(() => _profilePhoto = val);
              _updateSettings();
            },
            theme: theme,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Read Receipts'),
            subtitle: const Text('If turned off, you won\'t send or receive Read Receipts. Read Receipts are always sent for group chats (not applicable in 1-on-1).'),
            value: _readReceipts,
            activeColor: theme.colorScheme.primary,
            onChanged: (val) {
              setState(() => _readReceipts = val);
              _updateSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.primary)),
      onTap: () {
        // Toggle simply
        onChanged(!value);
      },
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    );
  }
}
