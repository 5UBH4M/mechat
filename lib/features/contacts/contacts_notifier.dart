import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/service_providers.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/contact_repository.dart';
import '../auth/auth_notifier.dart';

enum ContactOpsStatus { initial, loading, success, error }

class ContactsState {
  final ContactOpsStatus status;
  final UserEntity? searchResult;
  final List<UserEntity> blockedUsers;
  final String? errorMessage;

  const ContactsState({
    required this.status,
    this.searchResult,
    this.blockedUsers = const [],
    this.errorMessage,
  });

  factory ContactsState.initial() => const ContactsState(status: ContactOpsStatus.initial);

  ContactsState copyWith({
    ContactOpsStatus? status,
    UserEntity? searchResult,
    List<UserEntity>? blockedUsers,
    String? errorMessage,
  }) {
    return ContactsState(
      status: status ?? this.status,
      searchResult: searchResult, // Can be set to null
      blockedUsers: blockedUsers ?? this.blockedUsers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  final ContactRepository _contactRepository;
  final Ref _ref;

  ContactsNotifier(this._contactRepository, this._ref) : super(ContactsState.initial());

  Future<void> searchUser(String username) async {
    state = state.copyWith(status: ContactOpsStatus.loading, searchResult: null);
    try {
      final user = await _contactRepository.searchUserByUsername(username);
      if (user == null) {
        state = state.copyWith(status: ContactOpsStatus.error, errorMessage: 'User not found.');
      } else {
        state = state.copyWith(status: ContactOpsStatus.success, searchResult: user);
      }
    } catch (e) {
      state = state.copyWith(status: ContactOpsStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> blockUser(String blockUid) async {
    final currentUser = _ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    state = state.copyWith(status: ContactOpsStatus.loading);
    try {
      await _contactRepository.blockUser(currentUser.uid, blockUid);
      state = state.copyWith(status: ContactOpsStatus.success);
      loadBlockedUsers();
    } catch (e) {
      state = state.copyWith(status: ContactOpsStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> unblockUser(String unblockUid) async {
    final currentUser = _ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    state = state.copyWith(status: ContactOpsStatus.loading);
    try {
      await _contactRepository.unblockUser(currentUser.uid, unblockUid);
      state = state.copyWith(status: ContactOpsStatus.success);
      loadBlockedUsers();
    } catch (e) {
      state = state.copyWith(status: ContactOpsStatus.error, errorMessage: e.toString());
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
      state = state.copyWith(status: ContactOpsStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> loadBlockedUsers() async {
    final currentUser = _ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    try {
      // Reload current user to get fresh blocked list
      final freshProfile = await _ref.read(profileRepositoryProvider).getUserProfile(currentUser.uid);
      final blockedUids = freshProfile?.blockedUsers ?? currentUser.blockedUsers;
      
      final list = await _contactRepository.getBlockedUsers(blockedUids);
      state = state.copyWith(blockedUsers: list);
    } catch (_) {}
  }

  Future<void> connectWithUser(String targetUid) async {
    final currentUser = _ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    state = state.copyWith(status: ContactOpsStatus.loading);
    try {
      
      state = state.copyWith(status: ContactOpsStatus.success);
    } catch (e) {
      state = state.copyWith(status: ContactOpsStatus.error, errorMessage: e.toString());
    }
  }
}

final contactsNotifierProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return ContactsNotifier(repo, ref);
});
