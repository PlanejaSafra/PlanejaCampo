// lib/models/agro/adubacao/resultado_validacao.dart

class ResultadoValidacao {
  final bool valido;
  final List<String> erros;
  final List<String> avisos;
  final Map<String, dynamic> detalhes;

  ResultadoValidacao({
    required this.valido,
    required this.erros,
    required this.avisos,
    required this.detalhes,
  });

  /// Cria uma instância de ResultadoValidacao a partir de um Map
  factory ResultadoValidacao.fromMap(Map<String, dynamic> map) {
    return ResultadoValidacao(
      valido: map['valido'] ?? false,
      erros: List<String>.from(map['erros'] ?? []),
      avisos: List<String>.from(map['avisos'] ?? []),
      detalhes: Map<String, dynamic>.from(map['detalhes'] ?? {}),
    );
  }

  /// Converte a instância para um Map
  Map<String, dynamic> toMap() {
    return {
      'valido': valido,
      'erros': erros,
      'avisos': avisos,
      'detalhes': detalhes,
    };
  }
}
