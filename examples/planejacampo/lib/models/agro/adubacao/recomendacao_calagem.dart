// lib/models/agro/recomendacao/recomendacao_calagem.dart
class RecomendacaoCalagem {
  final String id;
  final String recomendacaoId;
  final String produtorId;
  final String propriedadeId;
  final double saturacaoBasesAtual;
  final double saturacaoBasesDesejada;
  final double ctc;
  final double prnt;
  final String tipoCalcario;
  final double quantidadeRecomendada;
  final double profundidadeIncorporacao;
  final String modoAplicacao;
  final int prazoAplicacao;
  final bool parcelamento;
  final List<String> observacoes;

  RecomendacaoCalagem({
    required this.id,
    required this.recomendacaoId,
    required this.produtorId,
    required this.propriedadeId,
    required this.saturacaoBasesAtual,
    required this.saturacaoBasesDesejada,
    required this.ctc,
    required this.prnt,
    required this.tipoCalcario,
    required this.quantidadeRecomendada,
    required this.profundidadeIncorporacao,
    required this.modoAplicacao,
    required this.prazoAplicacao,
    this.parcelamento = false,
    this.observacoes = const [],
  });

  factory RecomendacaoCalagem.fromMap(Map<String, dynamic> map, String id) {
    return RecomendacaoCalagem(
      id: id,
      recomendacaoId: map['recomendacaoId'] ?? '',
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      saturacaoBasesAtual: (map['saturacaoBasesAtual'] as num?)?.toDouble() ?? 0.0,
      saturacaoBasesDesejada: (map['saturacaoBasesDesejada'] as num?)?.toDouble() ?? 0.0,
      ctc: (map['ctc'] as num?)?.toDouble() ?? 0.0,
      prnt: (map['prnt'] as num?)?.toDouble() ?? 0.0,
      tipoCalcario: map['tipoCalcario'] ?? '',
      quantidadeRecomendada: (map['quantidadeRecomendada'] as num?)?.toDouble() ?? 0.0,
      profundidadeIncorporacao: (map['profundidadeIncorporacao'] as num?)?.toDouble() ?? 0.0,
      modoAplicacao: map['modoAplicacao'] ?? '',
      prazoAplicacao: map['prazoAplicacao'] ?? 0,
      parcelamento: map['parcelamento'] ?? false,
      observacoes: List<String>.from(map['observacoes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recomendacaoId': recomendacaoId,
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'saturacaoBasesAtual': saturacaoBasesAtual,
      'saturacaoBasesDesejada': saturacaoBasesDesejada,
      'ctc': ctc,
      'prnt': prnt,
      'tipoCalcario': tipoCalcario,
      'quantidadeRecomendada': quantidadeRecomendada,
      'profundidadeIncorporacao': profundidadeIncorporacao,
      'modoAplicacao': modoAplicacao,
      'prazoAplicacao': prazoAplicacao,
      'parcelamento': parcelamento,
      'observacoes': observacoes,
    };
  }

  RecomendacaoCalagem copyWith({
    String? id,
    String? recomendacaoId,
    String? produtorId,
    String? propriedadeId,
    double? saturacaoBasesAtual,
    double? saturacaoBasesDesejada,
    double? ctc,
    double? prnt,
    String? tipoCalcario,
    double? quantidadeRecomendada,
    double? profundidadeIncorporacao,
    String? modoAplicacao,
    int? prazoAplicacao,
    bool? parcelamento,
    List<String>? observacoes,
  }) {
    return RecomendacaoCalagem(
      id: id ?? this.id,
      recomendacaoId: recomendacaoId ?? this.recomendacaoId,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      saturacaoBasesAtual: saturacaoBasesAtual ?? this.saturacaoBasesAtual,
      saturacaoBasesDesejada: saturacaoBasesDesejada ?? this.saturacaoBasesDesejada,
      ctc: ctc ?? this.ctc,
      prnt: prnt ?? this.prnt,
      tipoCalcario: tipoCalcario ?? this.tipoCalcario,
      quantidadeRecomendada: quantidadeRecomendada ?? this.quantidadeRecomendada,
      profundidadeIncorporacao: profundidadeIncorporacao ?? this.profundidadeIncorporacao,
      modoAplicacao: modoAplicacao ?? this.modoAplicacao,
      prazoAplicacao: prazoAplicacao ?? this.prazoAplicacao,
      parcelamento: parcelamento ?? this.parcelamento,
      observacoes: observacoes ?? List.from(this.observacoes),
    );
  }
}