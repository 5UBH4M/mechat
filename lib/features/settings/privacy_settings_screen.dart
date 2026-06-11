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
  bool _showPreviousConnectionsVisible = true;
  bool _autoAcceptCalls = true;
  bool _disableMute = false;
  bool _disableCameraOff = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      _readReceipts = user.readReceiptsEnabled;
      _lastSeen = user.lastSeenVisible;
      _profilePhoto = user.profilePhotoVisible;
      _showPreviousConnectionsVisible = user.showPreviousConnectionsVisible;
      _autoAcceptCalls = user.autoAcceptCalls;
      _disableMute = user.disableMute;
      _disableCameraOff = user.disableCameraOff;
    }
  }

  void _updateSettings() {
    ref.read(profileNotifierProvider.notifier).updatePrivacySettings(
          readReceiptsEnabled: _readReceipts,
          lastSeenVisible: _lastSeen,
          profilePhotoVisible: _profilePhoto,
          showPreviousConnectionsVisible: _showPreviousConnectionsVisible,
          autoAcceptCalls: _autoAcceptCalls,
          disableMute: _disableMute,
          disableCameraOff: _disableCameraOff,
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
            title: const Text('Show Previous Connections'),
            subtitle: const Text('Allow others to see the list of people you have previously established a connection with on your profile.'),
            value: _showPreviousConnectionsVisible,
            activeColor: theme.colorScheme.primary,
            onChanged: (val) {
              setState(() => _showPreviousConnectionsVisible = val);
              _updateSettings();
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text('Call Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          SwitchListTile(
            title: const Text('Auto-Accept Calls'),
            subtitle: const Text('Automatically accept incoming calls after 5 seconds.'),
            value: _autoAcceptCalls,
            activeColor: theme.colorScheme.primary,
            onChanged: (val) {
              setState(() => _autoAcceptCalls = val);
              _updateSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Disable Mute in Calls'),
            subtitle: const Text('Remove the mute button during calls so audio cannot be muted.'),
            value: _disableMute,
            activeColor: theme.colorScheme.primary,
            onChanged: (val) {
              setState(() => _disableMute = val);
              _updateSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Disable Camera Off'),
            subtitle: const Text('Remove the video toggle button during video calls so the camera cannot be turned off.'),
            value: _disableCameraOff,
            activeColor: theme.colorScheme.primary,
            onChanged: (val) {
              setState(() => _disableCameraOff = val);
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
