// lib/models/agro/adubacao/config_calculo_recomendacao.dart

class ConfigCalculoRecomendacao {
  final bool considerarCulturaAnterior;
  final bool ajustarIrrigacao;
  final bool permitirParcelamento;
  final double toleranciaAjuste;

  ConfigCalculoRecomendacao({
    required this.considerarCulturaAnterior,
    required this.ajustarIrrigacao,
    required this.permitirParcelamento,
    required this.toleranciaAjuste,
  });

  /// Cria uma instância de ConfigCalculoRecomendacao a partir de um Map
  factory ConfigCalculoRecomendacao.fromMap(Map<String, dynamic> map) {
    return ConfigCalculoRecomendacao(
      considerarCulturaAnterior: map['considerarCulturaAnterior'] ?? false,
      ajustarIrrigacao: map['ajustarIrrigacao'] ?? false,
      permitirParcelamento: map['permitirParcelamento'] ?? false,
      toleranciaAjuste: map['toleranciaAjuste']?.toDouble() ?? 0.0,
    );
  }

  /// Converte a instância para um Map
  Map<String, dynamic> toMap() {
    return {
      'considerarCulturaAnterior': considerarCulturaAnterior,
      'ajustarIrrigacao': ajustarIrrigacao,
      'permitirParcelamento': permitirParcelamento,
      'toleranciaAjuste': toleranciaAjuste,
    };
  }
}
