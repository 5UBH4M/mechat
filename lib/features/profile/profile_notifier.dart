import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/service_providers.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../auth/auth_notifier.dart';

enum ProfileStatus { initial, loading, success, error }

class ProfileState {
  final ProfileStatus status;
  final String? errorMessage;

  const ProfileState({
    required this.status,
    this.errorMessage,
  });

  factory ProfileState.initial() => const ProfileState(status: ProfileStatus.initial);
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _profileRepository;
  final Ref _ref;

  ProfileNotifier(this._profileRepository, this._ref) : super(ProfileState.initial());

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
        state = const ProfileState(status: ProfileStatus.error, errorMessage: 'User session not found.');
        return;
      }

      String profilePicUrl = currentUser.profilePictureUrl;
      if (localImagePath != null && localImagePath.isNotEmpty) {
        profilePicUrl = await _profileRepository.uploadProfilePicture(localImagePath, currentUser.uid);
      }

      final updatedUser = UserEntity(
        uid: currentUser.uid,
        phoneNumber: currentUser.phoneNumber,
        username: username.toLowerCase().trim(),
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
      );

      await _profileRepository.createUserProfile(updatedUser);
      
      // Refresh auth state details
      _ref.read(authNotifierProvider.notifier).init();
      
      state = const ProfileState(status: ProfileStatus.success);
    } catch (e) {
      state = ProfileState(status: ProfileStatus.error, errorMessage: e.toString());
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
  }) async {
    try {
      final authState = _ref.read(authNotifierProvider);
      final currentUser = authState.user;
      if (currentUser == null) return;

      final updatedUser = UserEntity(
        uid: currentUser.uid,
        phoneNumber: currentUser.phoneNumber,
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
      );

      await _profileRepository.createUserProfile(updatedUser);
      _ref.read(authNotifierProvider.notifier).init();
    } catch (_) {}
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repo, ref);
});
