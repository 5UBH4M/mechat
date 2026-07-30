import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String type;
  final DateTime timestamp;
  final String status;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final int duration;
  final String repliedToMessageId;
  final String repliedToMessageContent;
  final Map<String, String> reactions;
  final List<String> starredBy;
  final bool isForwarded;
  final String localFilePath;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    this.fileUrl = '',
    this.fileName = '',
    this.fileSize = 0,
    this.duration = 0,
    this.repliedToMessageId = '',
    this.repliedToMessageContent = '',
    this.reactions = const {},
    this.starredBy = const [],
    this.isForwarded = false,
    this.localFilePath = '',
  });

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    content,
    type,
    timestamp,
    status,
    fileUrl,
    fileName,
    fileSize,
    duration,
    repliedToMessageId,
    repliedToMessageContent,
    reactions,
    starredBy,
    isForwarded,
  ];
}
