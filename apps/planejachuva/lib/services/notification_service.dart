import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../models/user_preferences.dart';
import 'chuva_service.dart';

/// Service for local reminder notifications (offline-first).
/// Reminds user to log rainfall at a scheduled time.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int dailyReminderNotificationId = 0;

  /// Initialize the notification service.
  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  /// Request notification permissions (required for iOS/Android 13+).
  static Future<bool> requestPermissions() async {
    final android = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final ios = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return (android ?? true) && (ios ?? true);
  }

  /// Schedule daily reminder notification.
  static Future<void> scheduleDailyReminder({
    required String time, // Format: "HH:mm" (e.g., "18:00")
    required String locale,
  }) async {
    // Cancel existing reminder first
    await cancelDailyReminder();

    // Parse time
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Create scheduled time
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final scheduledTz = tz.TZDateTime.from(scheduledDate, tz.local);

    // Notification text
    final title = locale.startsWith('pt')
        ? '🌧️ Planeja Chuva'
        : '🌧️ Planeja Chuva';
    final body = locale.startsWith('pt')
        ? 'Já registrou a chuva de hoje?'
        : 'Did you log today\'s rainfall?';

    // Schedule the notification
    await _notifications.zonedSchedule(
      dailyReminderNotificationId,
      title,
      body,
      scheduledTz,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_rainfall_reminder',
          locale.startsWith('pt') ? 'Lembretes Diários' : 'Daily Reminders',
          channelDescription: locale.startsWith('pt')
              ? 'Lembrete para registrar chuva'
              : 'Reminder to log rainfall',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Cancel daily reminder.
  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(dailyReminderNotificationId);
  }

  /// Check if user has already logged rainfall today.
  /// If yes, skip sending notification.
  static bool shouldSkipNotification() {
    final service = ChuvaService();
    final registros = service.listarTodos();

    if (registros.isEmpty) return false;

    final today = DateTime.now();
    final hasToday = registros.any((r) =>
        r.data.year == today.year &&
        r.data.month == today.month &&
        r.data.day == today.day);

    return hasToday; // Skip if already logged today
  }

  /// Update reminder based on user preferences.
  static Future<void> updateFromPreferences(UserPreferences prefs) async {
    if (prefs.reminderEnabled && prefs.reminderTime != null) {
      final locale = prefs.locale ?? 'pt_BR';
      await scheduleDailyReminder(
        time: prefs.reminderTime!,
        locale: locale,
      );
    } else {
      await cancelDailyReminder();
    }
  }
}
