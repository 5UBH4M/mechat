import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final HiveService _hive = HiveService();

  @override
  Stream<UserEntity?> get authStateChanges {
    try {
      return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        await _hive.clearUser();
        return null;
      }
      
      // Try to read local cache
      final cached = _hive.getUser();
      if (cached != null) {
        return UserModel.fromJson(cached);
      }

      // If no cache, fetch from Firestore
      try {
        final doc = await _db.collection(AppConstants.usersCollection).doc(firebaseUser.uid).get();
        if (doc.exists) {
          final model = UserModel.fromJson(doc.data()!);
          await _hive.saveUser(model.toJson());
          return model;
        }
      } catch (_) {}
      
      // Return a temporary user for profile creation
      return UserModel(
        uid: firebaseUser.uid,
        phoneNumber: firebaseUser.phoneNumber ?? '',
        username: '',
        displayName: '',
        profilePictureUrl: '',
        about: AppConstants.defaultAbout,
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
        publicKey: '',
        blockedUsers: const [],
        pushToken: '',
      );
    });
    } catch (e) {
      return Stream.value(null);
    }
  }

  @override
  UserEntity? get currentUser {
    final cached = _hive.getUser();
    if (cached != null) {
      return UserModel.fromJson(cached);
    }
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      return UserModel(
        uid: fbUser.uid,
        phoneNumber: fbUser.phoneNumber ?? '',
        username: '',
        displayName: '',
        profilePictureUrl: '',
        about: AppConstants.defaultAbout,
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
        publicKey: '',
        blockedUsers: const [],
        pushToken: '',
      );
    }
    return null;
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onVerificationFailed,
    required void Function(String verificationId) onAutoVerify,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (credential.smsCode != null) {
          final authResult = await _auth.signInWithCredential(credential);
          if (authResult.user != null) {
            onAutoVerify(credential.verificationId ?? '');
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onVerificationFailed(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Future<UserEntity> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    // Check if user profile already exists
    final userDoc = await _db.collection(AppConstants.usersCollection).doc(firebaseUser.uid).get();
    
    UserModel userModel;
    if (userDoc.exists) {
      userModel = UserModel.fromJson(userDoc.data()!);
    } else {
      userModel = UserModel(
        uid: firebaseUser.uid,
        phoneNumber: firebaseUser.phoneNumber ?? firebaseUser.uid,
        username: '',
        displayName: '',
        profilePictureUrl: '',
        about: AppConstants.defaultAbout,
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
        publicKey: '',
        blockedUsers: const [],
        pushToken: '',
      );
      // Wait to save to firestore until they complete the profile
    }

    await _hive.saveUser(userModel.toJson());
    return userModel;
  }

  @override
  Future<void> signOut() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        // Set offline status
        await _db.collection(AppConstants.usersCollection).doc(uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}

    await _auth.signOut();
    await _hive.clearAllCache();
  }
}
