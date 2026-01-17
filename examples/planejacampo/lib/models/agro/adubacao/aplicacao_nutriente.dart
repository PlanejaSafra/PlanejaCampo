// lib/models/agro/recomendacao/aplicacao_nutriente.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AplicacaoNutriente {
  final String id;
  final String recomendacaoNutrienteId;
  final String produtorId;
  final String propriedadeId;
  final String fase;
  final String modoAplicacao;
  final double dosePlanejada;
  final double percentualDose;
  final int? diasAposPlantio;
  final DateTime? dataPrevisao;
  final String? estagioCultura;
  final List<String> observacoes;

  AplicacaoNutriente({
    required this.id,
    required this.recomendacaoNutrienteId,
    required this.produtorId,
    required this.propriedadeId,
    required this.fase,
    required this.modoAplicacao,
    required this.dosePlanejada,
    required this.percentualDose,
    this.diasAposPlantio,
    this.dataPrevisao,
    this.estagioCultura,
    this.observacoes = const [],
  });

  factory AplicacaoNutriente.fromMap(Map<String, dynamic> map, String id) {
    return AplicacaoNutriente(
      id: id,
      recomendacaoNutrienteId: map['recomendacaoNutrienteId'] ?? '',
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      fase: map['fase'] ?? '',
      modoAplicacao: map['modoAplicacao'] ?? '',
      dosePlanejada: (map['dosePlanejada'] as num?)?.toDouble() ?? 0.0,
      percentualDose: (map['percentualDose'] as num?)?.toDouble() ?? 0.0,
      diasAposPlantio: map['diasAposPlantio'],
      dataPrevisao: map['dataPrevisao'] != null ? (map['dataPrevisao'] as Timestamp).toDate() : null,
      estagioCultura: map['estagioCultura'],
      observacoes: List<String>.from(map['observacoes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recomendacaoNutrienteId': recomendacaoNutrienteId,
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'fase': fase,
      'modoAplicacao': modoAplicacao,
      'dosePlanejada': dosePlanejada,
      'percentualDose': percentualDose,
      'diasAposPlantio': diasAposPlantio,
      'dataPrevisao': dataPrevisao != null ? Timestamp.fromDate(dataPrevisao!) : null,
      'estagioCultura': estagioCultura,
      'observacoes': observacoes,
    };
  }

  AplicacaoNutriente copyWith({
    String? id,
    String? recomendacaoNutrienteId,
    String? produtorId,
    String? propriedadeId,
    String? fase,
    String? modoAplicacao,
    double? dosePlanejada,
    double? percentualDose,
    int? diasAposPlantio,
    DateTime? dataPrevisao,
    String? estagioCultura,
    List<String>? observacoes,
  }) {
    return AplicacaoNutriente(
      id: id ?? this.id,
      recomendacaoNutrienteId: recomendacaoNutrienteId ?? this.recomendacaoNutrienteId,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      fase: fase ?? this.fase,
      modoAplicacao: modoAplicacao ?? this.modoAplicacao,
      dosePlanejada: dosePlanejada ?? this.dosePlanejada,
      percentualDose: percentualDose ?? this.percentualDose,
      diasAposPlantio: diasAposPlantio ?? this.diasAposPlantio,
      dataPrevisao: dataPrevisao ?? this.dataPrevisao,
      estagioCultura: estagioCultura ?? this.estagioCultura,
      observacoes: observacoes ?? List.from(this.observacoes),
    );
  }
}