import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String type; // 'text', 'image', 'video', 'audio', 'document'
  final DateTime timestamp;
  final String status; // 'sending', 'sent', 'delivered', 'read'
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final int duration; // for audio/video duration in seconds
  final String repliedToMessageId;
  final String repliedToMessageContent;
  final Map<String, String> reactions; // userId -> emoji
  final List<String> starredBy; // List of userIds who starred this message
  final bool isForwarded;
  final String localFilePath; // Client-only: for optimistic image preview

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
