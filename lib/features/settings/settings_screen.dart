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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isEditing = false;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      _nameController.text = user.displayName;
      _usernameController.text = user.username;
      _bioController.text = user.about;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
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
        if (croppedPath != null) {
          setState(() {
            _localImagePath = croppedPath;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    await ref
        .read(profileNotifierProvider.notifier)
        .saveProfile(
          username: _usernameController.text.trim(),
          displayName: _nameController.text.trim(),
          about: _bioController.text.trim(),
          localImagePath: _localImagePath,
        );
    setState(() {
      _isEditing = false;
      _localImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authNotifierProvider).user;
    final profileState = ref.watch(profileNotifierProvider);

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
        actions: [
          if (_isEditing)
            IconButton(
              icon: profileState.status == ProfileStatus.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, color: Colors.green),
              onPressed: profileState.status == ProfileStatus.loading
                  ? null
                  : _saveProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // User Avatar Picker / Viewer
            Center(
              child: GestureDetector(
                onTap: () {
                  if (_isEditing) {
                    _pickImage();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UserInfoScreen(user: user),
                      ),
                    );
                  }
                },
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: theme.colorScheme.surface,
                      backgroundImage: _localImagePath != null && !kIsWeb
                          ? FileImage(File(_localImagePath!)) as ImageProvider
                          : (user.profilePictureUrl.isNotEmpty
                                ? getBase64ImageProvider(user.profilePictureUrl)
                                : null),
                      child:
                          _localImagePath == null &&
                              user.profilePictureUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Profile Fields
            if (_isEditing) ...[
              TextFormField(
                controller: _usernameController,
                readOnly: true, // Username cannot be changed once set
                decoration: InputDecoration(
                  labelText: 'Username',
                  suffixIcon: const Icon(Icons.lock_outline, size: 18),
                  helperText: 'Username cannot be changed',
                  helperStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio / About'),
              ),
            ] else ...[
              Text(
                user.displayName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@${user.username}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(user.email, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text(
                user.about,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 40),
            const Divider(thickness: 0.5),
            const SizedBox(height: 20),

            // Application settings options
            Card(
              child: Column(
                children: [
                  // Dark Mode Switch Option
                  // Appearance Settings Link
                  ListTile(
                    leading: Icon(
                      Icons.palette_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Appearance'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => context.push('/appearance'),
                  ),

                  // Privacy Settings Link
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Privacy'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => context.push('/privacy-settings'),
                  ),

                  // Notification Settings Link
                  ListTile(
                    leading: Icon(
                      Icons.notifications_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Notification Settings'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => context.push('/notification-settings'),
                  ),

                  // Wallpaper Settings Link
                  ListTile(
                    leading: Icon(
                      Icons.wallpaper_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Chat Wallpaper'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () async {
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
                              content: Text('Wallpaper updated successfully'),
                            ),
                          );
                        }
                      }
                    },
                    onLongPress: () async {
                      // Allow removing wallpaper on long press
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove Wallpaper'),
                          content: const Text(
                            'Remove the custom chat wallpaper?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('REMOVE'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(hiveServiceProvider)
                            .removeChatWallpaper();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wallpaper removed')),
                          );
                        }
                      }
                    },
                  ),
                  // Always Send HD Media Switch
                  SwitchListTile(
                    secondary: Icon(
                      Icons.high_quality_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Always Send HD Media'),
                    subtitle: const Text(
                      'Send images in highest resolution without compression',
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

                  // Blocked Users Screen Link
                  ListTile(
                    leading: Icon(
                      Icons.block_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: const Text('Blocked Contacts'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => context.push('/blocked-users'),
                  ),

                  // Security info tile
                  ListTile(
                    leading: Icon(
                      Icons.lock_rounded,
                      color: theme.colorScheme.secondary,
                    ),
                    title: const Text('Encryption Status'),
                    subtitle: const Text(
                      'All messaging streams are end-to-end encrypted',
                    ),
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
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout Action Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                foregroundColor: theme.colorScheme.error,
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
                  // Perform signout
                  ref.read(authNotifierProvider.notifier).signOut();
                  // Re-route to login
                  context.go('/login');
                }
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
