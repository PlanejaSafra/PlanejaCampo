// lib/models/agro/adubacao/faixa_interpretacao_solo.dart

import 'package:planejacampo/models/enums.dart';

/// Representa uma faixa de interpretação para um nutriente específico em uma cultura.
class FaixaInterpretacaoSolo {
  /// Identificador único da faixa.
  final String id;

  /// Manual de adubação associado à faixa.
  final String manualAdubacao;

  /// Cultura associada à faixa.
  final TipoCultura cultura;

  /// Nutriente associado à faixa.
  final String nutriente;

  /// Limite inferior do nutriente.
  final double limiteInferior;

  /// Limite superior do nutriente.
  final double limiteSuperior;

  /// Unidade de medida do nutriente.
  final String unidade;

  /// Valor de referência para o nutriente.
  final double valorReferencia;

  /// Construtor da classe [FaixaInterpretacaoSolo].
  FaixaInterpretacaoSolo({
    required this.id,
    required this.manualAdubacao,
    required this.cultura,
    required this.nutriente,
    required this.limiteInferior,
    required this.limiteSuperior,
    required this.unidade,
    required this.valorReferencia,
  });

  /// Cria uma instância de [FaixaInterpretacaoSolo] a partir de um mapa.
  factory FaixaInterpretacaoSolo.fromMap(Map<String, dynamic> map, String id) {
    return FaixaInterpretacaoSolo(
      id: id,
      manualAdubacao: map['manualAdubacao'] ?? '',
      cultura: TipoCultura.fromString(map['cultura'] ?? ''),
      nutriente: map['nutriente'] ?? '',
      limiteInferior: (map['limiteInferior'] as num?)?.toDouble() ?? 0.0,
      limiteSuperior: (map['limiteSuperior'] as num?)?.toDouble() ?? 0.0,
      unidade: map['unidade'] ?? '',
      valorReferencia: (map['valorReferencia'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converte a instância de [FaixaInterpretacaoSolo] para um mapa.
  Map<String, dynamic> toMap() {
    return {
      'manualAdubacao': manualAdubacao,
      'cultura': cultura.toString().split('.').last,
      'nutriente': nutriente,
      'limiteInferior': limiteInferior,
      'limiteSuperior': limiteSuperior,
      'unidade': unidade,
      'valorReferencia': valorReferencia,
    };
  }

  /// Retorna a interpretação do valor com base nos limites definidos.
  ///
  /// - Retorna `'Baixo'` se o valor estiver abaixo do limite inferior.
  /// - Retorna `'Médio'` se o valor estiver dentro dos limites.
  /// - Retorna `'Alto'` se o valor estiver acima do limite superior.
  String getInterpretacao(double valor) {
    if (valor < limiteInferior) return 'Baixo';
    if (valor <= limiteSuperior) return 'Médio';
    return 'Alto';
  }

  /// Verifica se o valor está dentro da faixa definida.
  bool isValorDentroFaixa(double valor) {
    return valor >= limiteInferior && valor <= limiteSuperior;
  }

  /// Cria uma cópia da instância atual com possíveis alterações.
  FaixaInterpretacaoSolo copyWith({
    String? id,
    String? manualAdubacao,
    TipoCultura? cultura,
    String? nutriente,
    double? limiteInferior,
    double? limiteSuperior,
    String? unidade,
    double? valorReferencia,
  }) {
    return FaixaInterpretacaoSolo(
      id: id ?? this.id,
      manualAdubacao: manualAdubacao ?? this.manualAdubacao,
      cultura: cultura ?? this.cultura,
      nutriente: nutriente ?? this.nutriente,
      limiteInferior: limiteInferior ?? this.limiteInferior,
      limiteSuperior: limiteSuperior ?? this.limiteSuperior,
      unidade: unidade ?? this.unidade,
      valorReferencia: valorReferencia ?? this.valorReferencia,
    );
  }

  @override
  String toString() {
    return 'FaixaInterpretacaoSolo{id: $id, manualAdubacao: $manualAdubacao, cultura: $cultura, nutriente: $nutriente, limiteInferior: $limiteInferior, limiteSuperior: $limiteSuperior, unidade: $unidade, valorReferencia: $valorReferencia}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FaixaInterpretacaoSolo &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              manualAdubacao == other.manualAdubacao &&
              cultura == other.cultura &&
              nutriente == other.nutriente &&
              limiteInferior == other.limiteInferior &&
              limiteSuperior == other.limiteSuperior &&
              unidade == other.unidade &&
              valorReferencia == other.valorReferencia;

  @override
  int get hashCode =>
      id.hashCode ^
      manualAdubacao.hashCode ^
      cultura.hashCode ^
      nutriente.hashCode ^
      limiteInferior.hashCode ^
      limiteSuperior.hashCode ^
      unidade.hashCode ^
      valorReferencia.hashCode;
}
