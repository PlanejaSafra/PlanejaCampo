// lib/models/agro/recomendacao/recomendacao.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/enums.dart';

class Recomendacao {
  final String id;
  final String manualAdubacao;
  final String produtorId;
  final String propriedadeId;
  final String talhaoId;
  final DateTime dataRecomendacao;
  final DateTime dataPlantio;
  final double produtividadeEsperada;
  final String resultadoAnaliseSoloId;
  final TipoCultura tipoCultura;
  final ClasseResposta classeResposta;
  final TexturaSolo texturaSolo;
  final SistemaCultivo sistemaCultivo;
  final bool irrigado;
  final List<String> observacoes;

  Recomendacao({
    required this.id,
    required this.manualAdubacao,
    required this.produtorId,
    required this.propriedadeId,
    required this.talhaoId,
    required this.dataRecomendacao,
    required this.dataPlantio,
    required this.produtividadeEsperada,
    required this.resultadoAnaliseSoloId,
    required this.tipoCultura,
    required this.classeResposta,
    required this.texturaSolo,
    required this.sistemaCultivo,
    this.irrigado = false,
    this.observacoes = const [],
  });

  factory Recomendacao.fromMap(Map<String, dynamic> map, String id) {
    return Recomendacao(
      id: id,
      manualAdubacao: map['manualAdubacao'] ?? '',
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      talhaoId: map['talhaoId'] ?? '',
      dataRecomendacao: (map['dataRecomendacao'] as Timestamp).toDate(),
      dataPlantio: (map['dataPlantio'] as Timestamp).toDate(),
      produtividadeEsperada: (map['produtividadeEsperada']?.toDouble()) ?? 0.0,
      resultadoAnaliseSoloId: map['resultadoAnaliseSoloId'] ?? '',
      tipoCultura: TipoCultura.fromString(map['tipoCultura'] ?? ''),
      classeResposta: ClasseResposta.fromString(map['classeResposta'] ?? ''),
      texturaSolo: TexturaSolo.fromString(map['texturaSolo'] ?? ''),
      sistemaCultivo: SistemaCultivo.fromString(map['sistemaCultivo'] ?? ''),
      irrigado: map['irrigado'] ?? false,
      observacoes: List<String>.from(map['observacoes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'manualAdubacao': manualAdubacao,
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'talhaoId': talhaoId,
      'dataRecomendacao': Timestamp.fromDate(dataRecomendacao),
      'dataPlantio': Timestamp.fromDate(dataPlantio),
      'produtividadeEsperada': produtividadeEsperada,
      'resultadoAnaliseSoloId': resultadoAnaliseSoloId,
      'tipoCultura': tipoCultura.toString().split('.').last,
      'classeResposta': classeResposta.toString().split('.').last,
      'texturaSolo': texturaSolo.toString().split('.').last,
      'sistemaCultivo': sistemaCultivo.toString().split('.').last,
      'irrigado': irrigado,
      'observacoes': observacoes,
    };
  }

  Recomendacao copyWith({
    String? id,
    String? manualAdubacao,
    String? produtorId,
    String? propriedadeId,
    String? talhaoId,
    DateTime? dataRecomendacao,
    DateTime? dataPlantio,
    double? produtividadeEsperada,
    String? resultadoAnaliseSoloId,
    TipoCultura? tipoCultura,
    ClasseResposta? classeResposta,
    TexturaSolo? texturaSolo,
    SistemaCultivo? sistemaCultivo,
    bool? irrigado,
    List<String>? observacoes,
  }) {
    return Recomendacao(
      id: id ?? this.id,
      manualAdubacao: manualAdubacao ?? this.manualAdubacao,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      talhaoId: talhaoId ?? this.talhaoId,
      dataRecomendacao: dataRecomendacao ?? this.dataRecomendacao,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      produtividadeEsperada: produtividadeEsperada ?? this.produtividadeEsperada,
      resultadoAnaliseSoloId: resultadoAnaliseSoloId ?? this.resultadoAnaliseSoloId,
      tipoCultura: tipoCultura ?? this.tipoCultura,
      classeResposta: classeResposta ?? this.classeResposta,
      texturaSolo: texturaSolo ?? this.texturaSolo,
      sistemaCultivo: sistemaCultivo ?? this.sistemaCultivo,
      irrigado: irrigado ?? this.irrigado,
      observacoes: observacoes ?? List.from(this.observacoes),
    );
  }
}
