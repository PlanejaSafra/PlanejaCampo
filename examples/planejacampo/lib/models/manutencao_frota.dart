class ManutencaoFrota {
  final String id;
  final String produtorId;
  final String frotaId;
  final DateTime data;
  final double? horimetro;
  final String? observacoes;

  ManutencaoFrota({
    required this.id,
    required this.produtorId,
    required this.frotaId,
    required this.data,
    this.horimetro,
    this.observacoes,
  });

  factory ManutencaoFrota.fromMap(Map<String, dynamic> map, String id) {
    return ManutencaoFrota(
      id: id,
      produtorId: map['produtorId'] ?? '',
      frotaId: map['frotaId'] ?? '',
      data: DateTime.parse(map['data']),
      horimetro: map['horimetro']?.toDouble(),
      observacoes: map['observacoes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'frotaId': frotaId,
      'data': data.toIso8601String(),
      'horimetro': horimetro,
      'observacoes': observacoes,
    };
  }

  ManutencaoFrota copyWith({
    String? id,
    String? produtorId,
    String? frotaId,
    DateTime? data,
    double? horimetro,
    String? observacoes,
  }) {
    return ManutencaoFrota(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      frotaId: frotaId ?? this.frotaId,
      data: data ?? this.data,
      horimetro: horimetro ?? this.horimetro,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}
