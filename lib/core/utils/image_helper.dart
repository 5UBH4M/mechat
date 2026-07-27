import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cross_file/cross_file.dart';

class ImageHelper {
  /// Compresses the image and converts it to a base64 string.
  static Future<String> convertToBase64(
    String imagePath, {
    int maxWidth = 300,
    int quality = 70,
  }) async {
    final Uint8List bytes;
    if (kIsWeb) {
      bytes = await XFile(imagePath).readAsBytes();
    } else {
      bytes = await File(imagePath).readAsBytes();
    }


    img.Image? decodedImage = await compute(_decodeImageBackground, bytes);
    if (decodedImage == null) return '';


    if (decodedImage.width > maxWidth) {
      decodedImage = img.copyResize(decodedImage, width: maxWidth);
    }


    final compressedBytes = await compute(
      _encodeJpgBackground,
      _EncodeParams(decodedImage, quality),
    );


    return 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
  }
}

class _EncodeParams {
  final img.Image image;
  final int quality;
  _EncodeParams(this.image, this.quality);
}

img.Image? _decodeImageBackground(Uint8List bytes) {
  return img.decodeImage(bytes);
}

Uint8List _encodeJpgBackground(_EncodeParams params) {
  return Uint8List.fromList(
    img.encodeJpg(params.image, quality: params.quality),
  );
}

Uint8List _decodeBase64(String data) {
  return base64Decode(data);
}

/// Static in-memory cache for decoded base64 image bytes.
/// Keyed by the base64 string's hashCode to avoid re-decoding on widget
/// recreation (which happens every time the message list rebuilds).
class _Base64Cache {
  static final Map<int, Uint8List> _cache = {};
  static const int _maxEntries = 30;

  static Uint8List? get(String key) => _cache[key.hashCode];

  static void put(String key, Uint8List bytes) {
    final hash = key.hashCode;
    if (_cache.length >= _maxEntries && !_cache.containsKey(hash)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[hash] = bytes;
  }
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
    _loadImage();
  }

  @override
  void didUpdateWidget(Base64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64String != widget.base64String) {
      _hasError = false;
      _loadImage();
    }
  }

  void _loadImage() {
    if (widget.base64String.isEmpty) return;
    if (!widget.base64String.startsWith('data:image')) return;

    // Check static cache first — instant, no flicker
    final cached = _Base64Cache.get(widget.base64String);
    if (cached != null) {
      _bytes = cached;
      return; // Already decoded, no setState needed during build
    }


    final base64Data = widget.base64String.split(',').last;
    compute(_decodeBase64, base64Data)
        .then((bytes) {
          _Base64Cache.put(widget.base64String, bytes);
          if (mounted) {
            setState(() {
              _bytes = bytes;
            });
          }
        })
        .catchError((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });
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
        // Show a fixed-size placeholder so layout doesn't jump
        return SizedBox(
          width: widget.width ?? 200,
          height: widget.height ?? 200,
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

    // Network URL — CachedNetworkImage handles its own disk/memory cache
    return CachedNetworkImage(
      imageUrl: widget.base64String,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) =>
          SizedBox(width: widget.width ?? 200, height: widget.height ?? 200),
      errorWidget: (context, url, error) =>
          Icon(Icons.error, size: widget.width ?? 50, color: Colors.grey),
    );
  }
}

ImageProvider getBase64ImageProvider(String base64String) {
  if (base64String.startsWith('data:image')) {

    final cached = _Base64Cache.get(base64String);
    if (cached != null) return MemoryImage(cached);
    final base64Data = base64String.split(',').last;
    final bytes = base64Decode(base64Data);
    _Base64Cache.put(base64String, bytes);
    return MemoryImage(bytes);
  }
  return CachedNetworkImageProvider(base64String);
}
