import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AgroNotificationService {
  static final AgroNotificationService _instance =
      AgroNotificationService._internal();
  factory AgroNotificationService() => _instance;
  AgroNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _onNotificationClick =
      StreamController<String?>.broadcast();

  Stream<String?> get onNotificationClick => _onNotificationClick.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization (generic)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
        _onNotificationClick.add(details.payload);
      },
    );

    // Check if app was launched by notification
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload =
          notificationAppLaunchDetails?.notificationResponse?.payload;
      if (payload != null) {
        // Delay slightly to ensure listeners are registered
        Future.delayed(const Duration(milliseconds: 500), () {
          _onNotificationClick.add(payload);
        });
      }
    }

    _initialized = true;
  }

  Future<void> showRainAlert({
    required String title,
    required String body,
    required String channelName,
    required String channelDesc,
    String? payload,
  }) async {
    // Ensure initialized (might be called from background isolate where _instance is fresh)
    if (!_initialized) await init();

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'rain_alerts_channel', // channel Id (stable)
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // ID (can be random or fixed)
      title,
      body,
      notificationDetails,
      payload: payload ?? 'rain_alert',
    );
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}
