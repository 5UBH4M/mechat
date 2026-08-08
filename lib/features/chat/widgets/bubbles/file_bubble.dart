import 'package:flutter/material.dart';
import '../../../../domain/entities/message_entity.dart';

class FileBubble extends StatelessWidget {
  final MessageEntity msg;
  final bool isMe;
  final Color textColor;
  final ThemeData theme;

  const FileBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.textColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          msg.type == 'video'
              ? Icons.video_file
              : Icons.insert_drive_file,
          color: isMe ? textColor : theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(msg.fileSize / 1024).toStringAsFixed(1)} KB',
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? textColor.withValues(alpha: 0.7)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.download,
            color: isMe ? textColor : null,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}
