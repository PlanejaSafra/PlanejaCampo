import 'package:hive_flutter/hive_flutter.dart';
import 'sync_models.dart';

/// Gerenciador de cache local usando Hive
/// Encapsula operações de baixo nível com Boxes
class LocalCacheManager {
  static final LocalCacheManager instance = LocalCacheManager._();

  LocalCacheManager._();

  bool _initialized = false;
  final Map<String, Box<dynamic>> _openBoxes = {};

  // Cache de metadados de sync (último sync por coleção)
  Box<dynamic>? _metaBox;
  static const String _metaBoxName = 'sync_metadata_store';

  Future<void> init() async {
    if (_initialized) return;

    if (!Hive.isBoxOpen(_metaBoxName)) {
      _metaBox = await Hive.openBox(_metaBoxName);
    } else {
      _metaBox = Hive.box(_metaBoxName);
    }

    _initialized = true;
  }

  /// Retorna o timestamp do último sync bem sucedido para uma coleção
  DateTime? getLastSyncTimestamp(String collection) {
    if (!_initialized) return null;
    final val = _metaBox?.get('last_sync_$collection');
    if (val == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(val as int);
  }

  /// Atualiza o timestamp do último sync
  Future<void> setLastSyncTimestamp(
      String collection, DateTime timestamp) async {
    await _metaBox?.put(
        'last_sync_$collection', timestamp.millisecondsSinceEpoch);
  }

  /// Abre um box se necessário e o retorna
  /// Nota: O tipo T deve ser registrado no Hive
  Future<Box<T>> openBox<T>(String boxName) async {
    if (_openBoxes.containsKey(boxName)) {
      return _openBoxes[boxName] as Box<T>;
    }

    final box = await Hive.openBox<T>(boxName);
    _openBoxes[boxName] = box;
    return box;
  }

  /// Fecha um box específico
  Future<void> closeBox(String boxName) async {
    if (_openBoxes.containsKey(boxName)) {
      await _openBoxes[boxName]!.close();
      _openBoxes.remove(boxName);
    }
  }

  /// Lê um item do cache
  T? readFromCache<T>(String boxName, String id) {
    if (!_openBoxes.containsKey(boxName)) return null;
    return _openBoxes[boxName]!.get(id);
  }

  /// Lê múltiplos itens do cache
  List<T> readManyFromCache<T>(String boxName, List<String> ids) {
    if (!_openBoxes.containsKey(boxName)) return [];
    final box = _openBoxes[boxName]!;
    return ids.map((id) => box.get(id)).whereType<T>().toList();
  }

  /// Lê todos os itens do cache
  List<T> getAllFromCache<T>(String boxName) {
    if (!_openBoxes.containsKey(boxName)) return [];
    return _openBoxes[boxName]!.values.cast<T>().toList();
  }

  /// Salva no cache
  Future<void> updateCache<T>(String boxName, String id, T data) async {
    if (!_openBoxes.containsKey(boxName)) {
      await openBox<T>(boxName);
    }
    await _openBoxes[boxName]!.put(id, data);
  }

  /// Remove do cache
  Future<void> removeFromCache(String boxName, String id) async {
    if (!_openBoxes.containsKey(boxName)) return;
    await _openBoxes[boxName]!.delete(id);
  }

  /// Limpa toda a coleção (Cuidado!)
  Future<void> clearCollection(String boxName) async {
    if (!_openBoxes.containsKey(boxName)) return;
    await _openBoxes[boxName]!.clear();
  }

  /// Query em memória (filtra os valores do box)
  List<T> queryCache<T>(String boxName, bool Function(T) filter) {
    if (!_openBoxes.containsKey(boxName)) return [];
    return _openBoxes[boxName]!.values.cast<T>().where(filter).toList();
  }

  /// Estatísticas do cache
  Map<String, dynamic> getCacheStats(String boxName) {
    if (!_openBoxes.containsKey(boxName)) return {'status': 'closed'};
    final box = _openBoxes[boxName]!;
    return {
      'status': 'open',
      'count': box.length,
      'lastSync': getLastSyncTimestamp(boxName)?.toIso8601String(),
    };
  }
}
