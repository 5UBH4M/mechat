import 'package:cloud_firestore/cloud_firestore.dart';

class AppConstants {
  static const String appName = 'MeChat';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String callsCollection = 'calls';
  static const String iceCandidatesCollection = 'ice_candidates';

  // Hive Box Names
  static const String userBoxName = 'user_box';
  static const String chatCacheBoxName = 'chat_cache_box';
  static const String settingsBoxName = 'settings_box';
  static const String offlineOutboxBoxName = 'offline_outbox_box';

  // Hive Keys
  static const String keyAuthUser = 'auth_user';
  static const String keyThemeMode = 'theme_mode';
  static const String keyE2EPrivateKey = 'e2e_private_key';
  static const String keyE2EPublicKey = 'e2e_public_key';
  static const String keyNotificationSettings = 'notifications_enabled';

  static const String appConfigCollection = 'app_config';
  static const String webrtcConfigDocument = 'webrtc';

  static const Map<String, dynamic> fallbackIceServers = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
    ],
  };

  static Future<Map<String, dynamic>> getIceServers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(appConfigCollection)
        .doc(webrtcConfigDocument)
        .get();

    final data = snapshot.data();
    final iceServers = data?['iceServers'];
    if (iceServers is List && iceServers.isNotEmpty) {
      return {'iceServers': iceServers};
    }

    return fallbackIceServers;
  }

  // UI Default Values
  static const String defaultAbout = 'Hey there! I am using MeChat.';
  static const String notesToSelfId = 'notes_to_self';
  static const String notesToSelfName = 'Notes to Self';
}
