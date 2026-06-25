import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.type,
    required super.timestamp,
    required super.status,
    super.fileUrl = '',
    super.fileName = '',
    super.fileSize = 0,
    super.duration = 0,
    super.repliedToMessageId = '',
    super.repliedToMessageContent = '',
    super.reactions = const {},
    super.starredBy = const [],
    super.isForwarded = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final reactionsMap = json['reactions'] as Map<dynamic, dynamic>? ?? {};

    return MessageModel(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      timestamp: _parseDateTime(json['timestamp']),
      status: json['status'] as String? ?? 'sending',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      repliedToMessageId: json['repliedToMessageId'] as String? ?? '',
      repliedToMessageContent: json['repliedToMessageContent'] as String? ?? '',
      reactions: reactionsMap.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      starredBy:
          (json['starredBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isForwarded: json['isForwarded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'duration': duration,
      'repliedToMessageId': repliedToMessageId,
      'repliedToMessageContent': repliedToMessageContent,
      'reactions': reactions,
      'starredBy': starredBy,
      'isForwarded': isForwarded,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'duration': duration,
      'repliedToMessageId': repliedToMessageId,
      'repliedToMessageContent': repliedToMessageContent,
      'reactions': reactions,
      'starredBy': starredBy,
      'isForwarded': isForwarded,
    };
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.now();
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    String? type,
    DateTime? timestamp,
    String? status,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    int? duration,
    String? repliedToMessageId,
    String? repliedToMessageContent,
    Map<String, String>? reactions,
    List<String>? starredBy,
    bool? isForwarded,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      repliedToMessageId: repliedToMessageId ?? this.repliedToMessageId,
      repliedToMessageContent:
          repliedToMessageContent ?? this.repliedToMessageContent,
      reactions: reactions ?? this.reactions,
      starredBy: starredBy ?? this.starredBy,
      isForwarded: isForwarded ?? this.isForwarded,
    );
  }
}
