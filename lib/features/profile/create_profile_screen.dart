import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/profile_crop_screen.dart';
import 'profile_notifier.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController(
    text: AppConstants.defaultAbout,
  );
  final _formKey = GlobalKey<FormState>();
  String? _localImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
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
        if (croppedPath != null) {
          setState(() {
            _localImagePath = croppedPath;
          });
        }
      }
    } catch (_) {}
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(profileNotifierProvider.notifier)
        .saveProfile(
          username: _usernameController.text.trim(),
          displayName: _nameController.text.trim(),
          about: _bioController.text.trim(),
          localImagePath: _localImagePath,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileNotifierProvider);
    // Auth state not needed here

    // Listen for success routing
    ref.listen<ProfileState>(profileNotifierProvider, (previous, next) {
      if (next.status == ProfileStatus.success) {
        context.go('/home');
      } else if (next.status == ProfileStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('Create Profile'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Beautiful Profile Avatar Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: theme.colorScheme.surface,
                        backgroundImage: _localImagePath != null
                            ? FileImage(File(_localImagePath!))
                            : null,
                        child: _localImagePath == null
                            ? Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 40,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Username Text Field
                TextFormField(
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.contains(' ')) {
                      return 'Username cannot contain spaces';
                    }
                    if (value.length < 5) {
                      return 'Username must be at least 5 characters';
                    }
                    if (value.length > 20) {
                      return 'Username must be at most 20 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value)) {
                      return 'Only letters, numbers, _ - . allowed';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'subham123',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),

                const SizedBox(height: 20),

                // Display Name Text Field
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your display name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'Bob',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 20),

                // About / Bio Text Field
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'About / Bio',
                    hintText: 'Tell us about yourself...',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),

                const SizedBox(height: 48),

                ElevatedButton(
                  onPressed: profileState.status == ProfileStatus.loading
                      ? null
                      : _submit,
                  child: profileState.status == ProfileStatus.loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
