import 'package:flutter/material.dart'; // For DateRange (if using Flutter's) or just custom
import 'package:hive/hive.dart';
import 'package:agro_core/agro_core.dart';

part 'orcamento.g.dart';

@HiveType(typeId: 83)
enum TipoPeriodoOrcamento {
  @HiveField(0) mes,        // Janeiro, Fevereiro, etc.
  @HiveField(1) trimestre,  // Q1, Q2, Q3, Q4
  @HiveField(2) safra,      // Set-Ago (ciclo agrícola)
  @HiveField(3) ano,        // Janeiro-Dezembro
}

@HiveType(typeId: 82)
class Orcamento extends HiveObject with FarmOwnedMixin implements SyncableEntity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoriaId;

  @HiveField(2)
  final double valorLimite;

  @HiveField(3)
  final TipoPeriodoOrcamento tipo;

  @HiveField(4)
  final int ano; // Ano de vigência (ou ano INÍCIO da safra)

  @HiveField(5)
  final int? mes; // Só se tipo=mes

  @HiveField(6)
  final int? trimestre; // 1-4

  @HiveField(7)
  final bool alertaAtivo;

  @HiveField(8)
  final int alertaPercentual; // ex: 80

  @HiveField(9)
  @override
  final String farmId;

  // SyncableEntity metadata
  @HiveField(10)
  @override
  final String createdBy;

  @HiveField(11)
  @override
  final DateTime createdAt;

  @HiveField(12)
  @override
  DateTime updatedAt;

  @HiveField(13)
  @override
  final String sourceApp;

  @HiveField(14)
  @override
  bool? deleted;

  Orcamento({
    required this.id,
    required this.categoriaId,
    required this.valorLimite,
    required this.tipo,
    required this.ano,
    this.mes,
    this.trimestre,
    this.alertaAtivo = true,
    this.alertaPercentual = 80,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceApp,
    this.deleted = false,
  });

  /// Retorna o range de datas que este orçamento cobre
  DateTimeRange get periodo => _calcularPeriodo();

  DateTimeRange _calcularPeriodo() {
    DateTime inicio;
    DateTime fim;

    switch (tipo) {
      case TipoPeriodoOrcamento.mes:
        inicio = DateTime(ano, mes!);
        fim = DateTime(ano, mes! + 1, 0); // Último dia do mês
        break;
      case TipoPeriodoOrcamento.trimestre:
        final mesInicio = (trimestre! - 1) * 3 + 1;
        inicio = DateTime(ano, mesInicio);
        fim = DateTime(ano, mesInicio + 3, 0);
        break;
      case TipoPeriodoOrcamento.safra:
        // Safra: 1 Set (ano) até 31 Ago (ano + 1)
        inicio = DateTime(ano, 9, 1);
        fim = DateTime(ano + 1, 8, 31);
        break;
      case TipoPeriodoOrcamento.ano:
        inicio = DateTime(ano, 1, 1);
        fim = DateTime(ano, 12, 31);
        break;
    }

    // Ajusta fim para o final do dia (23:59:59)
    fim = DateTime(fim.year, fim.month, fim.day, 23, 59, 59, 999);
    return DateTimeRange(start: inicio, end: fim);
  }

  /// Serialization for GenericSyncService / backup.
  Map<String, dynamic> toJson() => {
        'id': id,
        'categoriaId': categoriaId,
        'valorLimite': valorLimite,
        'tipo': tipo.index,
        'ano': ano,
        'mes': mes,
        'trimestre': trimestre,
        'alertaAtivo': alertaAtivo,
        'alertaPercentual': alertaPercentual,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'sourceApp': sourceApp,
        'deleted': deleted,
      };

  /// Deserialization from GenericSyncService / backup.
  factory Orcamento.fromJson(Map<String, dynamic> json) => Orcamento(
        id: json['id'] as String,
        categoriaId: json['categoriaId'] as String,
        valorLimite: (json['valorLimite'] as num).toDouble(),
        tipo: TipoPeriodoOrcamento.values[json['tipo'] as int? ?? 0],
        ano: json['ano'] as int,
        mes: json['mes'] as int?,
        trimestre: json['trimestre'] as int?,
        alertaAtivo: json['alertaAtivo'] as bool? ?? true,
        alertaPercentual: json['alertaPercentual'] as int? ?? 80,
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

  Orcamento copyWith({
    double? valorLimite,
    bool? alertaAtivo,
    int? alertaPercentual,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return Orcamento(
      id: id,
      categoriaId: categoriaId,
      valorLimite: valorLimite ?? this.valorLimite,
      tipo: tipo,
      ano: ano,
      mes: mes,
      trimestre: trimestre,
      alertaAtivo: alertaAtivo ?? this.alertaAtivo,
      alertaPercentual: alertaPercentual ?? this.alertaPercentual,
      farmId: farmId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sourceApp: sourceApp,
      deleted: deleted ?? this.deleted,
    );
  }
}
