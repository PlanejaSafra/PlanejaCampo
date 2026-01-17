import 'package:planejacampo/models/enums.dart';

class LimitesAplicacao {
  final String id;
  final String produtorId;
  final String propriedadeId;
  final double doseMaximaSulco;
  final double doseMaximaTotal;
  final Map<String, double> limitesEpoca;
  final bool permiteParcelamento;

  const LimitesAplicacao({
    required this.id,
    required this.produtorId,
    required this.propriedadeId,
    required this.doseMaximaSulco,
    required this.doseMaximaTotal,
    required this.limitesEpoca,
    this.permiteParcelamento = true,
  });

  factory LimitesAplicacao.fromMap(Map<String, dynamic> map, String id) {
    return LimitesAplicacao(
      id: id,
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      doseMaximaSulco: (map['doseMaximaSulco'] as num?)?.toDouble() ?? 0.0,
      doseMaximaTotal: (map['doseMaximaTotal'] as num?)?.toDouble() ?? 0.0,
      limitesEpoca: Map<String, double>.from(map['limitesEpoca'] ?? {}),
      permiteParcelamento: map['permiteParcelamento'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'doseMaximaSulco': doseMaximaSulco,
      'doseMaximaTotal': doseMaximaTotal,
      'limitesEpoca': limitesEpoca,
      'permiteParcelamento': permiteParcelamento,
    };
  }

  LimitesAplicacao copyWith({
    String? id,
    String? produtorId,
    String? propriedadeId,
    double? doseMaximaSulco,
    double? doseMaximaTotal,
    Map<String, double>? limitesEpoca,
    bool? permiteParcelamento,
  }) {
    return LimitesAplicacao(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      doseMaximaSulco: doseMaximaSulco ?? this.doseMaximaSulco,
      doseMaximaTotal: doseMaximaTotal ?? this.doseMaximaTotal,
      limitesEpoca: limitesEpoca ?? Map.from(this.limitesEpoca),
      permiteParcelamento: permiteParcelamento ?? this.permiteParcelamento,
    );
  }

  bool excedeLimite(String epoca, double dose) {
    final limite = limitesEpoca[epoca];
    if (limite == null) return false;
    return dose > limite;
  }

  bool excedeLimiteSulco(double dose) => dose > doseMaximaSulco;

  bool excedeLimiteTotal(double dose) => dose > doseMaximaTotal;
}
