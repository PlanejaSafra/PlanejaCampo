import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class ManualAdubacaoOptions {
  // Lista de manuais de adubação com nome, sigla do país e sigla do estado
  static const List<Map<String, String>> manuais = [
    {
      'nomeManual': 'Manual de Adubação SP IAC 100 2022',
      'paisSigla': 'BR',
      'estadoSigla': 'SP'
    },
    // Outros manuais podem ser adicionados aqui
  ];

  // Lista de culturas para cada manual
  static const Map<String, List<String>> culturas = {
    'Manual de Adubação SP IAC 100 2022': ['Soja', 'Milho', 'Cana-de-Açúcar'],
  };

  // Mapeamento dos nomes dos manuais para suas siglas localizadas
  static Map<String, String> getLocalizedManuais(BuildContext context) {
    return {
      'Manual de Adubação SP IAC 100 2022': S.of(context).manual_adubacao_sp_iac_100_2022,
      // Outros manuais localizados podem ser adicionados aqui
    };
  }

  // Mapeamento das culturas para tradução localizada
  static Map<String, String> getLocalizedCulturas(BuildContext context) {
    return {
      'Soja': S.of(context).soybean,
      'Milho': S.of(context).corn,
      'Cana-de-Açúcar': S.of(context).sugarcane,
    };
  }

  // Retorna uma lista de nomes localizados dos manuais
  static List<String> getLocalizedManuaisString(BuildContext context) {
    return getLocalizedManuais(context).values.toList();
  }

  // Retorna uma lista de culturas localizadas por manual
  static List<String> getLocalizedCulturasByManual(BuildContext context, String nomeManual) {
    return culturas[nomeManual]
        ?.map((cultura) => getLocalizedCulturas(context)[cultura] ?? cultura)
        .toList() ??
        [];
  }

  // Retorna o nome do manual localizado a partir do nome original
  static String getNomeManual(BuildContext context, String nomeManual) {
    return getLocalizedManuais(context)[nomeManual] ?? nomeManual;
  }

  // Retorna a lista de culturas suportadas por um manual
  static List<String> getCulturasByManual(String nomeManual) {
    return culturas[nomeManual] ?? [];
  }

  // Adicione estes métodos à classe ManualAdubacaoOptions

// Método que retorna cores específicas para cada nutriente
  static Color getNutrienteColor(String nutriente, {Color? defaultColor}) {
    if (nutriente.contains('N')) return Colors.green;
    if (nutriente.contains('P')) return Colors.orange;
    if (nutriente.contains('K')) return Colors.purple;
    if (nutriente.contains('Zn')) return Colors.blue;
    if (nutriente.contains('B')) return Colors.red;
    if (nutriente.contains('Cu')) return Colors.cyan;
    if (nutriente.contains('Mn')) return Colors.amber;
    return defaultColor ?? Colors.teal; // Cor padrão caso nenhuma corresponda
  }

// Método que retorna símbolos de nutrientes
  static String getNutrienteSimbolo(String nutriente) {
    if (nutriente.contains('N')) return 'N';
    if (nutriente.contains('P')) return 'P';
    if (nutriente.contains('K')) return 'K';
    if (nutriente.contains('Zn')) return 'Zn';
    if (nutriente.contains('B')) return 'B';
    if (nutriente.contains('Cu')) return 'Cu';
    if (nutriente.contains('Mn')) return 'Mn';

    // Extrair o primeiro caractere ou primeiro caractere de cada palavra
    final palavras = nutriente.split(' ');
    if (palavras.length > 1) {
      return palavras.map((p) => p.isNotEmpty ? p[0] : '').join('');
    }

    return nutriente.isNotEmpty ? nutriente[0] : '?';
  }
}
