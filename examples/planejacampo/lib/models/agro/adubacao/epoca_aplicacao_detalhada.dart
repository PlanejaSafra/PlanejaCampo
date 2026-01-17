class EpocaAplicacaoDetalhada {
  final int dias; // Dias após plantio/emergência/corte
  final String descricao; // Ex: "Plantio", "Cobertura V4", "Quebra-lombo"
  final double percentual; // 0-100% da dose total do nutriente para esta época
  final double? limiteMaximoAplicacao; // Opcional: max kg/ha nesta aplicação específica (ex: limite K2O no sulco)
  final bool condicionalIrrigacao; // Opcional: esta época só se aplica se irrigado?
  final bool condicionalSequeiro; // Opcional: esta época só se aplica se sequeiro?
  final String? condicionalTextura; // Opcional: só se aplica a esta textura ('ARENOSO', 'ARGILOSO', etc.)

  EpocaAplicacaoDetalhada({
    required this.dias,
    required this.descricao,
    required this.percentual,
    this.limiteMaximoAplicacao,
    this.condicionalIrrigacao = false, // Padrão: aplica em ambos
    this.condicionalSequeiro = false,  // Padrão: aplica em ambos
    this.condicionalTextura,
  });

  // Métodos fromMap/toMap se for salvar no Firestore diretamente
  Map<String, dynamic> toMap() {
    return {
      'dias': dias,
      'descricao': descricao,
      'percentual': percentual,
      'limiteMaximoAplicacao': limiteMaximoAplicacao,
      'condicionalIrrigacao': condicionalIrrigacao,
      'condicionalSequeiro': condicionalSequeiro,
      'condicionalTextura': condicionalTextura,
    };
  }

  factory EpocaAplicacaoDetalhada.fromMap(Map<String, dynamic> map) {
    return EpocaAplicacaoDetalhada(
      dias: map['dias'] as int,
      descricao: map['descricao'] as String,
      percentual: (map['percentual'] as num).toDouble(),
      limiteMaximoAplicacao: map['limiteMaximoAplicacao'] != null ? (map['limiteMaximoAplicacao'] as num).toDouble() : null,
      condicionalIrrigacao: map['condicionalIrrigacao'] as bool? ?? false,
      condicionalSequeiro: map['condicionalSequeiro'] as bool? ?? false,
      condicionalTextura: map['condicionalTextura'] as String?,
    );
  }
}