import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  static const String _deviceIdKey = 'device_id';
  String? _deviceId;

  DeviceInfoService._internal();

  factory DeviceInfoService() {
    return _instance;
  }

  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString(_deviceIdKey);

      if (_deviceId == null) {
        // Gera um UUID único para o dispositivo
        _deviceId = const Uuid().v4();
        await prefs.setString(_deviceIdKey, _deviceId!);
      }

      return _deviceId!;
    } catch (e) {
      print('Erro ao obter deviceId: $e');
      // Em caso de erro, gera um ID temporário baseado no timestamp
      return 'temp_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
