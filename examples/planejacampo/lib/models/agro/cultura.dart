// lib/models/agro/cultura.dart

import 'package:planejacampo/models/enums.dart';

class Cultura {
  final String id;
  final String produtorId;
  final String propriedadeId;
  final String talhaoId;
  final TipoCultura tipo;
  final EpocaPlantio epocaPlantio;
  final SistemaCultivo sistemaCultivo;
  final double produtividadeEsperada;
  final bool permiteIrrigacao;
  final DateTime? dataPlantio;
  final DateTime? dataColheitaPrevista;
  final String? culturaAnterior;
  final String? proximaCultura;
  final List<String> observacoes;

  Cultura({
    required this.id,
    required this.produtorId,
    required this.propriedadeId,
    required this.talhaoId,
    required this.tipo,
    required this.epocaPlantio,
    required this.sistemaCultivo,
    required this.produtividadeEsperada,
    this.permiteIrrigacao = false,
    this.dataPlantio,
    this.dataColheitaPrevista,
    this.culturaAnterior,
    this.proximaCultura,
    this.observacoes = const [],
  });

  factory Cultura.fromMap(Map<String, dynamic> map, String id) {
    return Cultura(
      id: id,
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      talhaoId: map['talhaoId'] ?? '',
      tipo: TipoCultura.fromString(map['tipo'] ?? ''),
      epocaPlantio: EpocaPlantio.fromString(map['epocaPlantio'] ?? ''),
      sistemaCultivo: SistemaCultivo.fromString(map['sistemaCultivo'] ?? ''),
      produtividadeEsperada: (map['produtividadeEsperada'] as num?)?.toDouble() ?? 0.0,
      permiteIrrigacao: map['permiteIrrigacao'] ?? false,
      dataPlantio: map['dataPlantio'] != null ? DateTime.parse(map['dataPlantio']) : null,
      dataColheitaPrevista: map['dataColheitaPrevista'] != null ?
      DateTime.parse(map['dataColheitaPrevista']) : null,
      culturaAnterior: map['culturaAnterior'],
      proximaCultura: map['proximaCultura'],
      observacoes: List<String>.from(map['observacoes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'talhaoId': talhaoId,
      'tipo': tipo.toString().split('.').last,
      'epocaPlantio': epocaPlantio.toString().split('.').last,
      'sistemaCultivo': sistemaCultivo.toString().split('.').last,
      'produtividadeEsperada': produtividadeEsperada,
      'permiteIrrigacao': permiteIrrigacao,
      'dataPlantio': dataPlantio?.toIso8601String(),
      'dataColheitaPrevista': dataColheitaPrevista?.toIso8601String(),
      'culturaAnterior': culturaAnterior,
      'proximaCultura': proximaCultura,
      'observacoes': observacoes,
    };
  }

  Cultura copyWith({
    String? id,
    String? produtorId,
    String? propriedadeId,
    String? talhaoId,
    TipoCultura? tipo,
    EpocaPlantio? epocaPlantio,
    SistemaCultivo? sistemaCultivo,
    double? produtividadeEsperada,
    bool? permiteIrrigacao,
    DateTime? dataPlantio,
    DateTime? dataColheitaPrevista,
    String? culturaAnterior,
    String? proximaCultura,
    List<String>? observacoes,
  }) {
    return Cultura(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      talhaoId: talhaoId ?? this.talhaoId,
      tipo: tipo ?? this.tipo,
      epocaPlantio: epocaPlantio ?? this.epocaPlantio,
      sistemaCultivo: sistemaCultivo ?? this.sistemaCultivo,
      produtividadeEsperada: produtividadeEsperada ?? this.produtividadeEsperada,
      permiteIrrigacao: permiteIrrigacao ?? this.permiteIrrigacao,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      dataColheitaPrevista: dataColheitaPrevista ?? this.dataColheitaPrevista,
      culturaAnterior: culturaAnterior ?? this.culturaAnterior,
      proximaCultura: proximaCultura ?? this.proximaCultura,
      observacoes: observacoes ?? List.from(this.observacoes),
    );
  }
}