import 'package:flutter/foundation.dart';

import '../models/property.dart';
import 'cloud_backup_service.dart';
import 'property_service.dart';

/// Provider for Property backup data (shared across all apps).
class PropertyBackupProvider implements BackupProvider {
  @override
  String get key => 'agro_properties';

  @override
  Future<Map<String, dynamic>> getData() async {
    final service = PropertyService();
    final properties = service.getAllProperties();

    return {
      'version': '1.0.0',
      'properties': properties
          .map((p) => {
                'id': p.id,
                'userId': p.userId,
                'name': p.name,
                'latitude': p.latitude,
                'longitude': p.longitude,
                'isDefault': p.isDefault,
                'createdAt': p.createdAt.toIso8601String(),
                'updatedAt': p.updatedAt.toIso8601String(),
              })
          .toList(),
    };
  }

  @override
  Future<void> restoreData(Map<String, dynamic> data) async {
    if (data['properties'] == null) return;

    final propertiesList = data['properties'] as List;
    final service = PropertyService();

    // CLEAR existing properties first (restore = replace, not merge)
    await service.clearAllForUser();

    int imported = 0;

    for (final p in propertiesList) {
      final property = Property(
        id: p['id'] as String,
        userId: p['userId'] as String,
        name: p['name'] as String,
        latitude: (p['latitude'] as num?)?.toDouble(),
        longitude: (p['longitude'] as num?)?.toDouble(),
        isDefault: p['isDefault'] as bool? ?? false,
        createdAt: DateTime.parse(p['createdAt'] as String),
        updatedAt: DateTime.parse(p['updatedAt'] as String),
      );

      await service.importProperty(property);
      imported++;
    }

    debugPrint(
        '[PropertyBackup] Restored $imported properties (cleared existing first).');
  }
}
