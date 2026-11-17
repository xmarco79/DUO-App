import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'ours_messages',
  'OURS notifications',
  description: 'Messages and activity from your OURS private universe',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> oursFirebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class OursPushService {
  OursPushService._();

  static StreamSubscription<AuthState>? _authSubscription;
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _messageSubscription;
  static StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  static bool _initialized = false;
  static bool _initializing = false;

  static Future<void> initialize() async {
    if (_initialized || _initializing) return;
    _initializing = true;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(oursFirebaseBackgroundHandler);

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings),
        onDidReceiveNotificationResponse: (_) {},
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      _messageSubscription =
          FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      _openedMessageSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) _handleOpenedMessage(initialMessage);

      _authSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        if (event.session != null) {
          _registerCurrentToken();
        }
      });

      _tokenSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

      if (Supabase.instance.client.auth.currentSession != null) {
        await _registerCurrentToken();
      }
      _initialized = true;
    } catch (_) {
      await _cancelSubscriptions();
      rethrow;
    } finally {
      _initializing = false;
    }
  }

  static Future<void> _cancelSubscriptions() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedMessageSubscription?.cancel();
    _authSubscription = null;
    _tokenSubscription = null;
    _messageSubscription = null;
    _openedMessageSubscription = null;
  }

  static Future<void> _registerCurrentToken() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) await _saveToken(token);
  }

  static Future<void> _saveToken(String token) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      await client.from('duo_push_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': 'android',
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
    } catch (_) {
      // Push registration is best-effort; it must not block app startup.
    }
  }

  static Future<void> _showForegroundNotification(
      RemoteMessage message) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool('ours_quiet_mode') ?? false) return;

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'OURS',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static void _handleOpenedMessage(RemoteMessage message) {
    // The app currently opens to the shared home/chat experience.
    // Deep-link routing can be added when notification destinations are defined.
  }

  static Future<void> unregisterCurrentToken() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await client
            .from('duo_push_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('token', token);
      }
    } catch (_) {}
  }

  static Future<void> dispose() async {
    await _cancelSubscriptions();
    _initialized = false;
  }
}
