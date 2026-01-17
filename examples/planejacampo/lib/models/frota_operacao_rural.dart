class FrotaOperacaoRural {
  final String id;
  final String operacaoRuralId;
  final String frotaId;
  final String atividadeId;
  final String produtorId;
  final double horasUtilizadas;
  final double horimetroInicial;
  final double horimetroFinal;

  FrotaOperacaoRural({
    required this.id,
    required this.operacaoRuralId,
    required this.frotaId,
    required this.atividadeId,
    required this.produtorId,
    required this.horasUtilizadas,
    required this.horimetroInicial,
    required this.horimetroFinal,
  });

  factory FrotaOperacaoRural.fromMap(Map<String, dynamic> map, String id) {
    return FrotaOperacaoRural(
      id: id,
      operacaoRuralId: map['operacaoRuralId'] ?? '',
      frotaId: map['frotaId'] ?? '',
      atividadeId: map['atividadeId'] ?? '',
      produtorId: map['produtorId'] ?? '',
      horasUtilizadas: map['horasUtilizadas']?.toDouble() ?? 0.0,
      horimetroInicial: map['horimetroInicial']?.toDouble() ?? 0.0,
      horimetroFinal: map['horimetroFinal']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'operacaoRuralId': operacaoRuralId,
      'frotaId': frotaId,
      'atividadeId': atividadeId,
      'produtorId': produtorId,
      'horasUtilizadas': horasUtilizadas,
      'horimetroInicial': horimetroInicial,
      'horimetroFinal': horimetroFinal,
    };
  }

  FrotaOperacaoRural copyWith({
    String? id,
    String? operacaoRuralId,
    String? frotaId,
    String? atividadeId,
    String? produtorId,
    double? horasUtilizadas,
    double? horimetroInicial,
    double? horimetroFinal,
  }) {
    return FrotaOperacaoRural(
      id: id ?? this.id,
      operacaoRuralId: operacaoRuralId ?? this.operacaoRuralId,
      frotaId: frotaId ?? this.frotaId,
      atividadeId: atividadeId ?? this.atividadeId,
      produtorId: produtorId ?? this.produtorId,
      horasUtilizadas: horasUtilizadas ?? this.horasUtilizadas,
      horimetroInicial: horimetroInicial ?? this.horimetroInicial,
      horimetroFinal: horimetroFinal ?? this.horimetroFinal,
    );
  }
}
