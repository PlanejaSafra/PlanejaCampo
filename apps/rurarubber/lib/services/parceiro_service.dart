import 'package:agro_core/agro_core.dart';
import 'package:agro_core/services/sync/generic_sync_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/parceiro.dart';

/// Service for managing partners (Parceiros) in RuraRubber.
/// Migrated to GenericSyncService (CORE-83).
class ParceiroService extends GenericSyncService<Parceiro> {
  static final ParceiroService _instance = ParceiroService._internal();
  static ParceiroService get instance => _instance;
  ParceiroService._internal();
  factory ParceiroService() => _instance;

  @override
  String get boxName => 'parceiros';

  @override
  String get sourceApp => 'rurarubber';

  @override
  bool get syncEnabled => true;

  @override
  Parceiro fromMap(Map<String, dynamic> map) => Parceiro.fromJson(map);

  @override
  Map<String, dynamic> toMap(Parceiro item) => item.toJson();

  @override
  String getId(Parceiro item) => item.id;

  @override
  Future<void> init() async {
    await super.init();
    await _migrateDataIfNeeded();
  }

  /// Migra dados antigos (Objetos) para nova estrutura
  Future<void> _migrateDataIfNeeded() async {
    final box = Hive.box(boxName);
    if (box.isEmpty) return;

    final firstKey = box.keys.first;
    final firstValue = box.get(firstKey);

    if (firstValue is Parceiro) {
      debugPrint('[ParceiroService] Migrating data from Adapter to Map...');
      final Map<dynamic, dynamic> rawMap = box.toMap();

      for (final entry in rawMap.entries) {
        if (entry.value is Parceiro) {
          final item = entry.value as Parceiro;
          await super.update(item.id, item);
        }
      }
      debugPrint('[ParceiroService] Migration completed.');
    }
  }

  List<Parceiro> get parceiros => getAll();

  Future<void> addParceiro(Parceiro parceiro) async {
    await super.add(parceiro);
  }

  Future<void> updateParceiro(Parceiro parceiro) async {
    await super.update(parceiro.id, parceiro);
  }

  Future<void> deleteParceiro(String id) async {
    await super.delete(id);
  }

  Parceiro? getParceiro(String id) {
    return getById(id);
  }

  Future<void> clearAll() async {
    await super.clearAll();
  }
}
