// lib/models/agro/recomendacao/recomendacao_gessagem.dart
class RecomendacaoGessagem {
  final String id;
  final String recomendacaoId;
  final String produtorId;
  final String propriedadeId;
  final double teorSulfato;
  final double saturacaoAluminio;
  final double calcioSubsolo;
  final double doseRecomendada;
  final String modoAplicacao;
  final int profundidadeAvaliada;
  final bool parcelamento;
  final List<String> observacoes;

  RecomendacaoGessagem({
    required this.id,
    required this.recomendacaoId,
    required this.produtorId,
    required this.propriedadeId,
    required this.teorSulfato,
    required this.saturacaoAluminio,
    required this.calcioSubsolo,
    required this.doseRecomendada,
    required this.modoAplicacao,
    required this.profundidadeAvaliada,
    this.parcelamento = false,
    this.observacoes = const [],
  });

  factory RecomendacaoGessagem.fromMap(Map<String, dynamic> map, String id) {
    return RecomendacaoGessagem(
      id: id,
      recomendacaoId: map['recomendacaoId'] ?? '',
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      teorSulfato: (map['teorSulfato'] as num?)?.toDouble() ?? 0.0,
      saturacaoAluminio: (map['saturacaoAluminio'] as num?)?.toDouble() ?? 0.0,
      calcioSubsolo: (map['calcioSubsolo'] as num?)?.toDouble() ?? 0.0,
      doseRecomendada: (map['doseRecomendada'] as num?)?.toDouble() ?? 0.0,
      modoAplicacao: map['modoAplicacao'] ?? '',
      profundidadeAvaliada: map['profundidadeAvaliada'] ?? 0,
      parcelamento: map['parcelamento'] ?? false,
      observacoes: List<String>.from(map['observacoes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recomendacaoId': recomendacaoId,
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'teorSulfato': teorSulfato,
      'saturacaoAluminio': saturacaoAluminio,
      'calcioSubsolo': calcioSubsolo,
      'doseRecomendada': doseRecomendada,
      'modoAplicacao': modoAplicacao,
      'profundidadeAvaliada': profundidadeAvaliada,
      'parcelamento': parcelamento,
      'observacoes': observacoes,
    };
  }

  RecomendacaoGessagem copyWith({
    String? id,
    String? recomendacaoId,
    String? produtorId,
    String? propriedadeId,
    double? teorSulfato,
    double? saturacaoAluminio,
    double? calcioSubsolo,
    double? doseRecomendada,
    String? modoAplicacao,
    int? profundidadeAvaliada,
    bool? parcelamento,
    List<String>? observacoes,
  }) {
    return RecomendacaoGessagem(
      id: id ?? this.id,
      recomendacaoId: recomendacaoId ?? this.recomendacaoId,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      teorSulfato: teorSulfato ?? this.teorSulfato,
      saturacaoAluminio: saturacaoAluminio ?? this.saturacaoAluminio,
      calcioSubsolo: calcioSubsolo ?? this.calcioSubsolo,
      doseRecomendada: doseRecomendada ?? this.doseRecomendada,
      modoAplicacao: modoAplicacao ?? this.modoAplicacao,
      profundidadeAvaliada: profundidadeAvaliada ?? this.profundidadeAvaliada,
      parcelamento: parcelamento ?? this.parcelamento,
      observacoes: observacoes ?? List.from(this.observacoes),
    );
  }
}