import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/image_helper.dart';
import '../../core/widgets/profile_crop_screen.dart';
import '../auth/auth_notifier.dart';
import '../profile/profile_notifier.dart';
import '../../core/services/service_providers.dart';
import '../chat/user_info_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      _nameController.text = user.displayName;
      _bioController.text = user.about;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null) {
        if (!mounted) return;
        final croppedPath = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileCropScreen(imagePath: picked.path),
          ),
        );
        if (!mounted) return;
        if (croppedPath != null) {
          setState(() {
            _localImagePath = croppedPath;
          });
          await ref.read(profileNotifierProvider.notifier).saveProfile(
                username: ref.read(authNotifierProvider).user!.username,
                displayName: ref.read(authNotifierProvider).user!.displayName,
                about: ref.read(authNotifierProvider).user!.about,
                localImagePath: croppedPath,
              );
          if (mounted) {
            setState(() => _localImagePath = null);
          }
        }
      }
    } catch (_) {}
  }

  void _editName() {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    _nameController.text = user.displayName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your name',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 25,
              decoration: const InputDecoration(
                hintText: 'Display Name',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final name = _nameController.text.trim();
                    if (name.length >= 3) {
                      await ref
                          .read(profileNotifierProvider.notifier)
                          .saveProfile(
                            username: user.username,
                            displayName: name,
                            about: user.about,
                          );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editAbout() {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    _bioController.text = user.about;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add About',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              autofocus: true,
              maxLength: 139,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'About',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(profileNotifierProvider.notifier)
                        .saveProfile(
                          username: user.username,
                          displayName: user.displayName,
                          about: _bioController.text.trim(),
                        );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authNotifierProvider).user;
    ref.watch(profileNotifierProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: _localImagePath != null && !kIsWeb
                            ? FileImage(File(_localImagePath!)) as ImageProvider
                            : (user.profilePictureUrl.isNotEmpty
                                  ? getBase64ImageProvider(user.profilePictureUrl)
                                  : null),
                        child:
                            _localImagePath == null &&
                                user.profilePictureUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.about,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UserInfoScreen(user: user),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.qr_code_2_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),

          ListTile(
            leading: Icon(
              Icons.person_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              'Name',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Text(
              user.displayName,
              style: theme.textTheme.bodyLarge,
            ),
            trailing: Icon(
              Icons.edit_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            onTap: _editName,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),

          ListTile(
            leading: Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              'About',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Text(
              user.about,
              style: theme.textTheme.bodyLarge,
            ),
            trailing: Icon(
              Icons.edit_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            onTap: _editAbout,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),

          ListTile(
            leading: Icon(
              Icons.alternate_email_rounded,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              'Username',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Text(
              '@${user.username}',
              style: theme.textTheme.bodyLarge,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),

          ListTile(
            leading: Icon(
              Icons.email_outlined,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              'Email',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Text(
              user.email,
              style: theme.textTheme.bodyLarge,
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          _buildSettingsTile(
            theme: theme,
            icon: Icons.palette_rounded,
            title: 'Appearance',
            onTap: () => context.push('/appearance'),
          ),

          _buildSettingsTile(
            theme: theme,
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy',
            onTap: () => context.push('/privacy-settings'),
          ),

          _buildSettingsTile(
            theme: theme,
            icon: Icons.notifications_rounded,
            title: 'Notification Settings',
            onTap: () => context.push('/notification-settings'),
          ),

          _buildSettingsTile(
            theme: theme,
            icon: Icons.wallpaper_rounded,
            title: 'Chat Wallpaper',
            subtitle: ref.read(hiveServiceProvider).getChatWallpaper() != null
                ? 'Tap to change or remove'
                : null,
            onTap: () {
              final hasWallpaper = ref.read(hiveServiceProvider).getChatWallpaper() != null;
              showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library_rounded),
                        title: const Text('Choose from Gallery'),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            await ref
                                .read(hiveServiceProvider)
                                .saveChatWallpaper(picked.path);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Wallpaper updated'),
                                ),
                              );
                              setState(() {});
                            }
                          }
                        },
                      ),
                      if (hasWallpaper)
                        ListTile(
                          leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                          title: const Text('Remove Wallpaper'),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await ref
                                .read(hiveServiceProvider)
                                .removeChatWallpaper();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Wallpaper removed'),
                                ),
                              );
                              setState(() {});
                            }
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          SwitchListTile(
            secondary: Icon(
              Icons.high_quality_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Always Send HD Media'),
            subtitle: const Text(
              'Send images without compression',
            ),
            value: user.alwaysSendHD,
            onChanged: (val) {
              ref
                  .read(profileNotifierProvider.notifier)
                  .updatePrivacySettings(
                    alwaysSendHD: val,
                    readReceiptsEnabled: user.readReceiptsEnabled,
                    lastSeenVisible: user.lastSeenVisible,
                    profilePhotoVisible: user.profilePhotoVisible,
                  );
            },
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          _buildSettingsTile(
            theme: theme,
            icon: Icons.lock_rounded,
            iconColor: theme.colorScheme.secondary,
            title: 'Encryption Status',
            subtitle: 'End-to-end encrypted',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('End-to-End Encryption'),
                  content: const Text(
                    'MeChat uses industry standard AES-256 GCM symmetric keys. '
                    'Your messages are encrypted before sending and stored as ciphertext on Firestore. '
                    'Decryption occurs locally on device. No intermediates can read your conversations.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),

          _buildSettingsTile(
            theme: theme,
            icon: Icons.cloud_download_outlined,
            title: 'Backup & Restore',
            subtitle: 'Local backup of chats and media',
            onTap: () => context.push('/backup-restore'),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                foregroundColor: theme.colorScheme.error,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text(
                      'Are you sure you want to sign out from MeChat?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('LOGOUT'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  ref.read(authNotifierProvider.notifier).signOut();
                  context.go('/login');
                }
              },
              child: const Text('Logout'),
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'developed by ~ Subham 🤍',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }
}
