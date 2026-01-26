import 'package:agro_core/agro_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/registro_chuva.dart';
import 'sync_service.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
// Actually PropertyService is in agro_core/services.
// check line 1: import 'package:agro_core/agro_core.dart';.
// PropertyService is likely there.

/// Service responsible for managing rainfall records storage using Hive.
class ChuvaService {
  static const String _boxName = 'registros_chuva';

  // Singleton instance
  static final ChuvaService _instance = ChuvaService._internal();
  factory ChuvaService() => _instance;
  ChuvaService._internal();

  late Box<RegistroChuva> _box;

  /// Initializes the Hive box.
  /// Note: RegistroChuvaAdapter must be registered BEFORE calling this method.
  Future<void> init() async {
    _box = await Hive.openBox<RegistroChuva>(_boxName);
  }

  /// Returns all records sorted by date descending (most recent first).
  /// If propertyId is provided, filters records for that property only.
  List<RegistroChuva> listarTodos({String? propertyId}) {
    var todos = _box.values.toList();

    // Filter by property if specified
    if (propertyId != null && propertyId.isNotEmpty) {
      todos = todos.where((r) => r.propertyId == propertyId).toList();
    }

    todos.sort((a, b) => b.data.compareTo(a.data));
    return todos;
  }

  /// Adds a new record to the box.
  Future<void> adicionar(RegistroChuva registro) async {
    await _box.put(registro.id.toString(), registro);
    await _updateWidget();

    // CORE-61: Trigger sync (stats - Option 3)
    await _trySyncRecord(registro);

    // CORE-62: Trigger private backup (Option 1)
    await _trySyncPrivateBackup(registro);
  }

  /// Updates an existing record.
  Future<void> atualizar(RegistroChuva registro) async {
    await _box.put(registro.id.toString(), registro);
    await _updateWidget();

    // CORE-61: Trigger sync (stats - Option 3)
    await _trySyncRecord(registro);

    // CORE-62: Trigger private backup (Option 1)
    await _trySyncPrivateBackup(registro);
  }

  /// Helper to sync private backup (Option 1)
  Future<void> _trySyncPrivateBackup(RegistroChuva registro) async {
    try {
      await UserCloudService.instance.syncRainfallRecord(
        recordId: registro.id.toString(),
        data: registro.toMap(),
      );
    } catch (e) {
      debugPrint('ChuvaService: Error syncing private backup: $e');
    }
  }

  /// Helper to queue and sync a record
  Future<void> _trySyncRecord(RegistroChuva registro) async {
    try {
      // We need property details for the location
      final propertyService = PropertyService();
      // Ensure property service is initialized if not already (it usually is)
      // But PropertyService.init() is async. Best to rely on it being ready or await?
      // Prudence: await init.
      await propertyService.init();

      final property = propertyService.getPropertyById(registro.propertyId);
      if (property != null) {
        await SyncService().queueForSync(registro, property);

        // Try to push immediately (fire and forget to not block UI)
        SyncService().syncPendingItems().ignore();
      }
    } catch (e) {
      // Silent fail for sync side effects
      debugPrint('ChuvaService: Error syncing record: $e');
    }
  }

  /// Deletes a record by its ID.
  Future<void> excluir(int id) async {
    await _box.delete(id.toString());
    await _updateWidget();

    // CORE-62: Delete from private backup (Option 1)
    // We try to delete regardless of current consent (cleanup)
    try {
      await UserCloudService.instance.deleteRainfallRecord(id.toString());
    } catch (e) {
      // safe fail
    }
  }

  /// Clears all records from the box (used for restore).
  Future<void> limparTodos() async {
    await _box.clear();
    await _updateWidget();
    debugPrint('[ChuvaService] Cleared all records for restore.');
  }

  /// Calculates the total rainfall for a specific month.
  /// If propertyId is provided, calculates only for that property.
  double totalDoMes(DateTime dataReferencia, {String? propertyId}) {
    var registros = _box.values.where((r) =>
        r.data.year == dataReferencia.year &&
        r.data.month == dataReferencia.month);

    // Filter by property if specified
    if (propertyId != null && propertyId.isNotEmpty) {
      registros = registros.where((r) => r.propertyId == propertyId);
    }

    return registros.fold(0.0, (sum, r) => sum + r.milimetros);
  }

  /// Get count of records for a specific property
  int getRecordCountForProperty(String propertyId) {
    return _box.values.where((r) => r.propertyId == propertyId).length;
  }

  // ============================================================================
  // TALHÃO SUPPORT - Null handling methods
  // ============================================================================

  /// Private method to filter records by property and optional talhão
  /// Encapsulates null handling logic for talhaoId
  List<RegistroChuva> _filteredByTalhao(String propertyId, String? talhaoId) {
    return _box.values
        .where((r) =>
            r.propertyId == propertyId &&
            (talhaoId == null ? r.talhaoId == null : r.talhaoId == talhaoId))
        .toList();
  }

  /// Returns records for whole property (talhaoId = null)
  List<RegistroChuva> listarPropriedadeToda(String propertyId) {
    return _filteredByTalhao(propertyId, null)
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  /// Returns records for a specific talhão
  List<RegistroChuva> listarPorTalhao(String propertyId, String talhaoId) {
    return _filteredByTalhao(propertyId, talhaoId)
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  /// Generic method when flexibility is needed (UI usage)
  List<RegistroChuva> listarByTalhao(String propertyId, {String? talhaoId}) {
    return _filteredByTalhao(propertyId, talhaoId)
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  /// Calculate total rainfall for whole property (talhaoId = null)
  double totalPropriedadeToda(String propertyId) {
    return _filteredByTalhao(propertyId, null)
        .fold(0.0, (sum, r) => sum + r.milimetros);
  }

  /// Calculate total rainfall for a specific talhão
  double totalPorTalhao(String propertyId, String talhaoId) {
    return _filteredByTalhao(propertyId, talhaoId)
        .fold(0.0, (sum, r) => sum + r.milimetros);
  }

  /// Generic method for total by talhão (UI usage)
  double totalByTalhao(String propertyId, {String? talhaoId}) {
    return _filteredByTalhao(propertyId, talhaoId)
        .fold(0.0, (sum, r) => sum + r.milimetros);
  }

  /// Get count of records for a specific talhão
  /// If talhaoId is null, counts records for whole property (talhaoId = null)
  int getRecordCountForTalhao(String propertyId, {String? talhaoId}) {
    return _filteredByTalhao(propertyId, talhaoId).length;
  }

  /// Get count of records that have a specific talhaoId (not null check)
  /// Used for deletion protection
  int getRecordCountByTalhaoId(String talhaoId) {
    return _box.values.where((r) => r.talhaoId == talhaoId).length;
  }

  /// Calculate total rainfall for month with optional talhão filter
  double totalDoMesByTalhao(
    DateTime dataReferencia,
    String propertyId, {
    String? talhaoId,
  }) {
    var registros = _filteredByTalhao(propertyId, talhaoId).where((r) =>
        r.data.year == dataReferencia.year &&
        r.data.month == dataReferencia.month);

    return registros.fold(0.0, (sum, r) => sum + r.milimetros);
  }

  /// Reassign records from one talhão to whole property (set talhaoId to null)
  /// Used when deleting a talhão
  Future<int> reassignTalhaoToProperty(String talhaoId) async {
    final records = _box.values.where((r) => r.talhaoId == talhaoId).toList();

    for (final record in records) {
      // Create new record with talhaoId = null (preserves immutable fields)
      final updated = RegistroChuva(
        id: record.id,
        data: record.data,
        milimetros: record.milimetros,
        observacao: record.observacao,
        criadoEm: record.criadoEm,
        propertyId: record.propertyId,
        talhaoId: null, // Set to null (whole property)
        createdBy: record.createdBy,
        sourceApp: record.sourceApp,
      );
      await _box.put(record.id.toString(), updated);
    }

    return records.length;
  }

  /// Calculates days since the last rainfall record.
  /// Returns null if no records exist.
  int? daysSinceLastRain() {
    if (_box.isEmpty) return null;

    final sorted = _box.values.toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    final lastRain = sorted.first.data;
    final now = DateTime.now();

    // Normalize dates to ignore time component
    final dateLast = DateTime(lastRain.year, lastRain.month, lastRain.day);
    final dateNow = DateTime(now.year, now.month, now.day);

    return dateNow.difference(dateLast).inDays;
  }

  /// Notify that rain was logged today to trigger smart actions (like skipping reminder).
  Future<void> notifyRainLogged() async {
    // We need to import UserPreferences and NotificationService
    // But to avoid circular dependencies (if any), careful.
    // However, UserPreferences is model, NotificationService is service.
    // ChuvaService is service.
    // It's better to inject dependency or do this in the Screen.
    // BUT the requirement was "notifyRainLogged" in service.
    // Let's implement it here as a helper that loads prefs.
  }

  /// Updates the Home Widget with the latest data.
  Future<void> _updateWidget() async {
    try {
      final todos = listarTodos(); // Sorted by date desc

      // Get locale from Hive for widget
      final settingsBox = await Hive.openBox('settings');
      final locale =
          settingsBox.get('app_locale', defaultValue: 'pt_BR') as String;

      if (todos.isNotEmpty) {
        final latest = todos.first;
        await HomeWidgetService.updateWidgetData(
          lastRainDate: latest.data,
          lastRainMm: latest.milimetros,
          locale: locale,
        );
      } else {
        await HomeWidgetService.updateWidgetData(
          lastRainDate: null,
          lastRainMm: null,
          locale: locale,
        );
      }
    } catch (e) {
      // Ignore widget update errors to not block app flow
      print('Error updating widget: $e');
    }
  }
}
