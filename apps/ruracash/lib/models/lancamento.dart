import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:agro_core/agro_core.dart';
import 'cash_categoria.dart';

part 'lancamento.g.dart';

/// A financial entry (expense) in RuraCash.
@HiveType(typeId: 71)
class Lancamento extends HiveObject implements FarmOwnedEntity {
  @HiveField(0)
  @override
  String id;

  @HiveField(1)
  double valor;

  @HiveField(2)
  CashCategoria categoria;

  @HiveField(3)
  DateTime data;

  @HiveField(4)
  String? descricao;

  @HiveField(5)
  String? centroCustoId;

  // FarmOwnedEntity fields
  @HiveField(6)
  @override
  String farmId;

  @HiveField(7)
  @override
  String createdBy;

  @HiveField(8)
  @override
  DateTime createdAt;

  @HiveField(9)
  @override
  String sourceApp;

  Lancamento({
    required this.id,
    required this.valor,
    required this.categoria,
    required this.data,
    this.descricao,
    this.centroCustoId,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    this.sourceApp = 'ruracash',
  });

  /// Factory constructor with auto-populated metadata.
  factory Lancamento.create({
    required double valor,
    required CashCategoria categoria,
    DateTime? data,
    String? descricao,
    String? centroCustoId,
  }) {
    return Lancamento(
      id: const Uuid().v4(),
      valor: valor,
      categoria: categoria,
      data: data ?? DateTime.now(),
      descricao: descricao,
      centroCustoId: centroCustoId,
      farmId: FarmService.instance.defaultFarmId ?? '',
      createdBy: AuthService.currentUser?.uid ?? '',
      createdAt: DateTime.now(),
      sourceApp: 'ruracash',
    );
  }

  /// Serialization for backup.
  Map<String, dynamic> toJson() => {
        'id': id,
        'valor': valor,
        'categoria': categoria.index,
        'data': data.toIso8601String(),
        'descricao': descricao,
        'centroCustoId': centroCustoId,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'sourceApp': sourceApp,
      };

  /// Deserialization from backup.
  factory Lancamento.fromJson(Map<String, dynamic> json) => Lancamento(
        id: json['id'] as String,
        valor: (json['valor'] as num).toDouble(),
        categoria: CashCategoria.values[json['categoria'] as int],
        data: DateTime.parse(json['data'] as String),
        descricao: json['descricao'] as String?,
        centroCustoId: json['centroCustoId'] as String?,
        farmId: json['farmId'] as String? ?? '',
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        sourceApp: json['sourceApp'] as String? ?? 'ruracash',
      );
}
