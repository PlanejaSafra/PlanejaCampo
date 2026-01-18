import 'package:hive_flutter/hive_flutter.dart';
import '../models/registro_chuva.dart';

/// Service responsible for managing rainfall records storage using Hive.
class ChuvaService {
  static const String _boxName = 'registros_chuva';

  // Singleton instance
  static final ChuvaService _instance = ChuvaService._internal();
  factory ChuvaService() => _instance;
  ChuvaService._internal();

  late Box<RegistroChuva> _box;

  /// Initializes the Hive box and registers the adapter.
  Future<void> init() async {
    Hive.registerAdapter(RegistroChuvaAdapter());
    _box = await Hive.openBox<RegistroChuva>(_boxName);
  }

  /// Returns all records sorted by date descending (most recent first).
  List<RegistroChuva> listarTodos() {
    final todos = _box.values.toList();
    todos.sort((a, b) => b.data.compareTo(a.data));
    return todos;
  }

  /// Adds a new record to the box.
  Future<void> adicionar(RegistroChuva registro) async {
    await _box.put(registro.id.toString(), registro);
  }

  /// Updates an existing record.
  Future<void> atualizar(RegistroChuva registro) async {
    await _box.put(registro.id.toString(), registro);
  }

  /// Deletes a record by its ID.
  Future<void> excluir(int id) async {
    await _box.delete(id.toString());
  }

  /// Calculates the total rainfall for a specific month.
  double totalDoMes(DateTime dataReferencia) {
    return _box.values
        .where((r) =>
            r.data.year == dataReferencia.year &&
            r.data.month == dataReferencia.month)
        .fold(0.0, (sum, r) => sum + r.milimetros);
  }
}
