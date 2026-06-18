import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/service_providers.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, codeSent, authenticated, profileIncomplete, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? verificationId;
  final int? resendToken;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.verificationId,
    this.resendToken,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    String? verificationId,
    int? resendToken,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial()) {
    init();
  }

  void init() {
    _authRepository.authStateChanges.listen((user) {
      if (user == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else if (user.displayName.isEmpty) {
        state = AuthState(status: AuthStatus.profileIncomplete, user: user);
      } else {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      }
    });
  }

  void updateUser(UserEntity user) {
    state = state.copyWith(user: user);
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authRepository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            status: AuthStatus.codeSent,
            verificationId: verificationId,
            resendToken: resendToken,
          );
        },
        onVerificationFailed: (err) {
          state = state.copyWith(status: AuthStatus.error, errorMessage: err);
        },
        onAutoVerify: (verificationId) {
          // Handled automatically or transit into loaded
        },
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> verifyOtp(String smsCode) async {
    final verId = state.verificationId;
    if (verId == null) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Verification ID missing.');
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _authRepository.signInWithOtp(
        verificationId: verId,
        smsCode: smsCode,
      );

      if (user.displayName.isEmpty) {
        state = AuthState(status: AuthStatus.profileIncomplete, user: user);
      } else {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _authRepository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepo);
});
