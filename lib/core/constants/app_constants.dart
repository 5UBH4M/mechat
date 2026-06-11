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

  static const Map<String, dynamic> iceServers = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      },
      {
        'urls': [
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      }
    ]
  };

  // UI Default Values
  static const String defaultAbout = 'Hey there! I am using MeChat.';
  static const String notesToSelfId = 'notes_to_self';
  static const String notesToSelfName = 'Notes to Self';
}
