import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../privacy/agro_privacy_store.dart';
import 'dependency_service.dart';
import 'farm_service.dart';
import 'property_service.dart';
import 'talhao_service.dart';

/// Callback type for app-specific data export.
/// Apps should provide their data as a Map that can be JSON-encoded.
typedef DataExportCallback = Future<Map<String, dynamic>> Function();

/// Service for LGPD-compliant data portability (Art. 18, V - Right to Data Portability).
///
/// Exports user data in JSON or CSV format for use in other services.
/// Includes cross-app references and dependency information
/// so the user knows exactly how their data is connected.
///
/// See CORE-77 Section 10 for multi-app export architecture.
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

  /// Check if current user is the farm owner.
  ///
  /// Only the farm owner can export farm data (LGPD ownership rule).
  /// Non-owners can only export their personal data via [exportPersonalDataOnly].
  ///
  /// See CORE-77 Section 16 for ownership rules.
  bool get _isCurrentUserFarmOwner {
    if (!FarmService.instance.isInitialized) return false;
    final defaultFarm = FarmService.instance.getDefaultFarm();
    if (defaultFarm == null) return false;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return userId != null && defaultFarm.isOwner(userId);
  }

  /// Export all user data as JSON (human-readable format).
  ///
  /// **Ownership rule**: Only the farm owner can export farm data.
  /// Non-owners get only their personal data (consents, profile).
  /// This applies to all export/backup/import operations.
  ///
  /// Returns the JSON string containing:
  /// - User info (id, email)
  /// - Farms (from FarmService) — owner only
  /// - Properties — owner only
  /// - Field plots (talhões) — owner only
  /// - App-specific data — owner only
  /// - Cross-app references (from DependencyService) — owner only
  /// - Consents
  ///
  /// See CORE-77 Section 10 and Section 16 for architecture.
  Future<String> exportToJson() async {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = _isCurrentUserFarmOwner;

    final export = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'format': 'json',
      'isOwnerExport': isOwner,
      'user': {
        'id': user?.uid,
        'email': user?.email,
        'isAnonymous': user?.isAnonymous ?? true,
      },
      'consents': _exportConsents(),
    };

    // Farm data is only included for owners
    if (isOwner) {
      export['data'] = {
        'farms': _exportFarms(),
        'properties': await _exportProperties(),
        'field_plots': await _exportTalhoes(),
      };
      export['crossAppReferences'] = _exportCrossAppReferences();

      // Add app-specific data
      for (final entry in _appExporters.entries) {
        try {
          final appData = await entry.value();
          (export['data'] as Map<String, dynamic>)[entry.key] = appData;
        } catch (e) {
          debugPrint('DataExportService: Error exporting ${entry.key}: $e');
        }
      }
    } else {
      export['data'] = <String, dynamic>{};
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

  /// Export farms from FarmService.
  List<Map<String, dynamic>> _exportFarms() {
    if (!FarmService.instance.isInitialized) return [];

    return FarmService.instance.getAllFarms().map((farm) => {
      'id': farm.id,
      'name': farm.name,
      'ownerId': farm.ownerId,
      'isDefault': farm.isDefault,
      'createdAt': farm.createdAt.toIso8601String(),
      'updatedAt': farm.updatedAt.toIso8601String(),
      'description': farm.description,
    }).toList();
  }

  /// Export cross-app dependency references.
  ///
  /// Shows which apps reference which shared entities, so the user
  /// knows exactly how their data is connected across the ecosystem.
  Map<String, dynamic> _exportCrossAppReferences() {
    if (!DependencyService.instance.isInitialized) {
      return {'available': false};
    }

    final references = <String, dynamic>{};

    // Export all registered manifests
    for (final appId in DependencyService.instance.registeredApps) {
      final manifest = DependencyService.instance.getManifest(appId);
      if (manifest == null) continue;

      references[appId] = {
        'updatedAt': manifest.updatedAt.toIso8601String(),
        'references': manifest.references,
        'totalReferences': manifest.totalReferenceCount,
      };
    }

    return {
      'available': true,
      'apps': references,
    };
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
