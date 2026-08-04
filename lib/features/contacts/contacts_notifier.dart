import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/service_providers.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/contact_repository.dart';
import '../auth/auth_notifier.dart';

enum ContactOpsStatus { initial, loading, success, error }

class ContactsState {
  final ContactOpsStatus status;
  final UserEntity? searchResult;
  final String? errorMessage;

  const ContactsState({
    required this.status,
    this.searchResult,
    this.errorMessage,
  });

  factory ContactsState.initial() =>
      const ContactsState(status: ContactOpsStatus.initial);

  ContactsState copyWith({
    ContactOpsStatus? status,
    UserEntity? searchResult,
    String? errorMessage,
  }) {
    return ContactsState(
      status: status ?? this.status,
      searchResult: searchResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  final ContactRepository _contactRepository;
  final Ref _ref;

  ContactsNotifier(this._contactRepository, this._ref)
    : super(ContactsState.initial());

  Future<void> searchUser(String username) async {
    state = state.copyWith(
      status: ContactOpsStatus.loading,
      searchResult: null,
    );
    try {
      final user = await _contactRepository.searchUserByUsername(username);
      if (user == null) {
        state = state.copyWith(
          status: ContactOpsStatus.error,
          errorMessage: 'User not found.',
        );
      } else {
        state = state.copyWith(
          status: ContactOpsStatus.success,
          searchResult: user,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ContactOpsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }


  Future<void> reportUser(String reportedUid, String reason) async {
    final currentUser = _ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    state = state.copyWith(status: ContactOpsStatus.loading);
    try {
      await _contactRepository.reportUser(
        reporterUid: currentUser.uid,
        reportedUid: reportedUid,
        reason: reason,
      );
      state = state.copyWith(status: ContactOpsStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ContactOpsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }


  Future<void> connectWithUser(String targetUid) async {
    final currentUser = _ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    state = state.copyWith(status: ContactOpsStatus.loading);
    try {
      state = state.copyWith(status: ContactOpsStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ContactOpsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final contactsNotifierProvider =
    StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
      final repo = ref.watch(contactRepositoryProvider);
      return ContactsNotifier(repo, ref);
    });
