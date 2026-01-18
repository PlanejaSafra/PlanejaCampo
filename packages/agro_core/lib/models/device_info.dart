import 'package:hive/hive.dart';

part 'device_info.g.dart';

/// Device metadata for GDPR-safe identification.
/// Does not include MAC address, IMEI, or other unique identifiers.
@HiveType(typeId: 10)
class DeviceInfo extends HiveObject {
  /// Platform: 'android' or 'ios'
  @HiveField(0)
  String platform;

  /// App version (e.g., '1.0.0')
  @HiveField(1)
  String appVersion;

  /// Device model (e.g., 'SM-G973F', 'iPhone 12')
  @HiveField(2)
  String? deviceModel;

  /// OS version (e.g., '13', '15.2')
  @HiveField(3)
  String? osVersion;

  DeviceInfo({
    required this.platform,
    required this.appVersion,
    this.deviceModel,
    this.osVersion,
  });

  /// Convert to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'app_version': appVersion,
      'device_model': deviceModel,
      'os_version': osVersion,
    };
  }

  /// Create from Firestore Map
  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      platform: map['platform'] as String,
      appVersion: map['app_version'] as String,
      deviceModel: map['device_model'] as String?,
      osVersion: map['os_version'] as String?,
    );
  }
}
