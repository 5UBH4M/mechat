import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  
  UserEntity? get currentUser;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onVerificationFailed,
    required void Function(String verificationId) onAutoVerify,
  });

  Future<UserEntity> signInWithOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signOut();
}
