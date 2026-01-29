import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AgroNotificationService {
  static final AgroNotificationService _instance =
      AgroNotificationService._internal();
  static AgroNotificationService get instance => _instance;
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

  /// Schedule a rain record reminder notification.
  /// Sent 2 hours after predicted rain to remind user to record rainfall.
  Future<void> scheduleRainRecordReminder({
    required String propertyId,
    required String propertyName,
    required DateTime scheduledTime,
    required bool isEnglish,
  }) async {
    // Ensure initialized
    if (!_initialized) await init();

    final title = isEnglish
        ? '🌧️ Did it rain at $propertyName?'
        : '🌧️ Choveu na $propertyName?';
    final body =
        isEnglish ? 'Tap to record rainfall' : 'Toque para registrar a chuva';
    final channelName = isEnglish ? 'Rain Reminders' : 'Lembretes de Chuva';
    final channelDesc = isEnglish
        ? 'Reminds you to record rainfall after predicted rain'
        : 'Lembra de registrar chuva após previsão';

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'rain_reminders_channel',
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    // Generate unique ID based on property
    final notificationId = propertyId.hashCode.abs() % 100000;

    // For simplicity, we'll use a delayed show instead of zonedSchedule
    // (zonedSchedule requires timezone package setup)
    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return; // Already past

    // Schedule using Future.delayed (runs while app/service is alive)
    // For production, consider using flutter_local_notifications zonedSchedule
    Future.delayed(delay, () async {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: 'rain_record:$propertyId',
      );
      debugPrint('[RainReminder] Sent for $propertyName');
    });

    debugPrint(
        '[RainReminder] Scheduled for $propertyName in ${delay.inMinutes}min');
  }

  /// Envia uma notificação genérica.
  /// Usado por todos os apps do ecossistema RuraCamp.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? channelName,
    String? channelDescription,
    String? payload,
  }) async {
    if (!_initialized) await init();

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId ?? 'general_channel',
      channelName ?? 'Notificações',
      channelDescription: channelDescription ?? 'Notificações gerais do app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    debugPrint('[Notification] Sent: $title');
  }

  /// Cancela uma notificação por ID.
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancela todas as notificações.
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
