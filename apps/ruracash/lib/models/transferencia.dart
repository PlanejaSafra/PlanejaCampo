import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:agro_core/agro_core.dart';

part 'transferencia.g.dart';

/// CASH-25: Transfer between accounts.
/// Transfers don't affect DRE (not revenue nor expense).
@HiveType(typeId: 79)
class Transferencia extends HiveObject with FarmOwnedMixin implements SyncableEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  final String contaOrigemId;

  @HiveField(2)
  final String contaDestinoId;

  @HiveField(3)
  double valor;

  @HiveField(4)
  DateTime data;

  @HiveField(5)
  String? descricao;

  // FarmOwnedEntity fields
  @HiveField(6)
  @override
  final String farmId;

  @HiveField(7)
  @override
  final String createdBy;

  @HiveField(8)
  @override
  final DateTime createdAt;

  @HiveField(9)
  @override
  final String sourceApp;

  @HiveField(10)
  @override
  DateTime updatedAt;

  @HiveField(11)
  bool? deleted;

  Transferencia({
    required this.id,
    required this.contaOrigemId,
    required this.contaDestinoId,
    required this.valor,
    required this.data,
    this.descricao,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.sourceApp = 'ruracash',
    this.deleted = false,
  });

  factory Transferencia.create({
    required String contaOrigemId,
    required String contaDestinoId,
    required double valor,
    DateTime? data,
    String? descricao,
  }) {
    final now = DateTime.now();
    return Transferencia(
      id: const Uuid().v4(),
      contaOrigemId: contaOrigemId,
      contaDestinoId: contaDestinoId,
      valor: valor,
      data: data ?? now,
      descricao: descricao,
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
        'contaOrigemId': contaOrigemId,
        'contaDestinoId': contaDestinoId,
        'valor': valor,
        'data': data.toIso8601String(),
        'descricao': descricao,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'sourceApp': sourceApp,
        'deleted': deleted,
      };

  factory Transferencia.fromJson(Map<String, dynamic> json) => Transferencia(
        id: json['id'] as String,
        contaOrigemId: json['contaOrigemId'] as String,
        contaDestinoId: json['contaDestinoId'] as String,
        valor: (json['valor'] as num).toDouble(),
        data: DateTime.parse(json['data'] as String),
        descricao: json['descricao'] as String?,
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
}
