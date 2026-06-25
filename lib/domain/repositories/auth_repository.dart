import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;

  UserEntity? get currentUser;

  Future<void> signInWithGoogle({
    required void Function(String error) onSignInFailed,
  });

  Future<void> signOut();
}
