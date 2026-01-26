import 'package:hive/hive.dart';

part 'item_entrega.g.dart';

@HiveType(typeId: 1)
class ItemEntrega extends HiveObject {
  @HiveField(0)
  final String parceiroId;

  @HiveField(1)
  final List<double> pesagens;

  @HiveField(2)
  double pesoTotal;

  @HiveField(3)
  double valorTotal;

  @HiveField(4)
  double descontos;

  ItemEntrega({
    required this.parceiroId,
    required this.pesagens,
    required this.pesoTotal,
    this.valorTotal = 0.0,
    this.descontos = 0.0,
  });

  // Calculate total weight from individual weighings
  void calcularPesoTotal() {
    pesoTotal = pesagens.fold(0, (sum, item) => sum + item);
  }

  // Add a new weighing and recalculate total
  void adicionarPesagem(double peso) {
    pesagens.add(peso);
    calcularPesoTotal();
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'parceiroId': parceiroId,
      'pesagens': pesagens,
      'pesoTotal': pesoTotal,
      'valorTotal': valorTotal,
      'descontos': descontos,
    };
  }

  /// Create from JSON (backup/import)
  factory ItemEntrega.fromJson(Map<String, dynamic> json) {
    return ItemEntrega(
      parceiroId: json['parceiroId'] as String,
      pesagens: (json['pesagens'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      pesoTotal: (json['pesoTotal'] as num).toDouble(),
      valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0.0,
      descontos: (json['descontos'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
