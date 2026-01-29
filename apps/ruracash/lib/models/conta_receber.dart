import 'package:hive/hive.dart';
import 'package:agro_core/agro_core.dart';

part 'conta_receber.g.dart';

enum StatusRecebimento {
  @HiveField(0) pendente,
  @HiveField(1) recebido,
  @HiveField(2) vencido,
  @HiveField(3) cancelado
}

@HiveType(typeId: 81)
class ContaReceber extends HiveObject with FarmOwnedMixin implements SyncableEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  final String descricao;

  @HiveField(2)
  final double valor;

  @HiveField(3)
  final DateTime vencimento;

  @HiveField(4)
  final String? cliente;

  @HiveField(5)
  final String? categoriaId;

  /// Conta bancária onde o dinheiro VAI entrar (destino).
  /// Preenchido ao receber.
  @HiveField(6)
  final String? contaDestinoId;

  @HiveField(7)
  final StatusRecebimento status;

  @HiveField(8)
  final DateTime? dataRecebimento;

  /// ID da Receita criada no momento do recebimento?
  /// OU ID da Receita criada na venda a prazo?
  /// Seguindo a lógica do Pagar: Receita deve ser reconhecida na VENDA (Competência).
  @HiveField(9)
  final String? receitaOrigemId; // ID da Receita (venda)

  @HiveField(10)
  @override
  final String farmId;

  @HiveField(11)
  @override
  final String createdBy;

  @HiveField(12)
  @override
  final DateTime createdAt;

  @HiveField(13)
  @override
  DateTime updatedAt;

  @HiveField(14)
  @override
  final String sourceApp;

  @HiveField(15)
  bool? deleted;

  @override
  Map<String, dynamic> toMap() => toJson();

  ContaReceber({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.vencimento,
    this.cliente,
    this.categoriaId,
    this.contaDestinoId,
    required this.status,
    this.dataRecebimento,
    this.receitaOrigemId,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceApp,
    this.deleted = false,
  });

  bool get isVencido => status == StatusRecebimento.pendente && vencimento.isBefore(DateTime.now());
  int get diasParaVencer => vencimento.difference(DateTime.now()).inDays;

  /// Serialization for GenericSyncService / backup.
  Map<String, dynamic> toJson() => {
        'id': id,
        'descricao': descricao,
        'valor': valor,
        'vencimento': vencimento.toIso8601String(),
        'cliente': cliente,
        'categoriaId': categoriaId,
        'contaDestinoId': contaDestinoId,
        'status': status.index,
        'dataRecebimento': dataRecebimento?.toIso8601String(),
        'receitaOrigemId': receitaOrigemId,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'sourceApp': sourceApp,
        'deleted': deleted,
      };

  /// Deserialization from GenericSyncService / backup.
  factory ContaReceber.fromJson(Map<String, dynamic> json) => ContaReceber(
        id: json['id'] as String,
        descricao: json['descricao'] as String,
        valor: (json['valor'] as num).toDouble(),
        vencimento: DateTime.parse(json['vencimento'] as String),
        cliente: json['cliente'] as String?,
        categoriaId: json['categoriaId'] as String?,
        contaDestinoId: json['contaDestinoId'] as String?,
        status: StatusRecebimento.values[json['status'] as int? ?? 0],
        dataRecebimento: json['dataRecebimento'] != null
            ? DateTime.parse(json['dataRecebimento'] as String)
            : null,
        receitaOrigemId: json['receitaOrigemId'] as String?,
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

  ContaReceber copyWith({
    String? descricao,
    double? valor,
    DateTime? vencimento,
    String? cliente,
    StatusRecebimento? status,
    DateTime? dataRecebimento,
    String? contaDestinoId,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return ContaReceber(
      id: id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      vencimento: vencimento ?? this.vencimento,
      cliente: cliente ?? this.cliente,
      categoriaId: categoriaId,
      contaDestinoId: contaDestinoId ?? this.contaDestinoId,
      status: status ?? this.status,
      dataRecebimento: dataRecebimento ?? this.dataRecebimento,
      receitaOrigemId: receitaOrigemId,
      farmId: farmId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sourceApp: sourceApp,
      deleted: deleted ?? this.deleted,
    );
  }
}
