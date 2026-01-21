import 'package:hive/hive.dart';

part 'parceiro.g.dart';

@HiveType(typeId: 0)
class Parceiro extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  double percentualPadrao;

  @HiveField(3)
  String? telefone;

  @HiveField(4)
  List<String> tarefasIds;

  @HiveField(5)
  String? fotoPath;

  Parceiro({
    required this.id,
    required this.nome,
    required this.percentualPadrao,
    this.telefone,
    this.tarefasIds = const [],
    this.fotoPath,
  });
}
