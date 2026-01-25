import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';

import '../models/registro_chuva.dart';
import '../services/backup_service.dart';
import '../services/chuva_service.dart';

/// Provider for RuraRain backup data.
class ChuvaBackupProvider implements BackupProvider {
  @override
  String get key => 'rura_rain';

  @override
  Future<Map<String, dynamic>> getData() async {
    final service = ChuvaService();
    final registros = service.listarTodos();

    // Use existing backup logic but return Map directly
    return {
      'version': '1.0.0', // Schema version
      'records': registros
          .map((r) => {
                'id': r.id,
                'data': r.data.toIso8601String(),
                'milimetros': r.milimetros,
                'observacao': r.observacao,
                'criadoEm': r.criadoEm.toIso8601String(),
                'propertyId': r.propertyId,
                'talhaoId': r.talhaoId,
              })
          .toList(),
    };
  }

  @override
  Future<void> restoreData(Map<String, dynamic> data) async {
    if (data['records'] == null) return;

    final recordsList = data['records'] as List;
    final registros = recordsList.map((r) {
      return RegistroChuva(
        id: r['id'] as int,
        data: DateTime.parse(r['data'] as String),
        milimetros: (r['milimetros'] as num).toDouble(),
        observacao: r['observacao'] as String?,
        criadoEm: DateTime.parse(r['criadoEm'] as String),
        propertyId: r['propertyId'] as String,
        talhaoId: r['talhaoId'] as String?,
      );
    }).toList();

    // CLEAR existing data first (restore = replace, not merge)
    final service = ChuvaService();
    await service.limparTodos();

    // Import backup records
    final result = await BackupService.importar(registros);
    debugPrint(
        '[ChuvaBackup] Restored ${result.imported} records (cleared existing first).');
  }
}
