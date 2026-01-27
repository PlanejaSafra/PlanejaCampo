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
  outros,

  // Personal Categories (CASH-09)
  @HiveField(7)
  alimentacao,

  @HiveField(8)
  transporte,

  @HiveField(9)
  saude,

  @HiveField(10)
  educacao,

  @HiveField(11)
  lazer,

  @HiveField(12)
  moradia,

  @HiveField(13)
  outrosPessoal;

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
      // Personal
      case CashCategoria.alimentacao:
        return Icons.restaurant;
      case CashCategoria.transporte:
        return Icons.directions_car;
      case CashCategoria.saude:
        return Icons.local_hospital;
      case CashCategoria.educacao:
        return Icons.school;
      case CashCategoria.lazer:
        return Icons.beach_access;
      case CashCategoria.moradia:
        return Icons.home;
      case CashCategoria.outrosPessoal:
        return Icons.more_horiz;
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
      // Personal
      case CashCategoria.alimentacao:
        return Colors.red;
      case CashCategoria.transporte:
        return Colors.blueGrey;
      case CashCategoria.saude:
        return Colors.teal;
      case CashCategoria.educacao:
        return Colors.indigo;
      case CashCategoria.lazer:
        return Colors.orangeAccent;
      case CashCategoria.moradia:
        return Colors.brown;
      case CashCategoria.outrosPessoal:
        return Colors.grey;
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
      // Personal
      case CashCategoria.alimentacao:
        return l10n.catAlimentacao;
      case CashCategoria.transporte:
        return l10n.catTransporte;
      case CashCategoria.saude:
        return l10n.catSaude;
      case CashCategoria.educacao:
        return l10n.catEducacao;
      case CashCategoria.lazer:
        return l10n.catLazer;
      case CashCategoria.moradia:
        return l10n.catMoradia;
      case CashCategoria.outrosPessoal:
        return l10n.catOutrosPessoal;
    }
  }

  bool get isAgro => index <= 6;
  bool get isPersonal => index >= 7;
}
