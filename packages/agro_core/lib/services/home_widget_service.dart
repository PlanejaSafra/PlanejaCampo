import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class HomeWidgetService {
  static const String _groupId =
      'group.com.noverde.planejachuva'; // For iOS sharing if needed
  static const String _androidWidgetName = 'RainWidgetProvider';

  static Future<void> updateWidgetData({
    required double? lastRainMm,
    required DateTime? lastRainDate,
    String locale = 'pt_BR',
  }) async {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    final rainValStr =
        lastRainMm != null ? '${lastRainMm.toStringAsFixed(1)} mm' : '--';

    final isEnglish = locale.startsWith('en');

    // Use localized strings based on locale
    String dateStr = isEnglish ? 'No recent data' : 'Sem dados recentes';
    if (lastRainDate != null) {
      final diff = now.difference(lastRainDate).inDays;
      if (diff == 0) {
        dateStr = isEnglish ? 'Today' : 'Hoje';
      } else if (diff == 1) {
        dateStr = isEnglish ? 'Yesterday' : 'Ontem';
      } else {
        dateStr = DateFormat('dd/MM').format(lastRainDate);
      }
    }

    final updateStr =
        isEnglish ? 'Updated at $timeStr' : 'Atualizado às $timeStr';

    await HomeWidget.saveWidgetData<String>('last_rain_val', rainValStr);
    await HomeWidget.saveWidgetData<String>('last_rain_date', dateStr);
    await HomeWidget.saveWidgetData<String>('last_update_ts', updateStr);

    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      iOSName: 'RainWidget',
    );
  }
}
