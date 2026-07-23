import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/service_providers.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  codeSent,
  authenticated,
  profileIncomplete,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? Function()? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<UserEntity?>? _authSub;

  AuthNotifier(this._authRepository) : super(_getInitialState(_authRepository)) {
    init();
  }

  static AuthState _getInitialState(AuthRepository repo) {
    final user = repo.currentUser;
    if (user == null) return const AuthState(status: AuthStatus.initial);
    if (user.username.isEmpty) return AuthState(status: AuthStatus.profileIncomplete, user: user);
    return AuthState(status: AuthStatus.authenticated, user: user);
  }

  void init() {
    _authSub?.cancel();
    _authSub = _authRepository.authStateChanges.listen((user) {
      if (user == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else if (user.username.isEmpty) {
        state = AuthState(status: AuthStatus.profileIncomplete, user: user);
      } else {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void updateUser(UserEntity user) {
    state = state.copyWith(user: user);
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: () => null,
    );
    try {
      await _authRepository.signInWithGoogle(
        onSignInFailed: (err) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: () => err,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authRepository.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: () => 'Failed to sign out: ${e.toString()}',
      );
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepo);
});
