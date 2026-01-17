import 'package:planejacampo/models/tipo_operacao_rural.dart';

class OperacaoRural {
  final String id;
  final String atividadeId;
  final String produtorId;
  final String propriedadeId;
  final String fase;
  final String tipoOperacaoRuralId; // Armazena apenas o ID
  final DateTime dataInicio;
  final DateTime? dataFim;
  final List<String>? talhoes;
  final double? area;
  final String? descricao;

  OperacaoRural({
    required this.id,
    required this.atividadeId,
    required this.produtorId,
    required this.propriedadeId,
    required this.fase,
    required this.tipoOperacaoRuralId,
    required this.dataInicio,
    this.dataFim,
    this.talhoes,
    this.area,
    this.descricao,
  });

  factory OperacaoRural.fromMap(Map<String, dynamic> map, String id) {
    return OperacaoRural(
      id: id,
      atividadeId: map['atividadeId'] ?? '',
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      fase: map['fase'] ?? '',
      tipoOperacaoRuralId: map['tipoOperacaoRuralId'] ?? '',
      dataInicio: DateTime.parse(map['dataInicio']),
      dataFim: map['dataFim'] != null ? DateTime.parse(map['dataFim']) : null,
      talhoes: map['talhoes'] != null ? List<String>.from(map['talhoes']) : null,
      area: map['area']?.toDouble(),
      descricao: map['descricao'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'atividadeId': atividadeId,
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'fase': fase,
      'tipoOperacaoRuralId': tipoOperacaoRuralId, // Armazena apenas o ID
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim?.toIso8601String(),
      'talhoes': talhoes,
      'area': area,
      'descricao': descricao,
    };
  }

  OperacaoRural copyWith({
    String? id,
    String? atividadeId,
    String? produtorId,
    String? propriedadeId,
    String? fase,
    String? tipoOperacaoRuralId,
    DateTime? dataInicio,
    DateTime? dataFim,
    List<String>? talhoes,
    double? area,
    String? descricao,
  }) {
    return OperacaoRural(
      id: id ?? this.id,
      atividadeId: atividadeId ?? this.atividadeId,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      fase: fase ?? this.fase,
      tipoOperacaoRuralId: tipoOperacaoRuralId ?? this.tipoOperacaoRuralId,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      talhoes: talhoes ?? this.talhoes,
      area: area ?? this.area,
      descricao: descricao ?? this.descricao,
    );
  }
}
