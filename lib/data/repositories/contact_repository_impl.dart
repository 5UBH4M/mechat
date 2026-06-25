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
      // First try exact match
      var snap = await _db
          .collection(AppConstants.usersCollection)
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (snap.docs.isEmpty &&
          username.trim() != username.toLowerCase().trim()) {
        // Fallback to lowercase match if exact match fails
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
  Future<void> blockUser(String currentUid, String blockUid) async {
    await _db.collection(AppConstants.usersCollection).doc(currentUid).update({
      'blockedUsers': FieldValue.arrayUnion([blockUid]),
    });

    // Update local cache
    final localUser = _hive.getUser();
    if (localUser != null) {
      final model = UserModel.fromJson(localUser);
      final List<String> updatedBlocks = List.from(model.blockedUsers)
        ..add(blockUid);
      final updatedModel = model.copyWith(blockedUsers: updatedBlocks);
      await _hive.saveUser(updatedModel.toJson());
    }
  }

  @override
  Future<void> unblockUser(String currentUid, String unblockUid) async {
    await _db.collection(AppConstants.usersCollection).doc(currentUid).update({
      'blockedUsers': FieldValue.arrayRemove([unblockUid]),
    });

    // Update local cache
    final localUser = _hive.getUser();
    if (localUser != null) {
      final model = UserModel.fromJson(localUser);
      final List<String> updatedBlocks = List.from(model.blockedUsers)
        ..remove(unblockUid);
      final updatedModel = model.copyWith(blockedUsers: updatedBlocks);
      await _hive.saveUser(updatedModel.toJson());
    }
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

  @override
  Future<List<UserEntity>> getBlockedUsers(List<String> blockedUids) async {
    if (blockedUids.isEmpty) return [];

    final List<UserEntity> blockedUsers = [];
    // Firestore whereIn has a limit of 10 items, but for general messaging list it is fine.
    // Let's do chunking or fetch individually to make it fully production-grade.
    for (final uid in blockedUids) {
      try {
        final doc = await _db
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null) {
          blockedUsers.add(UserModel.fromJson(doc.data()!));
        }
      } catch (_) {}
    }
    return blockedUsers;
  }
}
