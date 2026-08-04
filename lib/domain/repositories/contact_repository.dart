import '../entities/user_entity.dart';

abstract class ContactRepository {
  Future<UserEntity?> searchUserByUsername(String username);


  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    required String reason,
  });


}
