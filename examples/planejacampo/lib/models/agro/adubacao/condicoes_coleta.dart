// lib/models/agro/analise_solo/condicoes_coleta.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/enums.dart';

class CondicoesColeta {
  final DateTime dataColeta;
  final DateTime dataAnalise;
  final double umidadeSolo;
  final CondicaoClimatica condicoesClimaticas;
  final int diasUltimaChuva;
  final String culturaAnterior;
  final String? sistemaCultivo;
  final bool coletaComposta;
  final int numerosSubamostras;
  final List<String> observacoes;

  CondicoesColeta({
    required this.dataColeta,
    required this.dataAnalise,
    required this.umidadeSolo,
    required this.condicoesClimaticas,
    required this.diasUltimaChuva,
    required this.culturaAnterior,
    this.sistemaCultivo,
    required this.coletaComposta,
    required this.numerosSubamostras,
    this.observacoes = const [],
  });

  factory CondicoesColeta.fromMap(Map<String, dynamic> map) {
    return CondicoesColeta(
      dataColeta: (map['dataColeta'] as Timestamp).toDate(),
      dataAnalise: (map['dataAnalise'] as Timestamp).toDate(),
      umidadeSolo: (map['umidadeSolo'] as num?)?.toDouble() ?? 0.0,
      condicoesClimaticas: CondicaoClimatica.fromString(map['condicoesClimaticas'] ?? ''),
      diasUltimaChuva: map['diasUltimaChuva'] ?? 0,
      culturaAnterior: map['culturaAnterior'] ?? '',
      sistemaCultivo: map['sistemaCultivo'],
      coletaComposta: map['coletaComposta'] ?? false,
      numerosSubamostras: map['numerosSubamostras'] ?? 0,
      observacoes: List<String>.from(map['observacoes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dataColeta': Timestamp.fromDate(dataColeta),
      'dataAnalise': Timestamp.fromDate(dataAnalise),
      'umidadeSolo': umidadeSolo,
      'condicoesClimaticas': condicoesClimaticas.name,
      'diasUltimaChuva': diasUltimaChuva,
      'culturaAnterior': culturaAnterior,
      'sistemaCultivo': sistemaCultivo,
      'coletaComposta': coletaComposta,
      'numerosSubamostras': numerosSubamostras,
      'observacoes': observacoes,
    };
  }

  CondicoesColeta copyWith({
    DateTime? dataColeta,
    DateTime? dataAnalise,
    double? umidadeSolo,
    CondicaoClimatica? condicoesClimaticas,
    int? diasUltimaChuva,
    String? culturaAnterior,
    String? sistemaCultivo,
    bool? coletaComposta,
    int? numerosSubamostras,
    List<String>? observacoes,
  }) {
    return CondicoesColeta(
      dataColeta: dataColeta ?? this.dataColeta,
      dataAnalise: dataAnalise ?? this.dataAnalise,
      umidadeSolo: umidadeSolo ?? this.umidadeSolo,
      condicoesClimaticas: condicoesClimaticas ?? this.condicoesClimaticas,
      diasUltimaChuva: diasUltimaChuva ?? this.diasUltimaChuva,
      culturaAnterior: culturaAnterior ?? this.culturaAnterior,
      sistemaCultivo: sistemaCultivo ?? this.sistemaCultivo,
      coletaComposta: coletaComposta ?? this.coletaComposta,
      numerosSubamostras: numerosSubamostras ?? this.numerosSubamostras,
      observacoes: observacoes ?? List.from(this.observacoes),
    );
  }
}