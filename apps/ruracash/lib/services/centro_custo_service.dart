import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/centro_custo.dart';

/// Service for managing cost centers.
/// Migrated to GenericSyncService (CORE-83).
class CentroCustoService extends GenericSyncService<CentroCusto> {
  static final CentroCustoService _instance = CentroCustoService._internal();
  static CentroCustoService get instance => _instance;
  CentroCustoService._internal();
  factory CentroCustoService() => _instance;

  @override
  String get boxName => 'centros_custo';

  @override
  String get sourceApp => 'ruracash';

  @override
  bool get syncEnabled => false; // CASH-08: disabled until real Firebase config

  @override
  CentroCusto fromMap(Map<String, dynamic> map) => CentroCusto.fromJson(map);

  @override
  Map<String, dynamic> toMap(CentroCusto item) => item.toJson();

  @override
  String getId(CentroCusto item) => item.id;

  @override
  Future<void> init() async {
    await super.init();
    await _migrateDataIfNeeded();
    await ensureDefaultCentroCusto();
  }

  /// Migra dados antigos (Objetos) para nova estrutura
  Future<void> _migrateDataIfNeeded() async {
    final box = Hive.box(boxName);
    if (box.isEmpty) return;

    final firstKey = box.keys.first;
    final firstValue = box.get(firstKey);

    if (firstValue is CentroCusto) {
      debugPrint('[CentroCustoService] Migrating data from Adapter to Map...');
      final Map<dynamic, dynamic> rawMap = box.toMap();

      for (final entry in rawMap.entries) {
        if (entry.value is CentroCusto) {
          final item = entry.value as CentroCusto;
          await super.update(item.id, item);
        }
      }
      debugPrint('[CentroCustoService] Migration completed.');
    }
  }

  /// Helper to get active farm ID.
  String get activeFarmId => FarmService.instance.defaultFarmId ?? '';

  /// All cost centers sorted by name, filtered by active farm.
  List<CentroCusto> get centros {
    final list = getAll().where((c) => c.farmId == activeFarmId).toList();
    list.sort((a, b) => a.nome.compareTo(b.nome));
    return list;
  }

  /// Get a center by ID.
  CentroCusto? getCentroCusto(String id) {
    return getById(id);
  }

  /// Get the default center ("Geral" if exists, otherwise first available).
  CentroCusto? get defaultCentroCusto {
    final list = centros;
    if (list.isEmpty) return null;
    return list.firstWhere((c) => c.nome == 'Geral', orElse: () => list.first);
  }

  /// Add a new cost center.
  Future<CentroCusto> addCentroCusto(CentroCusto centro) async {
    await super.add(centro);
    return centro;
  }

  /// Create and add a new center.
  Future<CentroCusto> createCentroCusto({
    required String nome,
    int corValue = 0xFF607D8B,
    String? appVinculado,
  }) async {
    final centro = CentroCusto.create(
      nome: nome,
      corValue: corValue,
      appVinculado: appVinculado,
    );
    return addCentroCusto(centro);
  }

  /// Update an existing center.
  Future<void> updateCentroCusto(CentroCusto centro) async {
    await super.update(centro.id, centro);
  }

  /// Delete a center.
  Future<void> deleteCentroCusto(String id) async {
    await super.delete(id);
  }

  /// Ensure at least one default center exists for the ACTIVE farm.
  Future<void> ensureDefaultCentroCusto() async {
    if (centros.isEmpty) {
      await createCentroCusto(
        nome: 'Geral',
        corValue: 0xFF607D8B,
      );
      debugPrint(
          '[CentroCustoService] Created default center for farm: $activeFarmId');
    }
  }

  /// Clear all centers.
  @override
  Future<void> clearAll() async {
    await super.clearAll();
  }

  /// Backup helpers.
  List<Map<String, dynamic>> toJsonList() {
    return centros.map((c) => c.toJson()).toList();
  }

  Future<void> importFromJson(List<dynamic> jsonList) async {
    for (final json in jsonList) {
      final centro = CentroCusto.fromJson(json as Map<String, dynamic>);
      if (getById(centro.id) == null) {
        await super.add(centro);
      }
    }
  }
}
