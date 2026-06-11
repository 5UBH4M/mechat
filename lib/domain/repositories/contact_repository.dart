import '../entities/user_entity.dart';

abstract class ContactRepository {
  Future<UserEntity?> searchUserByUsername(String username);

  Future<void> blockUser(String currentUid, String blockUid);

  Future<void> unblockUser(String currentUid, String unblockUid);

  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    required String reason,
  });

  Future<List<UserEntity>> getBlockedUsers(List<String> blockedUids);
}
