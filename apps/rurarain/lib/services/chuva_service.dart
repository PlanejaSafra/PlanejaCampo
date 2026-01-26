import 'package:agro_core/agro_core.dart';
import 'package:agro_core/services/sync/generic_sync_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/registro_chuva.dart';

/// Serviço de Chuva migrado para GenericSyncService (CORE-83)
class ChuvaService extends GenericSyncService<RegistroChuva> {
  static final ChuvaService instance = ChuvaService._();
  ChuvaService._();
  factory ChuvaService() => instance;

  @override
  String get boxName => 'registros_chuva';

  @override
  String get sourceApp => 'rurarain';

  @override
  bool get syncEnabled => true;

  @override
  RegistroChuva fromMap(Map<String, dynamic> map) =>
      RegistroChuva.fromJson(map);

  @override
  Map<String, dynamic> toMap(RegistroChuva item) => item.toJson();

  @override
  String getId(RegistroChuva item) => item.id.toString();

  @override
  Future<void> init() async {
    await super.init();
    await _migrateDataIfNeeded();
  }

  /// Migra dados antigos (Objetos) para nova estrutura (Maps com Metadata)
  Future<void> _migrateDataIfNeeded() async {
    // Acesso direto ao box privado da classe pai seria ideal,
    // mas GenericSyncService não expõe _box publicamente.
    // Porem, ele usa LocalCacheManager.
    // Vamos abrir o box como dinamico para verificar
    final box = Hive.box(boxName);

    if (box.isEmpty) return;

    final firstKey = box.keys.first;
    final firstValue = box.get(firstKey);

    // Se encontrar um objeto RegistroChuva (antigo), migra tudo para Map
    if (firstValue is RegistroChuva) {
      debugPrint('[ChuvaService] Migrating data from Adapter to Map...');
      final Map<dynamic, dynamic> rawMap = box.toMap();

      for (final entry in rawMap.entries) {
        if (entry.value is RegistroChuva) {
          final item = entry.value as RegistroChuva;
          // Usa o método add do GenericSyncService para salvar como Map + Metadata
          await super.update(item.id.toString(), item);
        }
      }
      debugPrint('[ChuvaService] Migration completed.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos de Listagem (Adaptados)
  // ─────────────────────────────────────────────────────────────────────

  /// Retorna todos os registros ordenados por data (mais recente primeiro)
  List<RegistroChuva> listarTodos({String? propertyId}) {
    var todos = getAll();

    if (propertyId != null && propertyId.isNotEmpty) {
      todos = todos.where((r) => r.propertyId == propertyId).toList();
    }

    todos.sort((a, b) => b.data.compareTo(a.data));
    return todos;
  }

  /// Adiciona novo registro
  Future<void> adicionar(RegistroChuva registro) async {
    await super.add(registro);
    await _updateWidget();
    // Sync é automático pelo GenericSyncService (CORE-78)
  }

  /// Atualiza registro existente
  Future<void> atualizar(RegistroChuva registro) async {
    await super.update(registro.id.toString(), registro);
    await _updateWidget();
  }

  /// Exclui registro
  Future<void> excluir(int id) async {
    await super.delete(id.toString());
    await _updateWidget();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Lógica de Talhões
  // ─────────────────────────────────────────────────────────────────────

  List<RegistroChuva> _filteredByTalhao(String propertyId, String? talhaoId) {
    // Usa getAll() do GenericSyncService (que já trata cache)
    return getAll()
        .where((r) =>
            r.propertyId == propertyId &&
            (talhaoId == null ? r.talhaoId == null : r.talhaoId == talhaoId))
        .toList();
  }

  List<RegistroChuva> listarPropriedadeToda(String propertyId) {
    return _filteredByTalhao(propertyId, null)
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  List<RegistroChuva> listarPorTalhao(String propertyId, String talhaoId) {
    return _filteredByTalhao(propertyId, talhaoId)
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  List<RegistroChuva> listarByTalhao(String propertyId, {String? talhaoId}) {
    return _filteredByTalhao(propertyId, talhaoId)
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  double totalPropriedadeToda(String propertyId) {
    return _filteredByTalhao(propertyId, null)
        .fold(0.0, (sum, r) => sum + r.milimetros);
  }

  double totalPorTalhao(String propertyId, String talhaoId) {
    return _filteredByTalhao(propertyId, talhaoId)
        .fold(0.0, (sum, r) => sum + r.milimetros);
  }

  double totalByTalhao(String propertyId, {String? talhaoId}) {
    return _filteredByTalhao(propertyId, talhaoId)
        .fold(0.0, (sum, r) => sum + r.milimetros);
  }

  int getRecordCountForTalhao(String propertyId, {String? talhaoId}) {
    return _filteredByTalhao(propertyId, talhaoId).length;
  }

  int getRecordCountForProperty(String propertyId) {
    return getAll().where((r) => r.propertyId == propertyId).length;
  }

  int getRecordCountByTalhaoId(String talhaoId) {
    return getAll().where((r) => r.talhaoId == talhaoId).length;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────

  /// Total do mês
  double totalDoMes(DateTime dataReferencia, {String? propertyId}) {
    var registros = getAll().where((r) =>
        r.data.year == dataReferencia.year &&
        r.data.month == dataReferencia.month);

    if (propertyId != null && propertyId.isNotEmpty) {
      registros = registros.where((r) => r.propertyId == propertyId);
    }

    return registros.fold(0.0, (sum, r) => sum + r.milimetros);
  }

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

  Future<void> limparTodos() async {
    await super.clearAll();
    await _updateWidget();
  }

  Future<int> reassignTalhaoToProperty(String talhaoId) async {
    final records = getAll().where((r) => r.talhaoId == talhaoId).toList();

    for (final record in records) {
      final updated = record.copyWith(talhaoId: null); // Null = Property
      await atualizar(updated);
    }
    return records.length;
  }

  int? daysSinceLastRain() {
    final all = getAll();
    if (all.isEmpty) return null;

    final sorted = all..sort((a, b) => b.data.compareTo(a.data));
    final lastRain = sorted.first.data;
    final now = DateTime.now();

    final dateLast = DateTime(lastRain.year, lastRain.month, lastRain.day);
    final dateNow = DateTime(now.year, now.month, now.day);

    return dateNow.difference(dateLast).inDays;
  }

  Future<void> notifyRainLogged() async {
    // Placeholder legacy
  }

  // Widget Update Logic (Preserved)
  Future<void> _updateWidget() async {
    try {
      final todos = listarTodos();
      // Não temos acesso fácil ao box de settings aqui dentro,
      // mas vamos tentar manter a lógica se possível ou simplificar.
      // O ideal seria injetar essa dependencia.
      // Assumindo que o Hive de settings está acessível globalmente se aberto:

      String locale = 'pt_BR';
      if (Hive.isBoxOpen('settings')) {
        locale = Hive.box('settings').get('app_locale', defaultValue: 'pt_BR');
      }

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
      debugPrint('Error updating widget: $e');
    }
  }
}
