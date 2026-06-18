import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String phoneNumber;
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

  const UserEntity({
    required this.uid,
    required this.phoneNumber,
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
  });

  @override
  List<Object?> get props => [
        uid,
        phoneNumber,
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
      ];
}
