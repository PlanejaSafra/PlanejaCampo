import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'cash_categoria.g.dart';

/// Expense category enum for RuraCash.
@HiveType(typeId: 70)
enum CashCategoria {
  @HiveField(0)
  maoDeObra,

  @HiveField(1)
  adubo,

  @HiveField(2)
  defensivos,

  @HiveField(3)
  combustivel,

  @HiveField(4)
  manutencao,

  @HiveField(5)
  energia,

  @HiveField(6)
  outros;

  /// Icon for the category.
  IconData get icon {
    switch (this) {
      case CashCategoria.maoDeObra:
        return Icons.engineering;
      case CashCategoria.adubo:
        return Icons.eco;
      case CashCategoria.defensivos:
        return Icons.science;
      case CashCategoria.combustivel:
        return Icons.local_gas_station;
      case CashCategoria.manutencao:
        return Icons.build;
      case CashCategoria.energia:
        return Icons.bolt;
      case CashCategoria.outros:
        return Icons.category;
    }
  }

  /// Color for the category.
  Color get color {
    switch (this) {
      case CashCategoria.maoDeObra:
        return Colors.blue;
      case CashCategoria.adubo:
        return Colors.green;
      case CashCategoria.defensivos:
        return Colors.purple;
      case CashCategoria.combustivel:
        return Colors.orange;
      case CashCategoria.manutencao:
        return Colors.grey;
      case CashCategoria.energia:
        return Colors.amber;
      case CashCategoria.outros:
        return Colors.brown;
    }
  }

  /// Localized label key accessor.
  String localizedName(dynamic l10n) {
    switch (this) {
      case CashCategoria.maoDeObra:
        return l10n.catMaoDeObra;
      case CashCategoria.adubo:
        return l10n.catAdubo;
      case CashCategoria.defensivos:
        return l10n.catDefensivos;
      case CashCategoria.combustivel:
        return l10n.catCombustivel;
      case CashCategoria.manutencao:
        return l10n.catManutencao;
      case CashCategoria.energia:
        return l10n.catEnergia;
      case CashCategoria.outros:
        return l10n.catOutros;
    }
  }
}
