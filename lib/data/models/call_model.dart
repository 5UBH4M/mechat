import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/call_entity.dart';

class CallModel extends CallEntity {
  const CallModel({
    required super.id,
    required super.callerId,
    required super.callerName,
    required super.receiverId,
    required super.type,
    required super.status,
    required super.createdAt,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'] as String? ?? '',
      callerId: json['callerId'] as String? ?? '',
      callerName: json['callerName'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      type: json['type'] as String? ?? 'voice',
      status: json['status'] as String? ?? 'dialing',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'type': type,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'type': type,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.now();
  }

  CallModel copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? receiverId,
    String? type,
    String? status,
    DateTime? createdAt,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
