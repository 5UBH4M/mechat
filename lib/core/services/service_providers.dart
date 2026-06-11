import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/contact_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/contact_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import 'encryptor_service.dart';
import 'hive_service.dart';
import 'notification_service.dart';
import 'signaling_service.dart';

// Low-Level Services
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

final encryptorServiceProvider = Provider<EncryptorService>((ref) {
  return EncryptorService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final signalingServiceProvider = Provider<SignalingService>((ref) {
  return SignalingService();
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepositoryImpl();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl();
});
