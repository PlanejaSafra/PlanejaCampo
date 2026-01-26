import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/centro_custo.dart';

/// Service for managing cost centers.
class CentroCustoService extends ChangeNotifier {
  static final CentroCustoService _instance = CentroCustoService._internal();
  static CentroCustoService get instance => _instance;
  factory CentroCustoService() => _instance;
  CentroCustoService._internal();

  static const String _boxName = 'centros_custo';
  late Box<CentroCusto> _box;

  /// Initialize the service and ensure default center exists.
  Future<void> init() async {
    _box = await Hive.openBox<CentroCusto>(_boxName);
    await _ensureDefaultCentroCusto();
  }

  /// All cost centers sorted by name.
  List<CentroCusto> get centros {
    final list = _box.values.toList();
    list.sort((a, b) => a.nome.compareTo(b.nome));
    return list;
  }

  /// Get a center by ID.
  CentroCusto? getCentroCusto(String id) {
    return _box.get(id);
  }

  /// Get the default center (first one, usually "Geral").
  CentroCusto? get defaultCentroCusto {
    if (_box.isEmpty) return null;
    return _box.values.first;
  }

  /// Add a new cost center.
  Future<CentroCusto> addCentroCusto(CentroCusto centro) async {
    await _box.put(centro.id, centro);
    notifyListeners();
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
    await _box.put(centro.id, centro);
    notifyListeners();
  }

  /// Delete a center.
  Future<void> deleteCentroCusto(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  /// Ensure at least one default center exists.
  Future<void> _ensureDefaultCentroCusto() async {
    if (_box.isEmpty) {
      await createCentroCusto(
        nome: 'Geral',
        corValue: 0xFF607D8B,
      );
    }
  }

  /// Clear all centers.
  Future<void> clearAll() async {
    await _box.clear();
    notifyListeners();
  }

  /// Backup helpers.
  List<Map<String, dynamic>> toJsonList() {
    return centros.map((c) => c.toJson()).toList();
  }

  Future<void> importFromJson(List<dynamic> jsonList) async {
    for (final json in jsonList) {
      final centro = CentroCusto.fromJson(json as Map<String, dynamic>);
      if (!_box.containsKey(centro.id)) {
        await _box.put(centro.id, centro);
      }
    }
    notifyListeners();
  }
}
