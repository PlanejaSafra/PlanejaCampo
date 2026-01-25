import 'dart:convert';
import 'dart:io';

import 'package:agro_core/agro_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/registro_chuva.dart';
import 'chuva_service.dart';

/// Result of an import operation.
class ImportResult {
  final int imported;
  final int duplicates;

  ImportResult({required this.imported, required this.duplicates});
}

/// Service for backup and restore operations.
class BackupService {
  static const String _appVersion = '1.0.0';

  /// Exports all records to a JSON file and shares it.
  static Future<void> exportar() async {
    final service = ChuvaService();
    final registros = service.listarTodos();

    if (registros.isEmpty) {
      throw Exception('Nenhum registro para exportar');
    }

    final backup = {
      'app': 'planeja_chuva',
      'version': _appVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'totalRecords': registros.length,
      'records': registros
          .map((r) => {
                'id': r.id,
                'data': r.data.toIso8601String(),
                'milimetros': r.milimetros,
                'observacao': r.observacao,
                'criadoEm': r.criadoEm.toIso8601String(),
                'propertyId': r.propertyId,
              })
          .toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

    // Write to temp file
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/planeja_chuva_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Backup RuraRain',
      text: 'Backup de ${registros.length} registros de chuva',
    );
  }

  /// Parses a JSON backup string and returns the records.
  static List<RegistroChuva> parseBackup(String jsonString) {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup structure
      if (data['app'] != 'planeja_chuva' || data['records'] == null) {
        throw Exception('Arquivo de backup inválido');
      }

      final records = data['records'] as List;

      // Get default property for old backups without propertyId
      final propertyService = PropertyService();
      final defaultProperty = propertyService.getDefaultProperty();
      final defaultPropertyId = defaultProperty?.id ?? '';

      return records.map((r) {
        // Use propertyId from backup if available, otherwise use default
        final propertyId = r['propertyId'] as String? ?? defaultPropertyId;

        return RegistroChuva(
          id: r['id'] as int,
          data: DateTime.parse(r['data'] as String),
          milimetros: (r['milimetros'] as num).toDouble(),
          observacao: r['observacao'] as String?,
          criadoEm: DateTime.parse(r['criadoEm'] as String),
          propertyId: propertyId,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erro ao processar backup: $e');
    }
  }

  /// Imports records from a parsed list, avoiding duplicates.
  static Future<ImportResult> importar(List<RegistroChuva> registros) async {
    final service = ChuvaService();
    final existentes = service.listarTodos();
    final idsExistentes = existentes.map((r) => r.id).toSet();

    int imported = 0;
    int duplicates = 0;

    for (final registro in registros) {
      if (idsExistentes.contains(registro.id)) {
        duplicates++;
      } else {
        await service.adicionar(registro);
        imported++;
      }
    }

    return ImportResult(imported: imported, duplicates: duplicates);
  }

  /// Generates a summary text for sharing via WhatsApp or other apps.
  static String gerarResumoTexto() {
    final service = ChuvaService();
    final registros = service.listarTodos();

    if (registros.isEmpty) {
      return 'RuraRain - Nenhum registro';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== RURARAIN ===');
    buffer.writeln('Backup: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('Total: ${registros.length} registros');
    buffer.writeln('');

    // Group by month
    final byMonth = <String, List<RegistroChuva>>{};
    for (final r in registros) {
      final key = '${r.data.year}-${r.data.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(r);
    }

    for (final month in byMonth.keys.toList()..sort((a, b) => b.compareTo(a))) {
      final regs = byMonth[month]!;
      final total = regs.fold(0.0, (sum, r) => sum + r.milimetros);
      buffer.writeln(
          '$month: ${total.toStringAsFixed(1)}mm (${regs.length} chuvas)');
    }

    return buffer.toString();
  }
}
