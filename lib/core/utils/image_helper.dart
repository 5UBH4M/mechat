import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageHelper {
  /// Compresses the image and converts it to a base64 string.
  static Future<String> convertToBase64(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    
    // Decode image to resize/compress
    img.Image? decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return '';

    // Resize to a maximum width of 300 to keep it very small (Firestore 1MB limit)
    if (decodedImage.width > 300) {
      decodedImage = img.copyResize(decodedImage, width: 300);
    }

    // Compress as JPEG
    final compressedBytes = img.encodeJpg(decodedImage, quality: 70);
    
    // Return Base64
    return 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
  }
}

class Base64Image extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (base64String.isEmpty) {
      return Icon(Icons.person, size: width ?? 50, color: Colors.grey);
    }
    
    if (base64String.startsWith('data:image')) {
      final base64Data = base64String.split(',').last;
      try {
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
        );
      } catch (e) {
        return Icon(Icons.error, size: width ?? 50, color: Colors.grey);
      }
    }
    
    // Fallback if it is a real network image URL
    return Image.network(
      base64String,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.error, size: width ?? 50, color: Colors.grey),
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
