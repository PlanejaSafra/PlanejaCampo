import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class OperacaoRuralOptions {
  // Lista de fases principais para operações rurais
  static const List<String> fases = [
    'Preparo de Solo',    // Operações iniciais de correção e preparo do solo
    'Pré-Plantio',        // Operações que antecedem o plantio, como adubação prévia
    'Plantio',            // Fase de semeadura
    'Pós-Plantio',        // Manutenção e aplicação de nutrientes após o plantio
    'Colheita',           // Etapa de colheita
    'Outros',             // Categoria para operações adicionais ou específicas
  ];

  // Internacionalização das fases
  static Map<String, String> getLocalizedFasesOperacoes(BuildContext context) {
    return {
      'Preparo de Solo': S.of(context).soil_preparation,
      'Pré-Plantio': S.of(context).pre_planting,
      'Plantio': S.of(context).planting,
      'Pós-Plantio': S.of(context).post_planting,
      'Colheita': S.of(context).harvest,
      'Outros': S.of(context).others,
    };
  }

  // Retorna uma lista de fases localizadas como Strings
  static List<String> getLocalizedFasesOperacoesString(BuildContext context) {
    return getLocalizedFasesOperacoes(context).values.toList();
  }
}
