// lib/models/agro/recomendacao/recomendacao_nutriente.dart
class RecomendacaoNutriente {
  final String id;
  final String recomendacaoId;
  final String produtorId;
  final String propriedadeId;
  final String nutriente;
  final double teor;
  final String interpretacao;
  final double doseRecomendada;
  final String? fonte;
  final double? eficiencia;
  final List<String> restricoes;
  final List<String> observacoes;

  RecomendacaoNutriente({
    required this.id,
    required this.recomendacaoId,
    required this.produtorId,
    required this.propriedadeId,
    required this.nutriente,
    required this.teor,
    required this.interpretacao,
    required this.doseRecomendada,
    this.fonte,
    this.eficiencia,
    this.restricoes = const [],
    this.observacoes = const [],
  });

  factory RecomendacaoNutriente.fromMap(Map<String, dynamic> map, String id) {
    return RecomendacaoNutriente(
      id: id,
      recomendacaoId: map['recomendacaoId'] ?? '',
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      nutriente: map['nutriente'] ?? '',
      teor: (map['teor'] as num?)?.toDouble() ?? 0.0,
      interpretacao: map['interpretacao'] ?? '',
      doseRecomendada: (map['doseRecomendada'] as num?)?.toDouble() ?? 0.0,
      fonte: map['fonte'],
      eficiencia: (map['eficiencia'] as num?)?.toDouble(),
      restricoes: List<String>.from(map['restricoes'] ?? []),
      observacoes: List<String>.from(map['observacoes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recomendacaoId': recomendacaoId,
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'nutriente': nutriente,
      'teor': teor,
      'interpretacao': interpretacao,
      'doseRecomendada': doseRecomendada,
      'fonte': fonte,
      'eficiencia': eficiencia,
      'restricoes': restricoes,
      'observacoes': observacoes,
    };
  }

  RecomendacaoNutriente copyWith({
    String? id,
    String? recomendacaoId,
    String? produtorId,
    String? propriedadeId,
    String? nutriente,
    double? teor,
    String? interpretacao,
    double? doseRecomendada,
    String? fonte,
    double? eficiencia,
    List<String>? restricoes,
    List<String>? observacoes,
  }) {
    return RecomendacaoNutriente(
      id: id ?? this.id,
      recomendacaoId: recomendacaoId ?? this.recomendacaoId,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      nutriente: nutriente ?? this.nutriente,
      teor: teor ?? this.teor,
      interpretacao: interpretacao ?? this.interpretacao,
      doseRecomendada: doseRecomendada ?? this.doseRecomendada,
      fonte: fonte ?? this.fonte,
      eficiencia: eficiencia ?? this.eficiencia,
      restricoes: restricoes ?? List.from(this.restricoes),
      observacoes: observacoes ?? List.from(this.observacoes),
    );
  }
}