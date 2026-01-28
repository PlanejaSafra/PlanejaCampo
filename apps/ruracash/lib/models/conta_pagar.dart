import 'package:hive/hive.dart';
import 'package:agro_core/agro_core.dart'; // SyncableEntity, FarmOwnedEntity

part 'conta_pagar.g.dart';

enum StatusPagamento {
  @HiveField(0) pendente,
  @HiveField(1) pago,
  @HiveField(2) vencido,
  @HiveField(3) cancelado
}

@HiveType(typeId: 80)
class ContaPagar extends HiveObject with FarmOwnedMixin implements SyncableEntity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String descricao;

  @HiveField(2)
  final double valor;

  @HiveField(3)
  final DateTime vencimento;

  @HiveField(4)
  final String? fornecedor;

  @HiveField(5)
  final String? categoriaId; // Vinculo com Categoria

  @HiveField(6)
  final StatusPagamento status;

  @HiveField(7)
  final DateTime? dataPagamento;

  // --- Double-Entry Escondido ---
  
  /// ID do Lançamento criado no momento da COMPRA (reconhecimento da despesa).
  /// Se null, significa que a conta foi criada avulsa sem lançamento (legado ou erro).
  @HiveField(8)
  final String? lancamentoOrigemId;

  /// ID da Conta Bancária/Caixa usada para PAGAR.
  /// Só é preenchido quando status = pago.
  @HiveField(9)
  final String? contaPagamentoId;

  // --- Parcelamento ---

  @HiveField(10)
  final int? parcela; // 1, 2, 3...

  @HiveField(11)
  final int? totalParcelas;

  @HiveField(12)
  final String? parcelaGrupoId; // UUID que agrupa as parcelas

  // --- Metadata ---

  @HiveField(13)
  @override
  final String farmId;

  @HiveField(14)
  @override
  final String createdBy;

  @HiveField(15)
  @override
  final DateTime createdAt;

  @HiveField(16)
  @override
  DateTime updatedAt;

  @HiveField(17)
  @override
  final String sourceApp;

  @HiveField(18)
  @override
  bool? deleted;
  
  ContaPagar({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.vencimento,
    this.fornecedor,
    this.categoriaId,
    required this.status,
    this.dataPagamento,
    this.lancamentoOrigemId,
    this.contaPagamentoId,
    this.parcela,
    this.totalParcelas,
    this.parcelaGrupoId,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceApp,
    this.deleted = false,
  });

  bool get isVencido => status == StatusPagamento.pendente && vencimento.isBefore(DateTime.now());
  int get diasParaVencer => vencimento.difference(DateTime.now()).inDays;
  String get parcelaLabel => parcela != null ? '$parcela/${totalParcelas ?? '?'}' : '';

  ContaPagar copyWith({
    String? descricao,
    double? valor,
    DateTime? vencimento,
    String? fornecedor,
    StatusPagamento? status,
    DateTime? dataPagamento,
    String? contaPagamentoId,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return ContaPagar(
      id: id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      vencimento: vencimento ?? this.vencimento,
      fornecedor: fornecedor ?? this.fornecedor,
      categoriaId: categoriaId,
      status: status ?? this.status,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      lancamentoOrigemId: lancamentoOrigemId,
      contaPagamentoId: contaPagamentoId ?? this.contaPagamentoId,
      parcela: parcela,
      totalParcelas: totalParcelas,
      parcelaGrupoId: parcelaGrupoId,
      farmId: farmId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sourceApp: sourceApp,
      deleted: deleted ?? this.deleted,
    );
  }
}
