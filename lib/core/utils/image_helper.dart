import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageHelper {
  /// Compresses the image and converts it to a base64 string.
  static Future<String> convertToBase64(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    
    // Decode image to resize/compress
    img.Image? decodedImage = await compute(_decodeImageBackground, bytes);
    if (decodedImage == null) return '';

    // Resize to a maximum width of 300 to keep it very small (Firestore 1MB limit)
    if (decodedImage.width > 300) {
      decodedImage = img.copyResize(decodedImage, width: 300);
    }

    // Compress as JPEG
    final compressedBytes = await compute(_encodeJpgBackground, decodedImage);
    
    // Return Base64
    return 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
  }
}

img.Image? _decodeImageBackground(Uint8List bytes) {
  return img.decodeImage(bytes);
}

Uint8List _encodeJpgBackground(img.Image image) {
  return Uint8List.fromList(img.encodeJpg(image, quality: 70));
}

Uint8List _decodeBase64(String data) {
  return base64Decode(data);
}

class Base64Image extends StatefulWidget {
  final String base64String;
  final double? width;
  final double? height;
  final BoxFit fit;

  const Base64Image({
    super.key,
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  Uint8List? _bytes;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(Base64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64String != widget.base64String) {
      _bytes = null;
      _hasError = false;
      _decodeImage();
    }
  }

  Future<void> _decodeImage() async {
    if (widget.base64String.isEmpty) return;
    if (widget.base64String.startsWith('data:image')) {
      final base64Data = widget.base64String.split(',').last;
      try {
        final bytes = await compute(_decodeBase64, base64Data);
        if (mounted) {
          setState(() {
            _bytes = bytes;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.base64String.isEmpty) {
      return Icon(Icons.person, size: widget.width ?? 50, color: Colors.grey);
    }
    
    if (widget.base64String.startsWith('data:image')) {
      if (_hasError) {
        return Icon(Icons.error, size: widget.width ?? 50, color: Colors.grey);
      }
      if (_bytes == null) {
        return SizedBox(
          width: widget.width ?? 50,
          height: widget.height ?? 50,
        );
      }
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
      );
    }
    
    return Image.network(
      widget.base64String,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.error, size: widget.width ?? 50, color: Colors.grey),
    );
  }
}

ImageProvider getBase64ImageProvider(String base64String) {
  if (base64String.startsWith('data:image')) {
    final base64Data = base64String.split(',').last;
    return MemoryImage(base64Decode(base64Data));
  }
  return NetworkImage(base64String);
}
