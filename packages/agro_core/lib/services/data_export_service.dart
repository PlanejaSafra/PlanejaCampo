import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../privacy/agro_privacy_store.dart';
import 'property_service.dart';
import 'talhao_service.dart';

/// Callback type for app-specific data export.
/// Apps should provide their data as a Map that can be JSON-encoded.
typedef DataExportCallback = Future<Map<String, dynamic>> Function();

/// Service for LGPD-compliant data portability (Art. 18, V - Right to Data Portability).
/// Exports user data in JSON or CSV format for use in other services.
class DataExportService {
  DataExportService._();
  static final DataExportService instance = DataExportService._();

  /// Registered exporters from apps (e.g., planeja_chuva exports rainfall records).
  final Map<String, DataExportCallback> _appExporters = {};

  /// Register an app-specific data exporter.
  ///
  /// Example:
  /// ```dart
  /// DataExportService.instance.registerExporter(
  ///   'rainfall_records',
  ///   () async => {'records': await chuvaService.getAllRecords()},
  /// );
  /// ```
  void registerExporter(String key, DataExportCallback callback) {
    _appExporters[key] = callback;
  }

  /// Export all user data as JSON (human-readable format).
  ///
  /// Returns the JSON string containing:
  /// - User info (id, email)
  /// - Properties
  /// - Field plots (talhões)
  /// - App-specific data (registered via registerExporter)
  /// - Consents
  Future<String> exportToJson() async {
    final user = FirebaseAuth.instance.currentUser;

    final export = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'format': 'json',
      'user': {
        'id': user?.uid,
        'email': user?.email,
        'isAnonymous': user?.isAnonymous ?? true,
      },
      'data': {
        'properties': await _exportProperties(),
        'field_plots': await _exportTalhoes(),
      },
      'consents': _exportConsents(),
    };

    // Add app-specific data
    for (final entry in _appExporters.entries) {
      try {
        final appData = await entry.value();
        export['data'][entry.key] = appData;
      } catch (e) {
        debugPrint('DataExportService: Error exporting ${entry.key}: $e');
      }
    }

    return const JsonEncoder.withIndent('  ').convert(export);
  }

  /// Export rainfall records as CSV (spreadsheet-compatible).
  ///
  /// Note: This is a generic exporter. Apps should register their CSV format.
  Future<String> exportToCsv() async {
    final properties = PropertyService().getAllProperties();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final talhoes = TalhaoService().listByUser(userId);

    final csv = StringBuffer();

    // Properties sheet
    csv.writeln('=== PROPERTIES ===');
    csv.writeln('Name,Area (ha),Latitude,Longitude,Is Default');
    for (final p in properties) {
      csv.writeln(
          '"${p.name}",${p.totalArea ?? ""},${p.latitude ?? ""},${p.longitude ?? ""},${p.isDefault}');
    }
    csv.writeln();

    // Field plots sheet
    csv.writeln('=== FIELD PLOTS ===');
    csv.writeln('Name,Area (ha),Crop,Property');
    for (final t in talhoes) {
      String propName = 'Unknown';
      try {
        propName = properties.firstWhere((p) => p.id == t.propertyId).name;
      } catch (_) {
        // Property not found, use default
      }
      csv.writeln('"${t.nome}",${t.area},"${t.cultura ?? ""}","$propName"');
    }

    return csv.toString();
  }

  /// Export data and share via native Share Sheet.
  ///
  /// [asCsv] - If true, exports as CSV. Otherwise exports as JSON.
  Future<void> shareExport({bool asCsv = false}) async {
    final content = asCsv ? await exportToCsv() : await exportToJson();
    final filename = asCsv ? 'meus_dados.csv' : 'meus_dados.json';

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(content);

    // Share via native sheet
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Meus dados - PlanejaCampo',
    );
  }

  /// Export properties as list of maps.
  Future<List<Map<String, dynamic>>> _exportProperties() async {
    final properties = PropertyService().getAllProperties();
    return properties
        .map((p) => {
              'name': p.name,
              'area_ha': p.totalArea,
              'latitude': p.latitude,
              'longitude': p.longitude,
              'is_default': p.isDefault,
              'created_at': p.createdAt.toIso8601String(),
            })
        .toList();
  }

  /// Export talhões as list of maps.
  Future<List<Map<String, dynamic>>> _exportTalhoes() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final talhoes = TalhaoService().listByUser(userId);
    final properties = PropertyService().getAllProperties();

    return talhoes.map((t) {
      String propName = 'Unknown';
      try {
        propName = properties.firstWhere((p) => p.id == t.propertyId).name;
      } catch (_) {
        // Property not found
      }

      return {
        'name': t.nome,
        'area_ha': t.area,
        'crop': t.cultura,
        'property': propName,
        'created_at': t.createdAt.toIso8601String(),
      };
    }).toList();
  }

  /// Export consents state.
  Map<String, dynamic> _exportConsents() {
    return {
      'data_location': AgroPrivacyStore.consentAggregateMetrics,
      'offers_promotions': AgroPrivacyStore.consentSharePartners,
      'personalized_ads': AgroPrivacyStore.consentAdsPersonalization,
      'last_updated': AgroPrivacyStore.consentTimestamp,
    };
  }
}
