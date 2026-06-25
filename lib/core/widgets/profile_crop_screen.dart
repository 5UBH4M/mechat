import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';

class ProfileCropScreen extends StatefulWidget {
  final String imagePath;

  const ProfileCropScreen({super.key, required this.imagePath});

  @override
  State<ProfileCropScreen> createState() => _ProfileCropScreenState();
}

class _ProfileCropScreenState extends State<ProfileCropScreen> {
  final _cropController = CropController();
  late Uint8List _imageBytes;
  bool _isLoading = true;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _isLoading = false;
    });
  }

  Future<void> _onCropped(Uint8List croppedData) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/cropped_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(croppedData);
    if (mounted) {
      Navigator.pop(context, file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Crop Profile Picture',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Crop area
            Expanded(
              child: Crop(
                image: _imageBytes,
                controller: _cropController,
                aspectRatio: 1,
                withCircleUi: true,
                interactive: true,
                baseColor: Colors.black,
                maskColor: Colors.black.withValues(alpha: 0.7),
                progressIndicator: const CircularProgressIndicator(
                  color: Colors.white,
                ),
                onCropped: _onCropped,
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel button
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, null),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),

                  // Confirm button
                  FilledButton.icon(
                    onPressed: _isCropping
                        ? null
                        : () {
                            setState(() => _isCropping = true);
                            _cropController.crop();
                          },
                    icon: _isCropping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 28),
                    label: Text(_isCropping ? 'Cropping...' : 'Done'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
