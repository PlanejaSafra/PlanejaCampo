import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/entrega.dart';
import '../models/item_entrega.dart';

class EntregaService extends ChangeNotifier {
  static const String boxName = 'entregas';
  late Box<Entrega> _box;

  // Active session data
  Entrega? _currentEntrega;

  List<Entrega> get entregas =>
      _box.values.toList()..sort((a, b) => b.data.compareTo(a.data));
  Entrega? get currentEntrega => _currentEntrega;

  Future<void> init() async {
    _box = await Hive.openBox<Entrega>(boxName);
    _checkForOpenEntrega();
    notifyListeners();
  }

  void _checkForOpenEntrega() {
    // Find the most recent 'Aberto' entrega
    try {
      final openEntregas =
          _box.values.where((e) => e.status == 'Aberto').toList();
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
    _currentEntrega = Entrega(
      id: const Uuid().v4(),
      data: DateTime.now(),
      status: 'Aberto',
      itens: [],
    );
    notifyListeners();
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
    await _box.put(_currentEntrega!.id, _currentEntrega!);
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
        await _box.put(_currentEntrega!.id, _currentEntrega!);
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
}
