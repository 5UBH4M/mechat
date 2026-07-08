import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/hive_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as gsia;

class AuthRepositoryImpl implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_SIGN_IN_CLIENT_ID'] ?? '',
    serverClientId: kIsWeb ? null : dotenv.env['GOOGLE_SIGN_IN_SERVER_CLIENT_ID'],
  );
  gsia.GoogleSignIn? _googleSignInLinux;

  final HiveService _hive = HiveService();

  AuthRepositoryImpl() {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows)) {
      _googleSignInLinux = gsia.GoogleSignIn(
        params: gsia.GoogleSignInParams(
          clientId: dotenv.env['GOOGLE_SIGN_IN_LINUX_CLIENT_ID'] ?? '',
          clientSecret: dotenv.env['GOOGLE_SIGN_IN_LINUX_CLIENT_SECRET'] ?? '',
          redirectPort: 3000,
        ),
      );
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    try {
      return _auth.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser == null) {
          await _hive.clearUser();
          return null;
        }

        // Always try local cache first — instant, works offline
        final cached = _hive.getUser();
        if (cached != null) {
          // Refresh from Firestore in the background (non-blocking)
          _refreshUserFromFirestore(firebaseUser.uid);
          return UserModel.fromJson(cached);
        }

        // No cache — must fetch from Firestore (with timeout for offline safety)
        try {
          final doc = await _db
              .collection(AppConstants.usersCollection)
              .doc(firebaseUser.uid)
              .get(const GetOptions(source: Source.serverAndCache))
              .timeout(const Duration(seconds: 5));
          if (doc.exists) {
            UserModel model = UserModel.fromJson(doc.data() ?? {});

            try {
              final token = await NotificationService().getToken();
              if (token != null && token != model.pushToken) {
                await _db
                    .collection(AppConstants.usersCollection)
                    .doc(firebaseUser.uid)
                    .update({'pushToken': token});
                model = model.copyWith(pushToken: token);
              }
            } catch (_) {}

            await _hive.saveUser(model.toJson());
            return model;
          }
        } catch (_) {}

        // Return a temporary user for profile creation
        return UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
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

  /// Refreshes user data from Firestore and updates local cache (non-blocking)
  Future<void> _refreshUserFromFirestore(String uid) async {
    try {
      final doc = await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        UserModel model = UserModel.fromJson(doc.data() ?? {});
        try {
          final token = await NotificationService().getToken();
          if (token != null && token != model.pushToken) {
            await _db.collection(AppConstants.usersCollection).doc(uid).update({
              'pushToken': token,
            });
            model = model.copyWith(pushToken: token);
          }
        } catch (_) {}
        await _hive.saveUser(model.toJson());
      }
    } catch (_) {}
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
        email: fbUser.email ?? '',
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
  Future<void> signInWithGoogle({
    required void Function(String error) onSignInFailed,
  }) async {
    try {
      OAuthCredential credential;
      
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows)) {
        if (_googleSignInLinux == null) {
          onSignInFailed('Linux sign in not initialized');
          return;
        }
        final credentials = await _googleSignInLinux!.signIn();
        if (credentials == null) {
          onSignInFailed('Sign in aborted by user');
          return;
        }
        credential = GoogleAuthProvider.credential(
          accessToken: credentials.accessToken,
          idToken: null, // Often null for desktop offline flow
        );
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          onSignInFailed('Sign in aborted by user');
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      }

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        onSignInFailed('Failed to sign in with Google');
        return;
      }

      // Check if user profile already exists
      final userDoc = await _db
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      UserModel userModel;
      if (userDoc.exists) {
        userModel = UserModel.fromJson(userDoc.data() ?? {});
      } else {
        userModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          username: '',
          displayName: firebaseUser.displayName ?? '',
          profilePictureUrl: firebaseUser.photoURL ?? '',
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
    } catch (e) {
      onSignInFailed(e.toString());
    }
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

    await _googleSignIn.signOut();
    await _auth.signOut();
    await _hive.clearAllCache();
  }
}
