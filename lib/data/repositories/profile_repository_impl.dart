
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/image_helper.dart';
import '../../core/services/hive_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final HiveService _hive = HiveService();

  @override
  Future<UserEntity?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final model = UserModel.fromJson(doc.data()!);
        await _hive.saveUser(model.toJson());
        return model;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> createUserProfile(UserEntity user) async {
    final model = UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber,
      username: user.username,
      displayName: user.displayName,
      profilePictureUrl: user.profilePictureUrl,
      about: user.about,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
      createdAt: user.createdAt,
      publicKey: user.publicKey,
      blockedUsers: user.blockedUsers,
      pushToken: user.pushToken,
      readReceiptsEnabled: user.readReceiptsEnabled,
      lastSeenVisible: user.lastSeenVisible,
      profilePhotoVisible: user.profilePhotoVisible,
      connectedTo: user.connectedTo,
      disconnectRequested: user.disconnectRequested,
      previouslyConnected: user.previouslyConnected,
      showPreviousConnectionsVisible: user.showPreviousConnectionsVisible,
      hideContactPhotoInChat: user.hideContactPhotoInChat,
      hideContactNameInChat: user.hideContactNameInChat,
      autoAcceptCalls: user.autoAcceptCalls,
      disableMute: user.disableMute,
      disableCameraOff: user.disableCameraOff,
    );

    await _db.collection(AppConstants.usersCollection).doc(user.uid).set(model.toFirestore());
    await _hive.saveUser(model.toJson());
  }

  @override
  Future<void> updateUserProfile(UserEntity user) async {
    final model = UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber,
      username: user.username,
      displayName: user.displayName,
      profilePictureUrl: user.profilePictureUrl,
      about: user.about,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
      createdAt: user.createdAt,
      publicKey: user.publicKey,
      blockedUsers: user.blockedUsers,
      pushToken: user.pushToken,
      readReceiptsEnabled: user.readReceiptsEnabled,
      lastSeenVisible: user.lastSeenVisible,
      profilePhotoVisible: user.profilePhotoVisible,
      connectedTo: user.connectedTo,
      disconnectRequested: user.disconnectRequested,
      previouslyConnected: user.previouslyConnected,
      showPreviousConnectionsVisible: user.showPreviousConnectionsVisible,
      hideContactPhotoInChat: user.hideContactPhotoInChat,
      hideContactNameInChat: user.hideContactNameInChat,
      autoAcceptCalls: user.autoAcceptCalls,
      disableMute: user.disableMute,
      disableCameraOff: user.disableCameraOff,
    );

    await _db.collection(AppConstants.usersCollection).doc(user.uid).update(model.toFirestore());
    await _hive.saveUser(model.toJson());
  }

  @override
  Future<String> uploadProfilePicture(String filePath, String uid) async {
    return await ImageHelper.convertToBase64(filePath);
  }

  @override
  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    final data = {
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    };
    await _db.collection(AppConstants.usersCollection).doc(uid).update(data);
    
    // Update local user cache if it's the current user
    final currentUser = _hive.getUser();
    if (currentUser != null && currentUser['uid'] == uid) {
      final model = UserModel.fromJson(currentUser).copyWith(
        isOnline: isOnline,
        lastSeen: DateTime.now(),
      );
      await _hive.saveUser(model.toJson());
    }
  }
}
