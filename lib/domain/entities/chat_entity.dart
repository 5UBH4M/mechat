import 'package:equatable/equatable.dart';
import 'message_entity.dart';

class ChatEntity extends Equatable {
  final String id;
  final List<String> participants;
  final MessageEntity? lastMessage;
  final Map<String, int> unreadCounts;
  final Map<String, bool> typingStatus;
  final bool isNotesToSelf;
  final int
  disappearingTimer; // 0 means disabled, otherwise duration in seconds
  final bool isConnectionEstablished;
  final String connectionRequestedBy;

  const ChatEntity({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCounts,
    required this.typingStatus,
    this.isNotesToSelf = false,
    this.disappearingTimer = 0,
    this.isConnectionEstablished = false,
    this.connectionRequestedBy = '',
  });

  @override
  List<Object?> get props => [
    id,
    participants,
    lastMessage,
    unreadCounts,
    typingStatus,
    isNotesToSelf,
    disappearingTimer,
    isConnectionEstablished,
    connectionRequestedBy,
  ];
}
