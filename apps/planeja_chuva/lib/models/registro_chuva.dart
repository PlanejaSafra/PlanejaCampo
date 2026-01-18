import 'package:hive/hive.dart';

part 'registro_chuva.g.dart';

@HiveType(typeId: 1)
class RegistroChuva extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime data;

  @HiveField(2)
  final double milimetros;

  @HiveField(3)
  final String? observacao;

  @HiveField(4)
  final DateTime criadoEm;

  RegistroChuva({
    required this.id,
    required this.data,
    required this.milimetros,
    this.observacao,
    required this.criadoEm,
  });

  /// Factory for creating a new record with auto-generated ID
  factory RegistroChuva.novo({
    required DateTime data,
    required double milimetros,
    String? observacao,
  }) {
    final agora = DateTime.now();
    return RegistroChuva(
      id: agora.millisecondsSinceEpoch,
      data: data,
      milimetros: milimetros,
      observacao: observacao,
      criadoEm: agora,
    );
  }
}
