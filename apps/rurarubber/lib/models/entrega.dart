import 'package:hive/hive.dart';
import 'item_entrega.dart';

part 'entrega.g.dart';

@HiveType(typeId: 2)
class Entrega extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime data;

  @HiveField(2)
  String status; // 'Aberto', 'Fechado', 'Pago'

  @HiveField(3)
  double? precoDrc;

  @HiveField(4)
  double? precoUmido;

  @HiveField(5)
  String? compradorId;

  @HiveField(6)
  List<ItemEntrega> itens;

  Entrega({
    required this.id,
    required this.data,
    this.status = 'Aberto',
    this.precoDrc,
    this.precoUmido,
    this.compradorId,
    this.itens = const [],
  });

  double get pesoTotalGeral {
    return itens.fold(0, (sum, item) => sum + item.pesoTotal);
  }
}
