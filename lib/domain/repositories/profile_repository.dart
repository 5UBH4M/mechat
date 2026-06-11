import '../entities/user_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity?> getUserProfile(String uid);

  Future<void> createUserProfile(UserEntity user);

  Future<void> updateUserProfile(UserEntity user);

  Future<String> uploadProfilePicture(String filePath, String uid);

  Future<void> updateOnlineStatus(String uid, bool isOnline);
}
