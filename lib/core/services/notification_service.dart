import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    dev.log("Handling background message: ${message.messageId}");
  }
  // FCM will auto-display the notification from the `notification` payload
  // sent by our Cloud Function, so we don't need to do anything extra here.
}

/// Global callback for notification tap — set from MeChatApp
typedef NotificationTapCallback = void Function(String? payload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationTapCallback? _onNotificationTap;

  /// Queued initial payload when app launched from terminated state
  /// before onNotificationTap callback is set.
  String? _pendingInitialPayload;

  set onNotificationTap(NotificationTapCallback? callback) {
    _onNotificationTap = callback;
    // Replay any queued initial payload
    if (callback != null && _pendingInitialPayload != null) {
      callback(_pendingInitialPayload);
      _pendingInitialPayload = null;
    }
  }

  NotificationTapCallback? get onNotificationTap => _onNotificationTap;

  Future<void> init() async {
    try {
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'mechat_channel',
        'MeChat Messages',
        description: 'Notifications for new messages',
        importance: Importance.max,
      );

      const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
        'mechat_incoming_call',
        'Incoming Calls',
        description: 'Full-screen notifications for incoming calls',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(channel);
      await androidPlugin?.createNotificationChannel(callChannel);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          dev.log("Foreground FCM message received: ${message.messageId}");
        }
      });

      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        final senderId = initialMessage.data['senderId'];
        if (senderId != null && senderId.isNotEmpty) {
          final route = '/chat/$senderId';
          if (_onNotificationTap != null) {
            _onNotificationTap!(route);
          } else {
            _pendingInitialPayload = route;
          }
        }
      }

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final senderId = message.data['senderId'];
        if (senderId != null && _onNotificationTap != null) {
          _onNotificationTap!('/chat/$senderId');
        }
      });

      try {
        final token = await _fcm.getToken();
        if (kDebugMode) {
          dev.log("FCM Token obtained");
        }
        if (token != null) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({'pushToken': token});
          }
        }
      } catch (e) {
        if (kDebugMode) {
          dev.log("Failed to save FCM token: $e");
        }
      }

      _fcm.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          dev.log("FCM Token refreshed");
        }
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({'pushToken': newToken});
            if (kDebugMode) {
              dev.log("Updated pushToken in Firestore after refresh");
            }
          }
        } catch (e) {
          if (kDebugMode) {
            dev.log("Failed to update refreshed FCM token: $e");
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        dev.log("Error initializing NotificationService: $e");
      }
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      dev.log("Notification clicked: ${response.payload}");
    }
    if (response.payload != null && _onNotificationTap != null) {
      _onNotificationTap!(response.payload);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      if (kDebugMode) {
        dev.log("Error getting FCM Token: $e");
      }
      return null;
    }
  }

  /// Show a message notification with proper sender name and content
  Future<void> showMessageNotification({
    required int id,
    required String senderName,
    required String messageBody,
    required String chatRoute,
    bool hideSender = false,
    bool hideMessage = false,
  }) async {
    String title;
    String body;

    if (hideSender) {
      title = 'MeChat';
      body = hideMessage ? 'New message' : messageBody;
    } else {
      title = senderName;
      body = hideMessage ? 'Sent a message' : messageBody;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'mechat_channel',
          'MeChat Messages',
          channelDescription: 'Notifications for new messages',
          importance: Importance.max,
          priority: Priority.high,
          autoCancel: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: chatRoute,
    );
  }

  Future<void> showCustomNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'mechat_custom',
          'MeChat Alert',
          channelDescription: 'Alerts and system messages',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> showOngoingCallNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'mechat_ongoing_call',
          'Ongoing Call',
          channelDescription: 'Ongoing call status',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showWhen: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.startForegroundService(
          id: id,
          title: title,
          body: body,
          notificationDetails: androidDetails,
        );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> cancelOngoingCallNotification(int id) async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.stopForegroundService();
    await _localNotifications.cancel(id: id);
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id: id);
  }

  /// Show a full-screen incoming call notification that displays over
  /// the lock screen and other apps
  Future<void> showIncomingCallNotification({
    required int id,
    required String callerName,
    required bool isVideo,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'mechat_incoming_call',
          'Incoming Calls',
          channelDescription: 'Full-screen notifications for incoming calls',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: false,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          timeoutAfter: 60000,
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: id,
      title: isVideo ? '📹 Incoming Video Call' : '📞 Incoming Voice Call',
      body: '$callerName is calling...',
      notificationDetails: details,
      payload: '/incoming-call',
    );
  }

  /// Cancel incoming call notification
  Future<void> cancelIncomingCallNotification(int id) async {
    await _localNotifications.cancel(id: id);
  }
}
