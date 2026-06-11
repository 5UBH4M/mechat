import 'package:equatable/equatable.dart';

class CallEntity extends Equatable {
  final String id;
  final String callerId;
  final String callerName;
  final String receiverId;
  final String type; // 'voice', 'video'
  final String status; // 'dialing', 'ringing', 'connected', 'ended', 'rejected', 'missed'
  final DateTime createdAt;

  const CallEntity({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        callerId,
        callerName,
        receiverId,
        type,
        status,
        createdAt,
      ];
}
