import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/image_viewer_screen.dart';
import '../../../../domain/entities/message_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../core/utils/image_helper.dart';
import '../../chat_notifier.dart';

class ImageBubble extends ConsumerWidget {
  final MessageEntity msg;
  final bool isMe;
  final UserEntity? receiverUser;

  const ImageBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.receiverUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: msg.fileUrl.isNotEmpty
          ? () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (context, animation, secondaryAnimation) => ImageViewerScreen(
                    base64String: msg.fileUrl,
                    senderName: isMe
                        ? 'You'
                        : (receiverUser?.displayName ?? 'User'),
                    timestamp: msg.timestamp,
                  ),
                ),
              );
            }
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: msg.fileUrl.isNotEmpty
            ? ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 250,
                  maxHeight: 300,
                  minWidth: 150,
                  minHeight: 150,
                ),
                child: Base64Image(
                  key: ValueKey(msg.fileUrl),
                  base64String: msg.fileUrl,
                  fit: BoxFit.cover,
                ),
              )
            : msg.localFilePath.isNotEmpty
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.file(
                        File(msg.localFilePath),
                        fit: BoxFit.cover,
                        width: 220,
                        height: 220,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 220,
                          height: 220,
                          child: Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black45,
                          child: Consumer(
                            builder: (context, ref, _) {
                              final progress = ref.watch(chatNotifierProvider);
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      value: progress > 0 && progress < 1.0 ? progress : null,
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (progress > 0 && progress < 1.0) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
      ),
    );
  }
}
