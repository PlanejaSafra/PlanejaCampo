import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/recebivel.dart';

/// Service for managing receivables (recebíveis) in RuraRubber.
/// Migrated to GenericSyncService (CORE-83).
class RecebivelService extends GenericSyncService<Recebivel> {
  static final RecebivelService _instance = RecebivelService._internal();
  static RecebivelService get instance => _instance;
  RecebivelService._internal();
  factory RecebivelService() => _instance;

  @override
  String get boxName => 'recebiveis';

  @override
  String get sourceApp => 'rurarubber';

  @override
  bool get syncEnabled => true;

  @override
  Recebivel fromMap(Map<String, dynamic> map) => Recebivel.fromJson(map);

  @override
  Map<String, dynamic> toMap(Recebivel item) => item.toJson();

  @override
  String getId(Recebivel item) => item.id;

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

    if (firstValue is Recebivel) {
      debugPrint('[RecebivelService] Migrating data from Adapter to Map...');
      final Map<dynamic, dynamic> rawMap = box.toMap();

      for (final entry in rawMap.entries) {
        if (entry.value is Recebivel) {
          final item = entry.value as Recebivel;
          await super.update(item.id, item);
        }
      }
      debugPrint('[RecebivelService] Migration completed.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────────────

  /// All receivables sorted by expected date (ascending).
  List<Recebivel> get recebiveis {
    final list = getAll();
    list.sort((a, b) => a.dataPrevista.compareTo(b.dataPrevista));
    return list;
  }

  /// All pending (not yet received) receivables.
  List<Recebivel> get pendentes =>
      recebiveis.where((r) => !r.recebido).toList();

  /// All received (marked as paid) receivables.
  List<Recebivel> get recebidos => recebiveis.where((r) => r.recebido).toList();

  /// Total value of pending receivables.
  double get totalPendente => pendentes.fold(0, (sum, r) => sum + r.valor);

  /// Total value of received receivables.
  double get totalRecebido => recebidos.fold(0, (sum, r) => sum + r.valor);

  /// Pending receivables due this week (up to end of current week).
  List<Recebivel> get vencidosEstaSemana {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    final endOfWeekEnd = DateTime(
      endOfWeek.year,
      endOfWeek.month,
      endOfWeek.day,
      23,
      59,
      59,
    );
    return pendentes
        .where((r) =>
            r.dataPrevista.isBefore(endOfWeekEnd) ||
            r.dataPrevista.isAtSameMomentAs(endOfWeekEnd))
        .toList();
  }

  /// Pending receivables due this month (up to end of current month).
  List<Recebivel> get vencidosEsteMes {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return pendentes
        .where((r) =>
            r.dataPrevista.isBefore(endOfMonth) ||
            r.dataPrevista.isAtSameMomentAs(endOfMonth))
        .toList();
  }

  /// Total value of pending receivables due this week.
  double get totalEstaSemana =>
      vencidosEstaSemana.fold(0, (sum, r) => sum + r.valor);

  /// Total value of pending receivables due this month.
  double get totalEsteMes => vencidosEsteMes.fold(0, (sum, r) => sum + r.valor);

  // ─────────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────────

  /// Create a new receivable linked to a delivery.
  Future<void> criarRecebivel({
    required String entregaId,
    required double valor,
    required DateTime dataPrevista,
    String? compradorNome,
  }) async {
    final recebivel = Recebivel.create(
      id: const Uuid().v4(),
      entregaId: entregaId,
      valor: valor,
      dataPrevista: dataPrevista,
      compradorNome: compradorNome,
    );
    await super.add(recebivel);
  }

  /// Mark a receivable as received (paid).
  Future<void> marcarRecebido(String id, {DateTime? dataRecebimento}) async {
    final recebivel = getById(id);
    if (recebivel != null) {
      recebivel.recebido = true;
      recebivel.dataRecebimento = dataRecebimento ?? DateTime.now();
      await super.update(id, recebivel);
    }
  }

  /// Update a receivable (replaces existing with same ID).
  Future<void> updateRecebivel({
    required String id,
    required double valor,
    required DateTime dataPrevista,
    String? compradorNome,
  }) async {
    final existing = getById(id);
    if (existing == null) return;

    final updated = Recebivel(
      id: existing.id,
      entregaId: existing.entregaId,
      valor: valor,
      dataPrevista: dataPrevista,
      compradorNome: compradorNome,
      recebido: existing.recebido,
      dataRecebimento: existing.dataRecebimento,
      farmId: existing.farmId,
      createdBy: existing.createdBy,
      createdAt: existing.createdAt,
      sourceApp: existing.sourceApp,
    );

    await super.update(id, updated);
  }

  /// Delete a receivable by ID.
  Future<void> deleteRecebivel(String id) async {
    await super.delete(id);
  }

  /// Clear all receivables (used for restore).
  @override
  Future<void> clearAll() async {
    await super.clearAll();
  }
}
