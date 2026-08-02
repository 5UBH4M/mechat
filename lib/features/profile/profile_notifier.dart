import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/service_providers.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../auth/auth_notifier.dart';

enum ProfileStatus { initial, loading, success, error }

class ProfileState {
  final ProfileStatus status;
  final String? errorMessage;

  const ProfileState({required this.status, this.errorMessage});

  factory ProfileState.initial() =>
      const ProfileState(status: ProfileStatus.initial);
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _profileRepository;
  final Ref _ref;

  ProfileNotifier(this._profileRepository, this._ref)
    : super(ProfileState.initial());

  Future<void> saveProfile({
    required String username,
    required String displayName,
    required String about,
    String? localImagePath,
  }) async {
    state = const ProfileState(status: ProfileStatus.loading);
    try {
      final authState = _ref.read(authNotifierProvider);
      final currentUser = authState.user;
      if (currentUser == null) {
        state = const ProfileState(
          status: ProfileStatus.error,
          errorMessage: 'User session not found.',
        );
        return;
      }

      final trimmedUsername = username.trim();


      final usernameRegex = RegExp(r'^[a-zA-Z0-9._-]+$');
      if (!usernameRegex.hasMatch(trimmedUsername)) {
        state = const ProfileState(
          status: ProfileStatus.error,
          errorMessage:
              'Username can only contain letters, numbers, underscores, hyphens, and dots.',
        );
        return;
      }

      if (trimmedUsername.contains(' ')) {
        state = const ProfileState(
          status: ProfileStatus.error,
          errorMessage: 'Username cannot contain spaces.',
        );
        return;
      }

      if (trimmedUsername.length < 5 || trimmedUsername.length > 20) {
        state = const ProfileState(
          status: ProfileStatus.error,
          errorMessage: 'Username must be 5-20 characters.',
        );
        return;
      }


      final effectiveUsername = (currentUser.username.isNotEmpty)
          ? currentUser.username
          : trimmedUsername;


      final db = FirebaseFirestore.instance;
      final existingUsers = await db
          .collection('users')
          .where('username', isEqualTo: effectiveUsername)
          .limit(1)
          .get();

      if (existingUsers.docs.isNotEmpty &&
          existingUsers.docs.first.id != currentUser.uid) {
        state = const ProfileState(
          status: ProfileStatus.error,
          errorMessage: 'Username is already taken.',
        );
        return;
      }

      String profilePicUrl = currentUser.profilePictureUrl;
      if (localImagePath != null && localImagePath.isNotEmpty) {
        profilePicUrl = await _profileRepository.uploadProfilePicture(
          localImagePath,
          currentUser.uid,
        );
      }

      final updatedUser = UserEntity(
        uid: currentUser.uid,
        email: currentUser.email,
        username: effectiveUsername,
        displayName: displayName,
        profilePictureUrl: profilePicUrl,
        about: about,
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: currentUser.createdAt,
        publicKey: currentUser.publicKey,
        blockedUsers: currentUser.blockedUsers,
        pushToken: currentUser.pushToken,
        readReceiptsEnabled: currentUser.readReceiptsEnabled,
        lastSeenVisible: currentUser.lastSeenVisible,
        profilePhotoVisible: currentUser.profilePhotoVisible,
        connectedTo: currentUser.connectedTo,
        disconnectRequested: currentUser.disconnectRequested,
        previouslyConnected: currentUser.previouslyConnected,
        showPreviousConnectionsVisible:
            currentUser.showPreviousConnectionsVisible,
        hideContactPhotoInChat: currentUser.hideContactPhotoInChat,
        hideContactNameInChat: currentUser.hideContactNameInChat,
        autoAcceptCalls: currentUser.autoAcceptCalls,
        disableMute: currentUser.disableMute,
        disableCameraOff: currentUser.disableCameraOff,
      );

      await _profileRepository.createUserProfile(updatedUser);

      _ref.read(authNotifierProvider.notifier).updateUser(updatedUser);

      state = const ProfileState(status: ProfileStatus.success);
    } catch (e) {
      state = ProfileState(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateOnlinePresence(bool isOnline) async {
    final authState = _ref.read(authNotifierProvider);
    final user = authState.user;
    if (user != null) {
      await _profileRepository.updateOnlineStatus(user.uid, isOnline);
    }
  }

  Future<void> updatePrivacySettings({
    required bool readReceiptsEnabled,
    required bool lastSeenVisible,
    required bool profilePhotoVisible,
    bool? showPreviousConnectionsVisible,
    bool? hideContactPhotoInChat,
    bool? hideContactNameInChat,
    bool? autoAcceptCalls,
    bool? disableMute,
    bool? disableCameraOff,
    bool? hideNotificationSender,
    bool? hideNotificationMessage,
    bool? alwaysSendHD,
  }) async {
    try {
      final authState = _ref.read(authNotifierProvider);
      final currentUser = authState.user;
      if (currentUser == null) return;

      final updatedUser = UserEntity(
        uid: currentUser.uid,
        email: currentUser.email,
        username: currentUser.username,
        displayName: currentUser.displayName,
        profilePictureUrl: currentUser.profilePictureUrl,
        about: currentUser.about,
        isOnline: currentUser.isOnline,
        lastSeen: currentUser.lastSeen,
        createdAt: currentUser.createdAt,
        publicKey: currentUser.publicKey,
        blockedUsers: currentUser.blockedUsers,
        pushToken: currentUser.pushToken,
        readReceiptsEnabled: readReceiptsEnabled,
        lastSeenVisible: lastSeenVisible,
        profilePhotoVisible: profilePhotoVisible,
        connectedTo: currentUser.connectedTo,
        disconnectRequested: currentUser.disconnectRequested,
        previouslyConnected: currentUser.previouslyConnected,
        showPreviousConnectionsVisible:
            showPreviousConnectionsVisible ??
            currentUser.showPreviousConnectionsVisible,
        hideContactPhotoInChat:
            hideContactPhotoInChat ?? currentUser.hideContactPhotoInChat,
        hideContactNameInChat:
            hideContactNameInChat ?? currentUser.hideContactNameInChat,
        autoAcceptCalls: autoAcceptCalls ?? currentUser.autoAcceptCalls,
        disableMute: disableMute ?? currentUser.disableMute,
        disableCameraOff: disableCameraOff ?? currentUser.disableCameraOff,
        hideNotificationSender:
            hideNotificationSender ?? currentUser.hideNotificationSender,
        hideNotificationMessage:
            hideNotificationMessage ?? currentUser.hideNotificationMessage,
        alwaysSendHD: alwaysSendHD ?? currentUser.alwaysSendHD,
      );

      await _profileRepository.createUserProfile(updatedUser);
      Future.microtask(() {
        _ref.read(authNotifierProvider.notifier).updateUser(updatedUser);
      });
    } catch (e) {
      state = ProfileState(
        status: ProfileStatus.error,
        errorMessage: 'Failed to update privacy settings: ${e.toString()}',
      );
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      final repo = ref.watch(profileRepositoryProvider);
      return ProfileNotifier(repo, ref);
    });
