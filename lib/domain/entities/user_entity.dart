import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String profilePictureUrl;
  final String about;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;
  final String publicKey;
  final List<String> blockedUsers;
  final String pushToken;
  final bool readReceiptsEnabled;
  final bool lastSeenVisible;
  final bool profilePhotoVisible;
  final String connectedTo;
  final bool disconnectRequested;
  final List<String> previouslyConnected;
  final bool showPreviousConnectionsVisible;
  final bool hideContactPhotoInChat;
  final bool hideContactNameInChat;

  final bool autoAcceptCalls;
  final bool disableMute;
  final bool disableCameraOff;

  final bool hideNotificationSender;
  final bool hideNotificationMessage;

  final bool alwaysSendHD;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    required this.profilePictureUrl,
    required this.about,
    required this.isOnline,
    required this.lastSeen,
    required this.createdAt,
    required this.publicKey,
    required this.blockedUsers,
    required this.pushToken,
    this.readReceiptsEnabled = true,
    this.lastSeenVisible = true,
    this.profilePhotoVisible = true,
    this.connectedTo = '',
    this.disconnectRequested = false,
    this.previouslyConnected = const [],
    this.showPreviousConnectionsVisible = true,
    this.hideContactPhotoInChat = false,
    this.hideContactNameInChat = false,
    this.autoAcceptCalls = true,
    this.disableMute = true,
    this.disableCameraOff = true,
    this.hideNotificationSender = false,
    this.hideNotificationMessage = false,
    this.alwaysSendHD = false,
  });

  @override
  List<Object?> get props => [
    uid,
    email,
    username,
    displayName,
    profilePictureUrl,
    about,
    isOnline,
    lastSeen,
    createdAt,
    publicKey,
    blockedUsers,
    pushToken,
    readReceiptsEnabled,
    lastSeenVisible,
    profilePhotoVisible,
    connectedTo,
    disconnectRequested,
    previouslyConnected,
    showPreviousConnectionsVisible,
    hideContactPhotoInChat,
    hideContactNameInChat,
    autoAcceptCalls,
    disableMute,
    disableCameraOff,
    hideNotificationSender,
    hideNotificationMessage,
    alwaysSendHD,
  ];

  UserEntity copyWith({
    String? uid,
    String? email,
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
    bool? hideContactPhotoInChat,
    bool? hideContactNameInChat,
    bool? autoAcceptCalls,
    bool? disableMute,
    bool? disableCameraOff,
    bool? hideNotificationSender,
    bool? hideNotificationMessage,
    bool? alwaysSendHD,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
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
      hideContactPhotoInChat: hideContactPhotoInChat ?? this.hideContactPhotoInChat,
      hideContactNameInChat: hideContactNameInChat ?? this.hideContactNameInChat,
      autoAcceptCalls: autoAcceptCalls ?? this.autoAcceptCalls,
      disableMute: disableMute ?? this.disableMute,
      disableCameraOff: disableCameraOff ?? this.disableCameraOff,
      hideNotificationSender: hideNotificationSender ?? this.hideNotificationSender,
      hideNotificationMessage: hideNotificationMessage ?? this.hideNotificationMessage,
      alwaysSendHD: alwaysSendHD ?? this.alwaysSendHD,
    );
  }
}
