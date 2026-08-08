import 'package:flutter/material.dart';
import '../../../../domain/entities/message_entity.dart';
import '../../audio_message_player.dart';

class AudioBubble extends StatelessWidget {
  final MessageEntity msg;
  final bool isMe;

  const AudioBubble({
    super.key,
    required this.msg,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return AudioMessagePlayer(
      audioUrl: msg.fileUrl,
      duration: msg.duration,
      isSender: isMe,
    );
  }
}
