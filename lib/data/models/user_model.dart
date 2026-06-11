import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.phoneNumber,
    required super.username,
    required super.displayName,
    required super.profilePictureUrl,
    required super.about,
    required super.isOnline,
    required super.lastSeen,
    required super.createdAt,
    required super.publicKey,
    required super.blockedUsers,
    required super.pushToken,
    super.readReceiptsEnabled = true,
    super.lastSeenVisible = true,
    super.profilePhotoVisible = true,
    super.connectedTo = '',
    super.disconnectRequested = false,
    super.previouslyConnected = const [],
    super.showPreviousConnectionsVisible = true,
    super.autoAcceptCalls = true,
    super.disableMute = false,
    super.disableCameraOff = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String? ?? '',
      about: json['about'] as String? ?? 'Hey there! I am using MeChat.',
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: _parseDateTime(json['lastSeen']),
      createdAt: _parseDateTime(json['createdAt']),
      publicKey: json['publicKey'] as String? ?? '',
      blockedUsers: (json['blockedUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      pushToken: json['pushToken'] as String? ?? '',
      readReceiptsEnabled: json['readReceiptsEnabled'] as bool? ?? true,
      lastSeenVisible: json['lastSeenVisible'] as bool? ?? true,
      profilePhotoVisible: json['profilePhotoVisible'] as bool? ?? true,
      connectedTo: json['connectedTo'] as String? ?? '',
      disconnectRequested: json['disconnectRequested'] as bool? ?? false,
      previouslyConnected: (json['previouslyConnected'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      showPreviousConnectionsVisible: json['showPreviousConnectionsVisible'] as bool? ?? true,
      autoAcceptCalls: json['autoAcceptCalls'] as bool? ?? true,
      disableMute: json['disableMute'] as bool? ?? false,
      disableCameraOff: json['disableCameraOff'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'username': username,
      'displayName': displayName,
      'profilePictureUrl': profilePictureUrl,
      'about': about,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'publicKey': publicKey,
      'blockedUsers': blockedUsers,
      'pushToken': pushToken,
      'readReceiptsEnabled': readReceiptsEnabled,
      'lastSeenVisible': lastSeenVisible,
      'profilePhotoVisible': profilePhotoVisible,
      'connectedTo': connectedTo,
      'disconnectRequested': disconnectRequested,
      'previouslyConnected': previouslyConnected,
      'showPreviousConnectionsVisible': showPreviousConnectionsVisible,
      'autoAcceptCalls': autoAcceptCalls,
      'disableMute': disableMute,
      'disableCameraOff': disableCameraOff,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'username': username,
      'displayName': displayName,
      'profilePictureUrl': profilePictureUrl,
      'about': about,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'createdAt': Timestamp.fromDate(createdAt),
      'publicKey': publicKey,
      'blockedUsers': blockedUsers,
      'pushToken': pushToken,
      'readReceiptsEnabled': readReceiptsEnabled,
      'lastSeenVisible': lastSeenVisible,
      'profilePhotoVisible': profilePhotoVisible,
      'connectedTo': connectedTo,
      'disconnectRequested': disconnectRequested,
      'previouslyConnected': previouslyConnected,
      'showPreviousConnectionsVisible': showPreviousConnectionsVisible,
      'autoAcceptCalls': autoAcceptCalls,
      'disableMute': disableMute,
      'disableCameraOff': disableCameraOff,
    };
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.now();
  }

  UserModel copyWith({
    String? uid,
    String? phoneNumber,
    String? username,
    String? displayName,
    String? profilePictureUrl,
    String? about,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    String? publicKey,
    List<String>? blockedUsers,
    String? pushToken,
    bool? readReceiptsEnabled,
    bool? lastSeenVisible,
    bool? profilePhotoVisible,
    String? connectedTo,
    bool? disconnectRequested,
    List<String>? previouslyConnected,
    bool? showPreviousConnectionsVisible,
    bool? autoAcceptCalls,
    bool? disableMute,
    bool? disableCameraOff,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      about: about ?? this.about,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      publicKey: publicKey ?? this.publicKey,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      pushToken: pushToken ?? this.pushToken,
      readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
      lastSeenVisible: lastSeenVisible ?? this.lastSeenVisible,
      profilePhotoVisible: profilePhotoVisible ?? this.profilePhotoVisible,
      connectedTo: connectedTo ?? this.connectedTo,
      disconnectRequested: disconnectRequested ?? this.disconnectRequested,
      previouslyConnected: previouslyConnected ?? this.previouslyConnected,
      showPreviousConnectionsVisible: showPreviousConnectionsVisible ?? this.showPreviousConnectionsVisible,
      autoAcceptCalls: autoAcceptCalls ?? this.autoAcceptCalls,
      disableMute: disableMute ?? this.disableMute,
      disableCameraOff: disableCameraOff ?? this.disableCameraOff,
    );
  }
}
