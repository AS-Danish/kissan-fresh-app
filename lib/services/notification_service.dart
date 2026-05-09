import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Request permission (Required for iOS/Web, recommended for Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
      await saveTokenToFirestore();
    } else {
      debugPrint('User declined or has not accepted notification permission');
    }

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Create Notification Channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Handle token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      saveTokenToFirestore();
    });

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message while in the foreground!');
      debugPrint('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // Handle app opening from a notification when in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
    });
  }

  Future<void> saveTokenToFirestore() async {
    try {
      final box = Hive.box('user_settings');
      bool isEnabled = box.get('isNotificationsEnabled', defaultValue: true);
      
      if (!isEnabled) {
        debugPrint('Notifications are disabled, skipping token save.');
        return;
      }

      String? token = await _fcm.getToken();
      String? uid = _auth.currentUser?.uid;

      if (token != null && uid != null) {
        final savedToken = box.get('fcm_token_$uid');
        if (savedToken == token) {
           debugPrint('FCM Token unchanged, skipping Firestore write.');
           return;
        }

        await _firestore.collection('users').doc(uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
        await box.put('fcm_token_$uid', token);
        debugPrint('FCM Token saved to Firestore: $token');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> deleteTokenFromFirestore() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set(
          {'fcmToken': FieldValue.delete()},
          SetOptions(merge: true),
        );
        final box = Hive.box('user_settings');
        await box.delete('fcm_token_$uid');
        debugPrint('FCM Token deleted from Firestore');
      }
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}
