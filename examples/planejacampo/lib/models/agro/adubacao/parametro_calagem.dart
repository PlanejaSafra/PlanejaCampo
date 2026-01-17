// lib/models/agro/analise_solo/parametro_calagem.dart
import 'package:planejacampo/models/enums.dart';

class ParametroCalagem {
  final String id;
  final String manualAdubacao;
  final TipoCultura cultura;
  final double saturacaoBasesAlvo;
  final double profundidadeCalcario;
  final double prntReferencia;
  final int prazoAplicacao;
  final double? teorMinimoMagnesio;
  final double? teorMaximoAluminio;
  final double? teorMinimoCa;
  final List<String> observacoes;

  ParametroCalagem({
    required this.id,
    required this.manualAdubacao,
    required this.cultura,
    required this.saturacaoBasesAlvo,
    required this.profundidadeCalcario,
    required this.prntReferencia,
    required this.prazoAplicacao,
    this.teorMinimoMagnesio,
    this.teorMaximoAluminio,
    this.teorMinimoCa,
    this.observacoes = const [],
  });

  // Método factory para criar uma instância a partir de um mapa
  factory ParametroCalagem.fromMap(Map<String, dynamic> map, String id) {
    return ParametroCalagem(
      id: id,
      manualAdubacao: map['manualAdubacao'] ?? '',
      cultura: TipoCultura.fromString(map['cultura'] ?? ''),
      saturacaoBasesAlvo: (map['saturacaoBasesAlvo'] as num?)?.toDouble() ?? 0.0,
      profundidadeCalcario: (map['profundidadeCalcario'] as num?)?.toDouble() ?? 0.0,
      prntReferencia: (map['prntReferencia'] as num?)?.toDouble() ?? 0.0,
      prazoAplicacao: map['prazoAplicacao'] ?? 0,
      teorMinimoMagnesio: (map['teorMinimoMagnesio'] as num?)?.toDouble(),
      teorMaximoAluminio: (map['teorMaximoAluminio'] as num?)?.toDouble(),
      teorMinimoCa: (map['teorMinimoCa'] as num?)?.toDouble(),
      observacoes: List<String>.from(map['observacoes'] ?? []),
    );
  }

  // Método para converter a instância para um mapa
  Map<String, dynamic> toMap() {
    return {
      'manualAdubacao': manualAdubacao,
      'cultura': cultura.toString().split('.').last,
      'saturacaoBasesAlvo': saturacaoBasesAlvo,
      'profundidadeCalcario': profundidadeCalcario,
      'prntReferencia': prntReferencia,
      'prazoAplicacao': prazoAplicacao,
      'teorMinimoMagnesio': teorMinimoMagnesio,
      'teorMaximoAluminio': teorMaximoAluminio,
      'teorMinimoCa': teorMinimoCa,
      'observacoes': observacoes,
    };
  }

  // Método copyWith para criar uma nova instância com algumas alterações
  ParametroCalagem copyWith({
    String? id,
    String? manualAdubacao,
    TipoCultura? cultura,
    double? saturacaoBasesAlvo,
    double? profundidadeCalcario,
    double? prntReferencia,
    int? prazoAplicacao,
    double? teorMinimoMagnesio,
    double? teorMaximoAluminio,
    double? teorMinimoCa,
    List<String>? observacoes,
  }) {
    return ParametroCalagem(
      id: id ?? this.id,
      manualAdubacao: manualAdubacao ?? this.manualAdubacao,
      cultura: cultura ?? this.cultura,
      saturacaoBasesAlvo: saturacaoBasesAlvo ?? this.saturacaoBasesAlvo,
      profundidadeCalcario: profundidadeCalcario ?? this.profundidadeCalcario,
      prntReferencia: prntReferencia ?? this.prntReferencia,
      prazoAplicacao: prazoAplicacao ?? this.prazoAplicacao,
      teorMinimoMagnesio: teorMinimoMagnesio ?? this.teorMinimoMagnesio,
      teorMaximoAluminio: teorMaximoAluminio ?? this.teorMaximoAluminio,
      teorMinimoCa: teorMinimoCa ?? this.teorMinimoCa,
      observacoes: observacoes ?? List.from(this.observacoes),
    );
  }
}
