import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/parceiro.dart';

class ParceiroService extends ChangeNotifier {
  static const String boxName = 'parceiros';
  Box<Parceiro>? _box;

  List<Parceiro> get parceiros => _box?.values.toList() ?? [];

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<Parceiro>(boxName);
    notifyListeners();
  }

  Future<void> addParceiro(Parceiro parceiro) async {
    if (_box == null) await init();
    await _box!.put(parceiro.id, parceiro);
    notifyListeners();
  }

  Future<void> updateParceiro(Parceiro parceiro) async {
    await parceiro.save();
    notifyListeners();
  }

  Future<void> deleteParceiro(String id) async {
    if (_box == null) return;
    await _box!.delete(id);
    notifyListeners();
  }

  Parceiro? getParceiro(String id) {
    return _box?.get(id);
  }

  /// Clear all parceiros (used for restore).
  Future<void> clearAll() async {
    if (_box == null) await init();
    await _box!.clear();
    notifyListeners();
  }
}
