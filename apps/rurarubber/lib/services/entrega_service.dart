import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/entrega.dart';
import '../models/item_entrega.dart';

/// Service for managing deliveries (Entregas) in RuraRubber.
/// Migrated to GenericSyncService (CORE-83).
class EntregaService extends GenericSyncService<Entrega> {
  static final EntregaService _instance = EntregaService._internal();
  static EntregaService get instance => _instance;
  EntregaService._internal();
  factory EntregaService() => _instance;

  @override
  String get boxName => 'entregas';

  @override
  String get sourceApp => 'rurarubber';

  @override
  bool get syncEnabled => true;

  @override
  Entrega fromMap(Map<String, dynamic> map) => Entrega.fromJson(map);

  @override
  Map<String, dynamic> toMap(Entrega item) => item.toJson();

  @override
  String getId(Entrega item) => item.id;

  // Active session data
  Entrega? _currentEntrega;

  /// All deliveries sorted by date (newest first).
  List<Entrega> get entregas {
    final list = getAll();
    list.sort((a, b) => b.data.compareTo(a.data));
    return list;
  }

  Entrega? get currentEntrega => _currentEntrega;

  @override
  Future<void> init() async {
    await super.init();
    await _migrateDataIfNeeded();
    _checkForOpenEntrega();
  }

  /// Migra dados antigos (Objetos) para nova estrutura
  Future<void> _migrateDataIfNeeded() async {
    final box = Hive.box(boxName);
    if (box.isEmpty) return;

    final firstKey = box.keys.first;
    final firstValue = box.get(firstKey);

    if (firstValue is Entrega) {
      debugPrint('[EntregaService] Migrating data from Adapter to Map...');
      final Map<dynamic, dynamic> rawMap = box.toMap();

      for (final entry in rawMap.entries) {
        if (entry.value is Entrega) {
          final item = entry.value as Entrega;
          await super.update(item.id, item);
        }
      }
      debugPrint('[EntregaService] Migration completed.');
    }
  }

  void _checkForOpenEntrega() {
    // Find the most recent 'Aberto' entrega
    try {
      final openEntregas = getAll().where((e) => e.status == 'Aberto').toList();
      if (openEntregas.isNotEmpty) {
        // Sort by date descending
        openEntregas.sort((a, b) => b.data.compareTo(a.data));
        _currentEntrega = openEntregas.first;
      }
    } catch (_) {
      // ignore
    }
  }

  void resumeEntrega(Entrega entrega) {
    _currentEntrega = entrega;
    notifyListeners();
  }

  void startNewEntrega() {
    _currentEntrega = Entrega.create(
      id: const Uuid().v4(),
      data: DateTime.now(),
      status: 'Aberto',
      itens: [],
    );
    notifyListeners();
  }

  /// Delete a specific entrega by ID.
  Future<void> deleteEntrega(String id) async {
    await super.delete(id);
    if (_currentEntrega?.id == id) {
      _currentEntrega = null;
    }
  }

  /// Get entrega by ID.
  Entrega? getEntregaById(String id) {
    return getById(id);
  }

  Future<void> addPesagem(String parceiroId, double peso) async {
    if (_currentEntrega == null) {
      startNewEntrega();
    }

    // Find if we already have an item for this partner
    ItemEntrega? item;
    try {
      item =
          _currentEntrega!.itens.firstWhere((i) => i.parceiroId == parceiroId);
    } catch (e) {
      item = null;
    }

    if (item != null) {
      item.adicionarPesagem(peso);
    } else {
      item = ItemEntrega(
        parceiroId: parceiroId,
        pesagens: [peso],
        pesoTotal: peso,
      );
      _currentEntrega!.itens.add(item);
    }

    // Save/Update current entrega via GenericSyncService (triggers sync)
    await super.update(_currentEntrega!.id, _currentEntrega!);
  }

  Future<void> undoLastPesagem(String parceiroId) async {
    if (_currentEntrega == null) return;

    try {
      final item =
          _currentEntrega!.itens.firstWhere((i) => i.parceiroId == parceiroId);
      if (item.pesagens.isNotEmpty) {
        item.pesagens.removeLast();
        item.calcularPesoTotal();
        if (item.pesagens.isEmpty) {
          _currentEntrega!.itens.remove(item);
        }
        await super.update(_currentEntrega!.id, _currentEntrega!);
      }
    } catch (e) {
      // Item not found
    }
  }

  List<double> getPesagensForParceiro(String parceiroId) {
    if (_currentEntrega == null) return [];
    try {
      final item =
          _currentEntrega!.itens.firstWhere((i) => i.parceiroId == parceiroId);
      return item.pesagens;
    } catch (e) {
      return [];
    }
  }

  double getTotalForParceiro(String parceiroId) {
    if (_currentEntrega == null) return 0.0;
    try {
      final item =
          _currentEntrega!.itens.firstWhere((i) => i.parceiroId == parceiroId);
      return item.pesoTotal;
    } catch (e) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Safra-filtered queries (RUBBER-17)
  // ─────────────────────────────────────────────────────────────────────

  /// Get entregas filtered by a safra's time period.
  List<Entrega> entregasPorSafra(Safra safra) {
    return SafraService.instance.filterBySafra(
      records: entregas,
      safra: safra,
      getDate: (e) => e.data,
    );
  }

  /// Total weight (kg) within a safra period.
  double totalPesoSafra(Safra safra) {
    return SafraService.instance.sumBySafra(
      records: entregas,
      safra: safra,
      getDate: (e) => e.data,
      getValue: (e) => e.pesoTotalGeral,
    );
  }

  /// Total value (R$) within a safra period.
  double totalValorSafra(Safra safra) {
    return SafraService.instance.sumBySafra(
      records: entregas,
      safra: safra,
      getDate: (e) => e.data,
      getValue: (e) => e.itens.fold<double>(0, (sum, i) => sum + i.valorTotal),
    );
  }

  /// Count entregas within a safra period.
  int countEntregasSafra(Safra safra) {
    return SafraService.instance.countBySafra(
      records: entregas,
      safra: safra,
      getDate: (e) => e.data,
    );
  }

  /// Total weight per parceiro within a safra period.
  /// Returns a map of parceiroId → totalKg.
  Map<String, double> pesoPorParceiroSafra(Safra safra) {
    final filtered = entregasPorSafra(safra);
    final result = <String, double>{};
    for (final entrega in filtered) {
      for (final item in entrega.itens) {
        result[item.parceiroId] =
            (result[item.parceiroId] ?? 0) + item.pesoTotal;
      }
    }
    return result;
  }

  /// Monthly totals within a safra period (for charts).
  List<MapEntry<DateTime, double>> totalMensalSafra(Safra safra) {
    final filtered = entregasPorSafra(safra);
    final monthly = <String, double>{};

    for (final entrega in filtered) {
      final key =
          '${entrega.data.year}-${entrega.data.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + entrega.pesoTotalGeral;
    }

    final entries = monthly.entries.map((e) {
      final parts = e.key.split('-');
      return MapEntry(
        DateTime(int.parse(parts[0]), int.parse(parts[1])),
        e.value,
      );
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries;
  }

  /// Biweekly (quinzenal) totals within a safra period.
  List<MapEntry<DateTime, double>> totalQuinzenalSafra(Safra safra) {
    final filtered = entregasPorSafra(safra);
    final biweekly = <String, double>{};

    for (final entrega in filtered) {
      final half = entrega.data.day <= 15 ? 1 : 16;
      final key =
          '${entrega.data.year}-${entrega.data.month.toString().padLeft(2, '0')}-${half.toString().padLeft(2, '0')}';
      biweekly[key] = (biweekly[key] ?? 0) + entrega.pesoTotalGeral;
    }

    final entries = biweekly.entries.map((e) {
      final parts = e.key.split('-');
      return MapEntry(
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
        e.value,
      );
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries;
  }

  /// Biweekly totals for a specific parceiro within a safra.
  List<MapEntry<DateTime, double>> totalQuinzenalPorParceiro(
      Safra safra, String parceiroId) {
    final filtered = entregasPorSafra(safra);
    final biweekly = <String, double>{};

    for (final entrega in filtered) {
      for (final item in entrega.itens) {
        if (item.parceiroId != parceiroId) continue;
        final half = entrega.data.day <= 15 ? 1 : 16;
        final key =
            '${entrega.data.year}-${entrega.data.month.toString().padLeft(2, '0')}-${half.toString().padLeft(2, '0')}';
        biweekly[key] = (biweekly[key] ?? 0) + item.pesoTotal;
      }
    }

    final entries = biweekly.entries.map((e) {
      final parts = e.key.split('-');
      return MapEntry(
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
        e.value,
      );
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries;
  }

  /// Monthly totals for a specific parceiro within a safra.
  List<MapEntry<DateTime, double>> totalMensalPorParceiro(
      Safra safra, String parceiroId) {
    final filtered = entregasPorSafra(safra);
    final monthly = <String, double>{};

    for (final entrega in filtered) {
      for (final item in entrega.itens) {
        if (item.parceiroId != parceiroId) continue;
        final key =
            '${entrega.data.year}-${entrega.data.month.toString().padLeft(2, '0')}';
        monthly[key] = (monthly[key] ?? 0) + item.pesoTotal;
      }
    }

    final entries = monthly.entries.map((e) {
      final parts = e.key.split('-');
      return MapEntry(
        DateTime(int.parse(parts[0]), int.parse(parts[1])),
        e.value,
      );
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries;
  }

  /// Clear all entregas (used for restore).
  @override
  Future<void> clearAll() async {
    await super.clearAll();
    _currentEntrega = null;
  }
}
