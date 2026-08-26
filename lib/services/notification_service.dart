import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/routes/app_routes.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isConfigured = false;

  bool _isAuthorized(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Orders and offers',
    description: 'Order updates, delivery alerts, and Kissan Fresh offers.',
    importance: Importance.high,
  );

  Future<void> initialize({bool requestPermission = true}) async {
    final NotificationSettings settings = requestPermission
        ? await _fcm.requestPermission(alert: true, badge: true, sound: true)
        : await _fcm.getNotificationSettings();

    final notificationsEnabled =
        Hive.box(
              'user_settings',
            ).get('isNotificationsEnabled', defaultValue: true)
            as bool;

    if (_isAuthorized(settings) && notificationsEnabled) {
      debugPrint('User granted notification permission');
      await enableNotifications();
    } else if (requestPermission &&
        settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined or has not accepted notification permission');
    }

    if (_isConfigured) return;
    _isConfigured = true;

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _handleNotificationData(
            Map<String, dynamic>.from(jsonDecode(payload) as Map),
          );
        } catch (error) {
          debugPrint('Unable to open notification payload: $error');
        }
      },
    );

    // Create Notification Channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Handle token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      saveTokenToFirestore();
    });

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final enabled =
          Hive.box(
                'user_settings',
              ).get('isNotificationsEnabled', defaultValue: true)
              as bool;
      if (!enabled) return;
      debugPrint('Got a message while in the foreground!');
      debugPrint('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      final AndroidNotification? android = notification?.android;

      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              styleInformation: BigTextStyleInformation(
                notification.body ?? '',
                contentTitle: notification.title,
              ),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Handle app opening from a notification when in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationData(message.data);
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }
  }

  Future<bool> hasNotificationPermission() async {
    final settings = await _fcm.getNotificationSettings();
    return _isAuthorized(settings);
  }

  Future<bool> requestNotificationPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return _isAuthorized(settings);
  }

  Future<void> enableNotifications() async {
    await saveTokenToFirestore();
    try {
      await _fcm.subscribeToTopic('all_users');
      debugPrint('Subscribed to all_users topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic: $e');
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final type = data['type']?.toString() ?? '';
      if (type.startsWith('ORDER_')) {
        Get.toNamed(
          AppRoutes.myOrdersRoute,
          arguments: {'highlightOrderId': data['orderId']?.toString()},
        );
      } else if (type == 'OFFER_NOTIFICATION') {
        Get.offAllNamed(AppRoutes.mainLayout);
      }
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

        await _firestore.collection('users').doc(uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
        await box.put('fcm_token_$uid', token);
        debugPrint('FCM token saved to Firestore');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> deleteTokenFromFirestore() async {
    try {
      await _fcm.unsubscribeFromTopic('all_users');
      await _fcm.deleteToken();
      String? uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'fcmToken': FieldValue.delete(),
        }, SetOptions(merge: true));
        final box = Hive.box('user_settings');
        await box.delete('fcm_token_$uid');
        debugPrint('FCM Token deleted from Firestore');
      }
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}
