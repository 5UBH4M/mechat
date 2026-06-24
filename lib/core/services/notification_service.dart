import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  dev.log("Handling background message: ${message.messageId}");
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
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Set this from the app to handle notification taps
  NotificationTapCallback? onNotificationTap;

  Future<void> init() async {
    try {
      // 1. Request permission
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      // 2. Setup background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Initialize Local Notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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

      // Create standard Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'mechat_channel',
        'MeChat Messages',
        description: 'Notifications for new messages',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 4. Listen to foreground messages from FCM
      // We do NOT show local notifications directly here because it doesn't know 
      // which chat screen is active. The listener in main.dart handles foreground 
      // notifications accurately.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        dev.log("Foreground FCM message received: ${message.messageId}");
      });

      // 5. Handle notification tap when app was terminated
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        final senderId = initialMessage.data['senderId'];
        if (senderId != null && senderId.isNotEmpty && onNotificationTap != null) {
          onNotificationTap!('/chat/$senderId');
        }
      }

      // 6. Handle notification tap when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final senderId = message.data['senderId'];
        if (senderId != null && onNotificationTap != null) {
          onNotificationTap!('/chat/$senderId');
        }
      });

      // 7. Force save token to Firestore immediately
      try {
        final token = await _fcm.getToken();
        dev.log("FCM Token: $token");
        if (token != null) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({'pushToken': token});
          }
        }
      } catch (e) {
        dev.log("Failed to save FCM token: $e");
      }
    } catch (e) {
      dev.log("Error initializing NotificationService: $e");
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    dev.log("Notification clicked: ${response.payload}");
    if (response.payload != null && onNotificationTap != null) {
      onNotificationTap!(response.payload);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      dev.log("Error getting FCM Token: $e");
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

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mechat_channel',
      'MeChat Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: chatRoute,
    );
  }

  // Programmatic local notification (e.g. for missed calls, off-line notifications)
  Future<void> showCustomNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mechat_custom',
      'MeChat Alert',
      channelDescription: 'Alerts and system messages',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // Show ongoing call notification (foreground service on Android)
  Future<void> showOngoingCallNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mechat_ongoing_call',
      'Ongoing Call',
      channelDescription: 'Ongoing call status',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    // Start foreground service for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.startForegroundService(
          id: id,
          title: title,
          body: body,
          notificationDetails: androidDetails,
        );
        
    // For iOS, just show a normal notification that doesn't auto cancel
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> cancelOngoingCallNotification(int id) async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.stopForegroundService();
    await _localNotifications.cancel(id: id);
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id: id);
  }
}
