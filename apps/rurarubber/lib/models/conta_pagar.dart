import 'package:agro_core/agro_core.dart';
import 'package:hive/hive.dart';

part 'conta_pagar.g.dart';

@HiveType(typeId: 61)
enum FormaPagamento {
  @HiveField(0)
  pix,
  @HiveField(1)
  ted,
  @HiveField(2)
  dinheiro,
}

@HiveType(typeId: 62)
class ContaPagar extends HiveObject implements FarmOwnedEntity {
  @override
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String parceiroId;

  @HiveField(2)
  final String? entregaId;

  @HiveField(3)
  final double valor;

  @HiveField(4)
  final DateTime vencimento;

  @HiveField(5)
  bool pago;

  @HiveField(6)
  DateTime? dataPagamento;

  @HiveField(7)
  FormaPagamento? formaPagamento;

  @override
  @HiveField(8)
  final String farmId;

  @override
  @HiveField(9)
  final String createdBy;

  @override
  @HiveField(10)
  final DateTime createdAt;

  @override
  @HiveField(11)
  final String sourceApp;

  ContaPagar({
    required this.id,
    required this.parceiroId,
    this.entregaId,
    required this.valor,
    required this.vencimento,
    this.pago = false,
    this.dataPagamento,
    this.formaPagamento,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    this.sourceApp = 'rurarubber',
  });

  /// Factory for creating a new ContaPagar with auto-filled metadata.
  factory ContaPagar.create({
    required String id,
    required String parceiroId,
    String? entregaId,
    required double valor,
    required DateTime vencimento,
  }) {
    return ContaPagar(
      id: id,
      parceiroId: parceiroId,
      entregaId: entregaId,
      valor: valor,
      vencimento: vencimento,
      farmId: FarmService.instance.defaultFarmId ?? '',
      createdBy: AuthService.currentUser?.uid ?? '',
      createdAt: DateTime.now(),
    );
  }

  /// Whether this account is overdue (past due date and not paid).
  bool get isVencido => !pago && vencimento.isBefore(DateTime.now());

  /// Days until due date (negative if overdue).
  int get diasParaVencer => vencimento.difference(DateTime.now()).inDays;

  /// Convert to JSON for backup/export.
  Map<String, dynamic> toJson() => {
        'id': id,
        'parceiroId': parceiroId,
        'entregaId': entregaId,
        'valor': valor,
        'vencimento': vencimento.toIso8601String(),
        'pago': pago,
        'dataPagamento': dataPagamento?.toIso8601String(),
        'formaPagamento': formaPagamento?.index,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'sourceApp': sourceApp,
      };

  /// Create from JSON (backup/import).
  factory ContaPagar.fromJson(Map<String, dynamic> json) => ContaPagar(
        id: json['id'] as String,
        parceiroId: json['parceiroId'] as String,
        entregaId: json['entregaId'] as String?,
        valor: (json['valor'] as num).toDouble(),
        vencimento: DateTime.parse(json['vencimento'] as String),
        pago: json['pago'] as bool? ?? false,
        dataPagamento: json['dataPagamento'] != null
            ? DateTime.parse(json['dataPagamento'] as String)
            : null,
        formaPagamento: json['formaPagamento'] != null
            ? FormaPagamento.values[json['formaPagamento'] as int]
            : null,
        farmId: json['farmId'] as String? ?? '',
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        sourceApp: json['sourceApp'] as String? ?? 'rurarubber',
      );
}
