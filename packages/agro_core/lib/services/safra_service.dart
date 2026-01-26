import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/safra.dart';

/// Service for managing agricultural seasons (Safras) in the RuraCamp ecosystem.
///
/// Safra (Crop Season) is the "temporal umbrella" for all apps:
/// - It represents an agricultural year (September → August)
/// - All apps query their data within the active safra period
/// - Totals are calculated dynamically via query, NEVER stored
///
/// ## Usage
/// ```dart
/// // Initialize in main.dart (after SafraAdapter registration)
/// await SafraService.instance.init();
///
/// // Get or create active safra for current farm
/// final safra = await SafraService.instance.ensureAtivaSafra(farmId: farmId);
///
/// // Filter records by safra period
/// final filtered = SafraService.instance.filterBySafra(
///   records: allRecords,
///   safra: safra,
///   getDate: (r) => r.data,
/// );
///
/// // Calculate totals within a safra
/// final totalMm = SafraService.instance.sumBySafra(
///   records: allRecords,
///   safra: safra,
///   getDate: (r) => r.data,
///   getValue: (r) => r.milimetros,
/// );
/// ```
///
/// See CORE-76 for architecture details.
class SafraService {
  static const String _boxName = 'safras';

  // Singleton
  static final SafraService _instance = SafraService._internal();
  static SafraService get instance => _instance;
  factory SafraService() => _instance;
  SafraService._internal();

  late Box<Safra> _box;
  bool _initialized = false;

  /// Initialize Hive box.
  /// Must be called from main.dart AFTER [SafraAdapter] registration.
  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<Safra>(_boxName);
    _initialized = true;
  }

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  // ─────────────────────────────────────────────────────────────────────
  // CRUD Operations
  // ─────────────────────────────────────────────────────────────────────

  /// Get all safras for a farm, sorted by start date (newest first).
  List<Safra> getAllSafras(String farmId) {
    return _box.values.where((s) => s.farmId == farmId).toList()
      ..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
  }

  /// Get only closed (previous) safras for a farm, newest first.
  List<Safra> getSafrasAnteriores(String farmId) {
    return getAllSafras(farmId).where((s) => !s.ativa).toList();
  }

  /// Get the active safra for a farm.
  /// Returns null if no active safra exists.
  Safra? getAtiva(String farmId) {
    try {
      return _box.values.firstWhere(
        (s) => s.farmId == farmId && s.ativa,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get a safra by its ID.
  Safra? getSafraById(String id) {
    return _box.get(id);
  }

  /// Create a new safra.
  ///
  /// If [ativa] is true, deactivates any other active safra for the same farm.
  Future<Safra> createSafra({
    required String farmId,
    required String nome,
    required DateTime dataInicio,
    DateTime? dataFim,
    bool ativa = true,
  }) async {
    if (ativa) {
      await _deactivateOthers(farmId);
    }

    final safra = Safra.create(
      farmId: farmId,
      nome: nome,
      dataInicio: dataInicio,
      dataFim: dataFim,
      ativa: ativa,
    );

    await _box.put(safra.id, safra);
    debugPrint('[SafraService] Created: ${safra.nome} (ativa: $ativa)');
    return safra;
  }

  /// Ensure there is an active safra for the given farm.
  ///
  /// If no active safra exists, creates one based on the current date.
  /// The safra name is auto-generated (e.g., "Safra 2025/2026").
  ///
  /// Returns the active safra (existing or newly created).
  ///
  /// [l10n] is reserved for future localized safra name support.
  Future<Safra> ensureAtivaSafra({
    required String farmId,
    AgroLocalizations? l10n,
  }) async {
    final existing = getAtiva(farmId);
    if (existing != null) return existing;

    // Determine current agricultural year
    final startYear = Safra.agriculturalStartYear();
    final nome = Safra.generateName(startYear);
    final dataInicio = DateTime(startYear, 9, 1);

    return createSafra(
      farmId: farmId,
      nome: nome,
      dataInicio: dataInicio,
      ativa: true,
    );
  }

  /// Update an existing safra.
  Future<void> updateSafra(Safra safra) async {
    await _box.put(safra.id, safra);
  }

  /// Delete a safra by ID.
  Future<void> deleteSafra(String id) async {
    await _box.delete(id);
  }

  /// Clear all safras for a farm (used during restore).
  Future<void> clearAllForFarm(String farmId) async {
    final ids = _box.values
        .where((s) => s.farmId == farmId)
        .map((s) => s.id)
        .toList();

    for (final id in ids) {
      await _box.delete(id);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Encerrar Safra (CORE-76.4)
  // ─────────────────────────────────────────────────────────────────────

  /// Close the current active safra and create the next one automatically.
  ///
  /// Steps:
  /// 1. Sets `dataFim` on current safra (end of August, end-of-day)
  /// 2. Sets `ativa = false`
  /// 3. Creates the next safra (startYear + 1) as the new active safra
  ///
  /// Returns the newly created safra.
  ///
  /// Throws [SafraNotFoundException] if the safra ID is not found.
  Future<Safra> encerrarSafra(String safraId) async {
    final safra = getSafraById(safraId);
    if (safra == null) {
      throw SafraNotFoundException(safraId);
    }

    // Close current safra
    safra.encerrar();
    await _box.put(safra.id, safra);

    // Create next safra automatically
    final nextStartYear = safra.startYear + 1;
    final nextNome = Safra.generateName(nextStartYear);
    final nextDataInicio = DateTime(nextStartYear, 9, 1);

    final newSafra = await createSafra(
      farmId: safra.farmId,
      nome: nextNome,
      dataInicio: nextDataInicio,
      ativa: true,
    );

    debugPrint(
        '[SafraService] Encerrada: ${safra.nome} → ${newSafra.nome}');
    return newSafra;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Query Helpers (CORE-76.5)
  // ─────────────────────────────────────────────────────────────────────

  /// Filter a list of records by the safra's time period.
  ///
  /// Generic helper that works with any record type.
  /// [getDate] extracts the relevant date from each record.
  ///
  /// Example:
  /// ```dart
  /// final filtered = SafraService.instance.filterBySafra(
  ///   records: chuvaService.listarTodos(),
  ///   safra: safraAtiva,
  ///   getDate: (r) => r.data,
  /// );
  /// ```
  List<T> filterBySafra<T>({
    required List<T> records,
    required Safra safra,
    required DateTime Function(T) getDate,
  }) {
    return records.where((r) => safra.containsDate(getDate(r))).toList();
  }

  /// Calculate a numeric sum for records within a safra period.
  ///
  /// Example:
  /// ```dart
  /// final totalMm = SafraService.instance.sumBySafra(
  ///   records: chuvaService.listarTodos(),
  ///   safra: safraAtiva,
  ///   getDate: (r) => r.data,
  ///   getValue: (r) => r.milimetros,
  /// );
  /// ```
  double sumBySafra<T>({
    required List<T> records,
    required Safra safra,
    required DateTime Function(T) getDate,
    required double Function(T) getValue,
  }) {
    return filterBySafra(records: records, safra: safra, getDate: getDate)
        .fold(0.0, (sum, r) => sum + getValue(r));
  }

  /// Count records within a safra period.
  int countBySafra<T>({
    required List<T> records,
    required Safra safra,
    required DateTime Function(T) getDate,
  }) {
    return filterBySafra(records: records, safra: safra, getDate: getDate)
        .length;
  }

  /// Get the safra that contains a specific date for a given farm.
  ///
  /// Returns null if no safra covers the specified date.
  Safra? getSafraForDate(String farmId, DateTime date) {
    try {
      return _box.values.firstWhere(
        (s) => s.farmId == farmId && s.containsDate(date),
      );
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Backup Helpers
  // ─────────────────────────────────────────────────────────────────────

  /// Export all safras for a farm as a list of JSON maps.
  List<Map<String, dynamic>> exportSafras(String farmId) {
    return getAllSafras(farmId).map((s) => s.toJson()).toList();
  }

  /// Import safras from a JSON list (backup restore).
  Future<void> importSafras(List<dynamic> safrasJson) async {
    for (final json in safrasJson) {
      final safra = Safra.fromJson(json as Map<String, dynamic>);
      await _box.put(safra.id, safra);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────

  /// Deactivate all active safras for a farm.
  Future<void> _deactivateOthers(String farmId) async {
    final actives = _box.values
        .where((s) => s.farmId == farmId && s.ativa)
        .toList();

    for (final safra in actives) {
      safra.ativa = false;
      await _box.put(safra.id, safra);
    }
  }
}

/// Exception thrown when a safra is not found by ID.
class SafraNotFoundException implements Exception {
  final String safraId;
  const SafraNotFoundException(this.safraId);

  @override
  String toString() => 'SafraNotFoundException: Safra "$safraId" not found';
}
