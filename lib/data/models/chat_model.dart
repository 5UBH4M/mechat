import '../../domain/entities/chat_entity.dart';
import 'message_model.dart';

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.participants,
    super.lastMessage,
    required super.unreadCounts,
    required super.typingStatus,
    super.isNotesToSelf = false,
    super.disappearingTimer = 0,
    super.isConnectionEstablished = false,
    super.connectionRequestedBy = '',
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final lastMsgData = json['lastMessage'] as Map<String, dynamic>?;

    // Parse maps defensively
    final unreadMap = json['unreadCounts'] as Map<dynamic, dynamic>? ?? {};
    final typingMap = json['typingStatus'] as Map<dynamic, dynamic>? ?? {};

    return ChatModel(
      id: json['id'] as String? ?? '',
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastMessage: lastMsgData != null
          ? MessageModel.fromJson(lastMsgData)
          : null,
      unreadCounts: unreadMap.map(
        (key, value) => MapEntry(key.toString(), value as int),
      ),
      typingStatus: typingMap.map(
        (key, value) => MapEntry(key.toString(), value as bool),
      ),
      isNotesToSelf: json['isNotesToSelf'] as bool? ?? false,
      disappearingTimer: json['disappearingTimer'] as int? ?? 0,
      isConnectionEstablished:
          json['isConnectionEstablished'] as bool? ?? false,
      connectionRequestedBy: json['connectionRequestedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage != null
          ? (lastMessage as MessageModel).toJson()
          : null,
      'unreadCounts': unreadCounts,
      'typingStatus': typingStatus,
      'isNotesToSelf': isNotesToSelf,
      'disappearingTimer': disappearingTimer,
      'isConnectionEstablished': isConnectionEstablished,
      'connectionRequestedBy': connectionRequestedBy,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage != null
          ? (lastMessage as MessageModel).toFirestore()
          : null,
      'unreadCounts': unreadCounts,
      'typingStatus': typingStatus,
      'isNotesToSelf': isNotesToSelf,
      'disappearingTimer': disappearingTimer,
      'isConnectionEstablished': isConnectionEstablished,
      'connectionRequestedBy': connectionRequestedBy,
    };
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    MessageModel? lastMessage,
    Map<String, int>? unreadCounts,
    Map<String, bool>? typingStatus,
    bool? isNotesToSelf,
    int? disappearingTimer,
    bool? isConnectionEstablished,
    String? connectionRequestedBy,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      typingStatus: typingStatus ?? this.typingStatus,
      isNotesToSelf: isNotesToSelf ?? this.isNotesToSelf,
      disappearingTimer: disappearingTimer ?? this.disappearingTimer,
      isConnectionEstablished:
          isConnectionEstablished ?? this.isConnectionEstablished,
      connectionRequestedBy:
          connectionRequestedBy ?? this.connectionRequestedBy,
    );
  }
}
