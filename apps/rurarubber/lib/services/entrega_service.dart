import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/entrega.dart';
import '../models/item_entrega.dart';

class EntregaService extends ChangeNotifier {
  static const String boxName = 'entregas';
  Box<Entrega>? _box;

  // Active session data
  Entrega? _currentEntrega;

  List<Entrega> get entregas {
    final box = _box;
    if (box == null) return [];
    final list = box.values.toList();
    list.sort((a, b) => b.data.compareTo(a.data));
    return list;
  }

  Entrega? get currentEntrega => _currentEntrega;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<Entrega>(boxName);
    _checkForOpenEntrega();
    notifyListeners();
  }

  void _checkForOpenEntrega() {
    // Find the most recent 'Aberto' entrega
    try {
      if (_box == null) return;
      final openEntregas =
          _box!.values.where((e) => e.status == 'Aberto').toList();
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
    if (_box == null) await init();
    await _box!.delete(id);
    if (_currentEntrega?.id == id) {
      _currentEntrega = null;
    }
    notifyListeners();
  }

  /// Get entrega by ID.
  Entrega? getEntregaById(String id) {
    if (_box == null) return null;
    return _box!.get(id);
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

    // Save/Update current entrega in Hive
    if (_box == null) await init();
    await _box!.put(_currentEntrega!.id, _currentEntrega!);
    notifyListeners();
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
        if (_box == null) await init();
        await _box!.put(_currentEntrega!.id, _currentEntrega!);
        notifyListeners();
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
      getValue: (e) =>
          e.itens.fold<double>(0, (sum, i) => sum + i.valorTotal),
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
  /// Returns a sorted list of (year, month) → totalKg.
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
  /// Returns sorted list of (first day of period) → totalKg.
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
        DateTime(int.parse(parts[0]), int.parse(parts[1]),
            int.parse(parts[2])),
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
        DateTime(int.parse(parts[0]), int.parse(parts[1]),
            int.parse(parts[2])),
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
  Future<void> clearAll() async {
    if (_box == null) await init();
    await _box!.clear();
    _currentEntrega = null;
    notifyListeners();
  }
}
