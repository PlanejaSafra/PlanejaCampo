import 'package:planejacampo/models/agro/adubacao/epoca_aplicacao.dart';
import 'package:planejacampo/models/enums.dart';

/// Representa os parâmetros de uma cultura para adubação.
class CulturaParametros {
  final String id;
  final String manualAdubacao;
  final TipoCultura cultura;
  final CicloCultura? ciclo;
  final double produtividadeMinima;
  final double produtividadeMaxima;
  final double saturacaoBasesIdeal;
  final double teorMinimoMagnesio;
  final Map<String, dynamic> parametrosCalagem;
  final Map<String, dynamic> parametrosGessagem;
  final int espacamentoEntrelinhasMin;
  final int espacamentoEntrelinhasMax;
  final int populacaoMinima;
  final int populacaoMaxima;
  final bool permiteParcelamentoN;
  final bool permiteIrrigacao;
  final Map<String, Map<String, double>> teoresCriticosMacro;
  final Map<String, Map<String, double>> teoresCriticosMicro;
  final Map<String, Map<double, Map<String, double>>> recomendacaoNPK;
  final Map<String, Map<String, double>> recomendacaoMicro;
  final Map<String, double> faixasTextura;
  final Map<String, double> limitesMaximosNutrientes;
  final Map<String, double> limitesMaximosSulco;
  final Map<String, List<String>> fontesNutrientes;
  final Map<String, Map<String, double>> fatorAjusteDoses;
  final Map<String, EpocaAplicacao> epocasAplicacao;
  final List<String> restricoesAplicacao;
  final List<String> observacoesManejo;
  final List<String> observacoesGerais;
  final bool usaFBN;
  // Novo campo para parâmetros adicionais
  final Map<String, dynamic>? parametrosAdicionais;

  CulturaParametros({
    required this.id,
    required this.manualAdubacao,
    required this.cultura,
    this.ciclo,
    required this.produtividadeMinima,
    required this.produtividadeMaxima,
    required this.saturacaoBasesIdeal,
    required this.teorMinimoMagnesio,
    required this.parametrosCalagem,
    required this.parametrosGessagem,
    required this.espacamentoEntrelinhasMin,
    required this.espacamentoEntrelinhasMax,
    required this.populacaoMinima,
    required this.populacaoMaxima,
    required this.permiteParcelamentoN,
    required this.permiteIrrigacao,
    required this.teoresCriticosMacro,
    required this.teoresCriticosMicro,
    required this.recomendacaoNPK,
    required this.recomendacaoMicro,
    required this.faixasTextura,
    required this.limitesMaximosNutrientes,
    required this.limitesMaximosSulco,
    required this.fontesNutrientes,
    required this.fatorAjusteDoses,
    required this.epocasAplicacao,
    this.restricoesAplicacao = const [],
    this.observacoesManejo = const [],
    this.observacoesGerais = const [],
    this.usaFBN = false,
    this.parametrosAdicionais, // Adicionado ao construtor
  });

  factory CulturaParametros.fromMap(Map<String, dynamic> map, String id) {
    // Funções auxiliares (inalteradas)
    Map<String, double> _toDoubleMap(Map? m) {
      final result = <String, double>{};
      if (m != null && m is Map) {
        m.forEach((key, value) {
          final doubleValue = (value is num)
              ? value.toDouble()
              : double.tryParse(value.toString()) ?? 0.0;
          result[key.toString()] = doubleValue;
        });
      }
      return result;
    };

    Map<String, Map<String, double>> _toNestedDoubleMap(Map? m) => {
      for (var e in (m ?? {}).entries)
        e.key.toString(): _toDoubleMap(e.value as Map?)
    };

    Map<String, Map<double, Map<String, double>>> _toNPKMap(Map? m) => {
      for (var e in (m ?? {}).entries)
        e.key.toString(): {
          for (var p in (e.value as Map).entries)
            (p.key is num
                ? p.key.toDouble()
                : double.tryParse(p.key.toString()) ?? 0.0): {
              for (var i in (p.value as Map).entries)
                i.key.toString(): (i.value as num?)?.toDouble() ?? 0.0
            }
        }
    };

    List<String> _toList(List? l) => l?.map((e) => e.toString()).toList() ?? [];

    // Adiciona a lógica para extrair parametrosAdicionais
    final paRaw = map['parametrosAdicionais'];
    final Map<String, dynamic>? parametrosAdicionaisMap =
    paRaw is Map ? Map<String, dynamic>.from(paRaw) : null;

    return CulturaParametros(
      id: id,
      manualAdubacao: map['manualAdubacao']?.toString() ?? '',
      cultura: TipoCultura.fromString(map['cultura']?.toString() ?? ''),
      ciclo: map['ciclo'] != null
          ? CicloCultura.fromString(map['ciclo'].toString())
          : null,
      produtividadeMinima:
      (map['produtividadeMinima'] as num?)?.toDouble() ?? 0.0,
      produtividadeMaxima:
      (map['produtividadeMaxima'] as num?)?.toDouble() ?? 0.0,
      saturacaoBasesIdeal:
      (map['saturacaoBasesIdeal'] as num?)?.toDouble() ?? 0.0,
      teorMinimoMagnesio:
      (map['teorMinimoMagnesio'] as num?)?.toDouble() ?? 0.0,
      parametrosCalagem:
      Map<String, dynamic>.from(map['parametrosCalagem'] ?? {}),
      parametrosGessagem:
      Map<String, dynamic>.from(map['parametrosGessagem'] ?? {}),
      espacamentoEntrelinhasMin:
      (map['espacamentoEntrelinhasMin'] as num?)?.toInt() ?? 0,
      espacamentoEntrelinhasMax:
      (map['espacamentoEntrelinhasMax'] as num?)?.toInt() ?? 0,
      populacaoMinima: (map['populacaoMinima'] as num?)?.toInt() ?? 0,
      populacaoMaxima: (map['populacaoMaxima'] as num?)?.toInt() ?? 0,
      permiteParcelamentoN: map['permiteParcelamentoN'] as bool? ?? false,
      permiteIrrigacao: map['permiteIrrigacao'] as bool? ?? false,
      teoresCriticosMacro: _toNestedDoubleMap(map['teoresCriticosMacro']),
      teoresCriticosMicro: _toNestedDoubleMap(map['teoresCriticosMicro']),
      recomendacaoNPK: _toNPKMap(map['recomendacaoNPK']),
      recomendacaoMicro: _toNestedDoubleMap(map['recomendacaoMicro']),
      faixasTextura: _toDoubleMap(map['faixasTextura']),
      limitesMaximosNutrientes: _toDoubleMap(map['limitesMaximosNutrientes']),
      limitesMaximosSulco: _toDoubleMap(map['limitesMaximosSulco']),
      fontesNutrientes: (map['fontesNutrientes'] as Map?)
          ?.map((k, v) => MapEntry(k.toString(), _toList(v))) ??
          {},
      fatorAjusteDoses: _toNestedDoubleMap(map['fatorAjusteDoses']),
      epocasAplicacao: (map['epocasAplicacao'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), EpocaAplicacao.fromMap(v))) ??
          {},
      restricoesAplicacao: _toList(map['restricoesAplicacao']),
      observacoesManejo: _toList(map['observacoesManejo']),
      observacoesGerais: _toList(map['observacoesGerais']),
      usaFBN: map['usaFBN'] as bool? ?? false,
      parametrosAdicionais: parametrosAdicionaisMap, // Adicionado aqui
    );
  }

  Map<String, dynamic> toMap() {
    // Helper function para converter o mapa NPK para um formato compatível com Firestore (inalterada)
    Map<String, Map<String, Map<String, double>>> _convertNPKForFirestore(
        Map<String, Map<double, Map<String, double>>> npkMap) {
      final Map<String, Map<String, Map<String, double>>> result = {};
      npkMap.forEach((nutriente, prodMap) {
        final Map<String, Map<String, double>> prodMapForFirestore = {};
        prodMap.forEach((prodDoubleKey, interpMap) {
          // Converte a chave double (ex: 6.0) para String (ex: "6.0")
          final String prodStringKey = prodDoubleKey.toString();
          prodMapForFirestore[prodStringKey] = interpMap;
        });
        result[nutriente] = prodMapForFirestore;
      });
      return result;
    }

    return {
      'manualAdubacao': manualAdubacao,
      'cultura': cultura.toString().split('.').last,
      'ciclo': ciclo?.toString().split('.').last,
      'produtividadeMinima': produtividadeMinima,
      'produtividadeMaxima': produtividadeMaxima,
      'saturacaoBasesIdeal': saturacaoBasesIdeal,
      'teorMinimoMagnesio': teorMinimoMagnesio,
      'parametrosCalagem': parametrosCalagem,
      'parametrosGessagem': parametrosGessagem,
      'espacamentoEntrelinhasMin': espacamentoEntrelinhasMin,
      'espacamentoEntrelinhasMax': espacamentoEntrelinhasMax,
      'populacaoMinima': populacaoMinima,
      'populacaoMaxima': populacaoMaxima,
      'permiteParcelamentoN': permiteParcelamentoN,
      'permiteIrrigacao': permiteIrrigacao,
      'teoresCriticosMacro': teoresCriticosMacro,
      'teoresCriticosMicro': teoresCriticosMicro,
      'recomendacaoNPK': _convertNPKForFirestore(recomendacaoNPK),
      'recomendacaoMicro': recomendacaoMicro,
      'faixasTextura': faixasTextura,
      'limitesMaximosNutrientes': limitesMaximosNutrientes,
      'limitesMaximosSulco': limitesMaximosSulco,
      'fontesNutrientes': fontesNutrientes,
      'fatorAjusteDoses': fatorAjusteDoses,
      'epocasAplicacao': epocasAplicacao.map((k, v) => MapEntry(k, v.toMap())),
      'restricoesAplicacao': restricoesAplicacao,
      'observacoesManejo': observacoesManejo,
      'observacoesGerais': observacoesGerais,
      'usaFBN': usaFBN,
      'parametrosAdicionais': parametrosAdicionais, // Adicionado ao mapa
    };
  }

  CulturaParametros copyWith({
    String? id,
    String? manualAdubacao,
    TipoCultura? cultura,
    // Usar Object? para permitir definir ciclo como null explicitamente
    Object? ciclo = const _Undefined(),
    double? produtividadeMinima,
    double? produtividadeMaxima,
    double? saturacaoBasesIdeal,
    double? teorMinimoMagnesio,
    Map<String, dynamic>? parametrosCalagem,
    Map<String, dynamic>? parametrosGessagem,
    int? espacamentoEntrelinhasMin,
    int? espacamentoEntrelinhasMax,
    int? populacaoMinima,
    int? populacaoMaxima,
    bool? permiteParcelamentoN,
    bool? permiteIrrigacao,
    Map<String, Map<String, double>>? teoresCriticosMacro,
    Map<String, Map<String, double>>? teoresCriticosMicro,
    Map<String, Map<double, Map<String, double>>>? recomendacaoNPK,
    Map<String, Map<String, double>>? recomendacaoMicro,
    Map<String, double>? faixasTextura,
    Map<String, double>? limitesMaximosNutrientes,
    Map<String, double>? limitesMaximosSulco,
    Map<String, List<String>>? fontesNutrientes,
    Map<String, Map<String, double>>? fatorAjusteDoses,
    Map<String, EpocaAplicacao>? epocasAplicacao,
    List<String>? restricoesAplicacao,
    List<String>? observacoesManejo,
    List<String>? observacoesGerais,
    bool? usaFBN,
    // Usar Object? para permitir definir parametrosAdicionais como null explicitamente
    Object? parametrosAdicionais = const _Undefined(),
  }) {
    // Lógica para tratar valores nulos explicitamente passados para campos anuláveis
    final CicloCultura? finalCiclo = ciclo is _Undefined
        ? this.ciclo
        : ciclo as CicloCultura?;
    final Map<String, dynamic>? finalParametrosAdicionais = parametrosAdicionais is _Undefined
        ? this.parametrosAdicionais
        : parametrosAdicionais as Map<String, dynamic>?;


    return CulturaParametros(
      id: id ?? this.id,
      manualAdubacao: manualAdubacao ?? this.manualAdubacao,
      cultura: cultura ?? this.cultura,
      ciclo: finalCiclo, // Usa a lógica de tratamento de nulo explícito
      produtividadeMinima: produtividadeMinima ?? this.produtividadeMinima,
      produtividadeMaxima: produtividadeMaxima ?? this.produtividadeMaxima,
      saturacaoBasesIdeal: saturacaoBasesIdeal ?? this.saturacaoBasesIdeal,
      teorMinimoMagnesio: teorMinimoMagnesio ?? this.teorMinimoMagnesio,
      parametrosCalagem: parametrosCalagem ?? this.parametrosCalagem,
      parametrosGessagem: parametrosGessagem ?? this.parametrosGessagem,
      espacamentoEntrelinhasMin:
      espacamentoEntrelinhasMin ?? this.espacamentoEntrelinhasMin,
      espacamentoEntrelinhasMax:
      espacamentoEntrelinhasMax ?? this.espacamentoEntrelinhasMax,
      populacaoMinima: populacaoMinima ?? this.populacaoMinima,
      populacaoMaxima: populacaoMaxima ?? this.populacaoMaxima,
      permiteParcelamentoN: permiteParcelamentoN ?? this.permiteParcelamentoN,
      permiteIrrigacao: permiteIrrigacao ?? this.permiteIrrigacao,
      teoresCriticosMacro: teoresCriticosMacro ?? this.teoresCriticosMacro,
      teoresCriticosMicro: teoresCriticosMicro ?? this.teoresCriticosMicro,
      recomendacaoNPK: recomendacaoNPK ?? this.recomendacaoNPK,
      recomendacaoMicro: recomendacaoMicro ?? this.recomendacaoMicro,
      faixasTextura: faixasTextura ?? this.faixasTextura,
      limitesMaximosNutrientes:
      limitesMaximosNutrientes ?? this.limitesMaximosNutrientes,
      limitesMaximosSulco: limitesMaximosSulco ?? this.limitesMaximosSulco,
      fontesNutrientes: fontesNutrientes ?? this.fontesNutrientes,
      fatorAjusteDoses: fatorAjusteDoses ?? this.fatorAjusteDoses,
      epocasAplicacao: epocasAplicacao ?? this.epocasAplicacao,
      restricoesAplicacao: restricoesAplicacao ?? this.restricoesAplicacao,
      observacoesManejo: observacoesManejo ?? this.observacoesManejo,
      observacoesGerais: observacoesGerais ?? this.observacoesGerais,
      usaFBN: usaFBN ?? this.usaFBN,
      parametrosAdicionais: finalParametrosAdicionais, // Adicionado e usa a lógica de tratamento de nulo explícito
    );
  }
}

// Classe auxiliar para diferenciar valor não passado de valor null explícito no copyWith
class _Undefined {
  const _Undefined();
}
