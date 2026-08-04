import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/contact_repository.dart';
import '../models/user_model.dart';

class ContactRepositoryImpl implements ContactRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final HiveService _hive = HiveService();

  @override
  Future<UserEntity?> searchUserByUsername(String username) async {
    try {

      var snap = await _db
          .collection(AppConstants.usersCollection)
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (snap.docs.isEmpty &&
          username.trim() != username.toLowerCase().trim()) {

        snap = await _db
            .collection(AppConstants.usersCollection)
            .where('username', isEqualTo: username.toLowerCase().trim())
            .limit(1)
            .get();
      }

      if (snap.docs.isNotEmpty) {
        return UserModel.fromJson(snap.docs.first.data());
      }
    } catch (_) {}
    return null;
  }


  @override
  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    required String reason,
  }) async {
    await _db.collection('reports').add({
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

}
