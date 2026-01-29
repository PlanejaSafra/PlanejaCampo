import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:agro_core/agro_core.dart';

part 'receita.g.dart';

/// CASH-24: Revenue/income entry model.
@HiveType(typeId: 74)
class Receita extends HiveObject with FarmOwnedMixin implements SyncableEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  double valor;

  @HiveField(2)
  String categoriaId;

  @HiveField(3)
  DateTime data;

  @HiveField(4)
  String? descricao;

  @HiveField(5)
  String? centroCustoId;

  /// CASH-23: Conta destino da receita (opcional, null = carteira/caixa)
  @HiveField(6)
  String? contaDestinoId;

  // FarmOwnedEntity fields
  @HiveField(7)
  @override
  final String farmId;

  @HiveField(8)
  @override
  final String createdBy;

  @HiveField(9)
  @override
  final DateTime createdAt;

  @HiveField(10)
  @override
  final String sourceApp;

  @HiveField(11)
  @override
  DateTime updatedAt;

  @HiveField(12)
  bool? deleted;

  Receita({
    required this.id,
    required this.valor,
    required this.categoriaId,
    required this.data,
    this.descricao,
    this.centroCustoId,
    this.contaDestinoId,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.sourceApp = 'ruracash',
    this.deleted = false,
  });

  factory Receita.create({
    required double valor,
    required String categoriaId,
    DateTime? data,
    String? descricao,
    String? centroCustoId,
    String? contaDestinoId,
  }) {
    final now = DateTime.now();
    return Receita(
      id: const Uuid().v4(),
      valor: valor,
      categoriaId: categoriaId,
      data: data ?? now,
      descricao: descricao,
      centroCustoId: centroCustoId,
      contaDestinoId: contaDestinoId,
      farmId: FarmService.instance.defaultFarmId ?? '',
      createdBy: AuthService.currentUser?.uid ?? '',
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
        'id': id,
        'valor': valor,
        'categoriaId': categoriaId,
        'data': data.toIso8601String(),
        'descricao': descricao,
        'centroCustoId': centroCustoId,
        'contaDestinoId': contaDestinoId,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'sourceApp': sourceApp,
        'deleted': deleted,
      };

  factory Receita.fromJson(Map<String, dynamic> json) => Receita(
        id: json['id'] as String,
        valor: (json['valor'] as num).toDouble(),
        categoriaId: json['categoriaId'] as String,
        data: DateTime.parse(json['data'] as String),
        descricao: json['descricao'] as String?,
        centroCustoId: json['centroCustoId'] as String?,
        contaDestinoId: json['contaDestinoId'] as String?,
        farmId: json['farmId'] as String? ?? '',
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        sourceApp: json['sourceApp'] as String? ?? 'ruracash',
        deleted: json['deleted'] as bool? ?? false,
      );

  Receita copyWith({
    double? valor,
    String? categoriaId,
    DateTime? data,
    String? descricao,
    String? centroCustoId,
    String? contaDestinoId,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return Receita(
      id: id,
      valor: valor ?? this.valor,
      categoriaId: categoriaId ?? this.categoriaId,
      data: data ?? this.data,
      descricao: descricao ?? this.descricao,
      centroCustoId: centroCustoId ?? this.centroCustoId,
      contaDestinoId: contaDestinoId ?? this.contaDestinoId,
      farmId: farmId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sourceApp: sourceApp,
      deleted: deleted ?? this.deleted,
    );
  }
}
