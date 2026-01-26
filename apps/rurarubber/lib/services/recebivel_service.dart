import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/recebivel.dart';

/// Service for managing receivables (recebíveis) in RuraRubber.
///
/// Provides CRUD operations, status queries, and period-based totals
/// for tracking amounts owed by buyers after rubber deliveries.
///
/// See RUBBER-18 for architecture.
class RecebivelService extends ChangeNotifier {
  static const String boxName = 'recebiveis';
  Box<Recebivel>? _box;

  static final RecebivelService _instance = RecebivelService._internal();
  static RecebivelService get instance => _instance;
  RecebivelService._internal();
  factory RecebivelService() => _instance;

  /// Initialize the Hive box for receivables.
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<Recebivel>(boxName);
    notifyListeners();
  }

  /// All receivables sorted by expected date (ascending).
  List<Recebivel> get recebiveis {
    if (_box == null) return [];
    final list = _box!.values.toList();
    list.sort((a, b) => a.dataPrevista.compareTo(b.dataPrevista));
    return list;
  }

  /// All pending (not yet received) receivables.
  List<Recebivel> get pendentes =>
      recebiveis.where((r) => !r.recebido).toList();

  /// All received (marked as paid) receivables.
  List<Recebivel> get recebidos =>
      recebiveis.where((r) => r.recebido).toList();

  /// Total value of pending receivables.
  double get totalPendente =>
      pendentes.fold(0, (sum, r) => sum + r.valor);

  /// Total value of received receivables.
  double get totalRecebido =>
      recebidos.fold(0, (sum, r) => sum + r.valor);

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
  double get totalEsteMes =>
      vencidosEsteMes.fold(0, (sum, r) => sum + r.valor);

  /// Create a new receivable linked to a delivery.
  Future<void> criarRecebivel({
    required String entregaId,
    required double valor,
    required DateTime dataPrevista,
    String? compradorNome,
  }) async {
    if (_box == null) await init();
    final recebivel = Recebivel.create(
      id: const Uuid().v4(),
      entregaId: entregaId,
      valor: valor,
      dataPrevista: dataPrevista,
      compradorNome: compradorNome,
    );
    await _box!.put(recebivel.id, recebivel);
    notifyListeners();
  }

  /// Mark a receivable as received (paid).
  Future<void> marcarRecebido(String id, {DateTime? dataRecebimento}) async {
    if (_box == null) await init();
    final recebivel = _box!.get(id);
    if (recebivel != null) {
      recebivel.recebido = true;
      recebivel.dataRecebimento = dataRecebimento ?? DateTime.now();
      await recebivel.save();
      notifyListeners();
    }
  }

  /// Delete a receivable by ID.
  Future<void> deleteRecebivel(String id) async {
    if (_box == null) await init();
    await _box!.delete(id);
    notifyListeners();
  }

  /// Clear all receivables (used for restore).
  Future<void> clearAll() async {
    if (_box == null) await init();
    await _box!.clear();
    notifyListeners();
  }
}
