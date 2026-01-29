import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:agro_core/agro_core.dart';

part 'conta.g.dart';

/// CASH-23: Account types.
@HiveType(typeId: 75)
enum TipoConta {
  @HiveField(0) carteira,       // Cash wallet
  @HiveField(1) contaCorrente,  // Checking account
  @HiveField(2) poupanca,       // Savings
  @HiveField(3) cartaoCredito,  // Credit card (passivo)
  @HiveField(4) investimento,   // Investment
  @HiveField(5) emprestimo,     // Loan (passivo)
}

/// CASH-23: Bank/financial account model.
@HiveType(typeId: 73)
class Conta extends HiveObject with FarmOwnedMixin implements SyncableEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  final TipoConta tipo;

  @HiveField(3)
  double saldoInicial;

  @HiveField(4)
  double saldoAtual;

  @HiveField(5)
  String? banco; // Bank name (optional)

  @HiveField(6)
  String? agencia;

  @HiveField(7)
  String? numeroConta;

  @HiveField(8)
  int corValue;

  @HiveField(9)
  bool isAtiva;

  // FarmOwnedEntity fields
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
  final String sourceApp;

  @HiveField(14)
  @override
  DateTime updatedAt;

  @HiveField(15)
  bool? deleted;

  Conta({
    required this.id,
    required this.nome,
    required this.tipo,
    this.saldoInicial = 0.0,
    this.saldoAtual = 0.0,
    this.banco,
    this.agencia,
    this.numeroConta,
    this.corValue = 0xFF2196F3,
    this.isAtiva = true,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.sourceApp = 'ruracash',
    this.deleted = false,
  });

  factory Conta.create({
    required String nome,
    required TipoConta tipo,
    double saldoInicial = 0.0,
    String? banco,
    String? agencia,
    String? numeroConta,
    int corValue = 0xFF2196F3,
  }) {
    final now = DateTime.now();
    return Conta(
      id: const Uuid().v4(),
      nome: nome,
      tipo: tipo,
      saldoInicial: saldoInicial,
      saldoAtual: saldoInicial,
      banco: banco,
      agencia: agencia,
      numeroConta: numeroConta,
      corValue: corValue,
      farmId: FarmService.instance.defaultFarmId ?? '',
      createdBy: AuthService.currentUser?.uid ?? '',
      createdAt: now,
      updatedAt: now,
    );
  }

  Color get cor => Color(corValue);

  /// Whether account is an asset (positive balance expected).
  bool get isAtivo => tipo == TipoConta.carteira ||
      tipo == TipoConta.contaCorrente ||
      tipo == TipoConta.poupanca ||
      tipo == TipoConta.investimento;

  /// Whether account is a liability (negative/debt).
  bool get isPassivo => tipo == TipoConta.cartaoCredito ||
      tipo == TipoConta.emprestimo;

  IconData get icone {
    switch (tipo) {
      case TipoConta.carteira:
        return Icons.account_balance_wallet;
      case TipoConta.contaCorrente:
        return Icons.account_balance;
      case TipoConta.poupanca:
        return Icons.savings;
      case TipoConta.cartaoCredito:
        return Icons.credit_card;
      case TipoConta.investimento:
        return Icons.trending_up;
      case TipoConta.emprestimo:
        return Icons.money_off;
    }
  }

  @override
  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo.index,
        'saldoInicial': saldoInicial,
        'saldoAtual': saldoAtual,
        'banco': banco,
        'agencia': agencia,
        'numeroConta': numeroConta,
        'corValue': corValue,
        'isAtiva': isAtiva,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'sourceApp': sourceApp,
        'deleted': deleted,
      };

  factory Conta.fromJson(Map<String, dynamic> json) => Conta(
        id: json['id'] as String,
        nome: json['nome'] as String,
        tipo: TipoConta.values[json['tipo'] as int? ?? 0],
        saldoInicial: (json['saldoInicial'] as num?)?.toDouble() ?? 0.0,
        saldoAtual: (json['saldoAtual'] as num?)?.toDouble() ?? 0.0,
        banco: json['banco'] as String?,
        agencia: json['agencia'] as String?,
        numeroConta: json['numeroConta'] as String?,
        corValue: json['corValue'] as int? ?? 0xFF2196F3,
        isAtiva: json['isAtiva'] as bool? ?? true,
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

  Conta copyWith({
    String? nome,
    double? saldoAtual,
    String? banco,
    String? agencia,
    String? numeroConta,
    int? corValue,
    bool? isAtiva,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return Conta(
      id: id,
      nome: nome ?? this.nome,
      tipo: tipo,
      saldoInicial: saldoInicial,
      saldoAtual: saldoAtual ?? this.saldoAtual,
      banco: banco ?? this.banco,
      agencia: agencia ?? this.agencia,
      numeroConta: numeroConta ?? this.numeroConta,
      corValue: corValue ?? this.corValue,
      isAtiva: isAtiva ?? this.isAtiva,
      farmId: farmId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sourceApp: sourceApp,
      deleted: deleted ?? this.deleted,
    );
  }
}
