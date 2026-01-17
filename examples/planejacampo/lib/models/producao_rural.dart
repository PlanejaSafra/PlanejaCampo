import 'package:cloud_firestore/cloud_firestore.dart';

class ProducaoRural {
  final String id;
  final String produtorId;
  final String propriedadeId;
  final String atividadeId;  // vínculo com atividade rural
  final String? operacaoId;  // vínculo opcional com operação específica
  final String itemId;       // item produzido
  final double quantidade;
  final String unidadeMedida;
  final DateTime data;
  final DateTime timestamp;
  final double valorUnitario; // valor estimado/realizado unitário
  final bool geraReceita;     // se deve gerar lançamento de receita
  final String? safra;        // identificação da safra
  final String? ciclo;        // ciclo produtivo
  final List<String>? talhoes; // talhões envolvidos
  final String? descricao;
  final bool ativo;

  ProducaoRural({
    required this.id,
    required this.produtorId,
    required this.propriedadeId,
    required this.atividadeId,
    this.operacaoId,
    required this.itemId,
    required this.quantidade,
    required this.unidadeMedida,
    required this.data,
    required this.timestamp,
    required this.valorUnitario,
    required this.geraReceita,
    this.safra,
    this.ciclo,
    this.talhoes,
    this.descricao,
    required this.ativo,
  });

  factory ProducaoRural.fromMap(Map<String, dynamic> map, String documentId) {
    return ProducaoRural(
      id: documentId,
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      atividadeId: map['atividadeId'] ?? '',
      operacaoId: map['operacaoId'],
      itemId: map['itemId'] ?? '',
      quantidade: (map['quantidade'] ?? 0.0).toDouble(),
      unidadeMedida: map['unidadeMedida'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      valorUnitario: (map['valorUnitario'] ?? 0.0).toDouble(),
      geraReceita: map['geraReceita'] ?? true,
      safra: map['safra'],
      ciclo: map['ciclo'],
      talhoes: map['talhoes'] != null ? List<String>.from(map['talhoes']) : null,
      descricao: map['descricao'],
      ativo: map['ativo'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'atividadeId': atividadeId,
      'operacaoId': operacaoId,
      'itemId': itemId,
      'quantidade': quantidade,
      'unidadeMedida': unidadeMedida,
      'data': Timestamp.fromDate(data),
      'timestamp': Timestamp.fromDate(timestamp),
      'valorUnitario': valorUnitario,
      'geraReceita': geraReceita,
      'safra': safra,
      'ciclo': ciclo,
      'talhoes': talhoes,
      'descricao': descricao,
      'ativo': ativo,
    };
  }

  ProducaoRural copyWith({
    String? id,
    String? produtorId,
    String? propriedadeId,
    String? atividadeId,
    String? operacaoId,
    String? itemId,
    double? quantidade,
    String? unidadeMedida,
    DateTime? data,
    DateTime? timestamp,
    double? valorUnitario,
    bool? geraReceita,
    String? safra,
    String? ciclo,
    List<String>? talhoes,
    String? descricao,
    bool? ativo,
  }) {
    return ProducaoRural(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      atividadeId: atividadeId ?? this.atividadeId,
      operacaoId: operacaoId ?? this.operacaoId,
      itemId: itemId ?? this.itemId,
      quantidade: quantidade ?? this.quantidade,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      geraReceita: geraReceita ?? this.geraReceita,
      safra: safra ?? this.safra,
      ciclo: ciclo ?? this.ciclo,
      talhoes: talhoes ?? this.talhoes,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
    );
  }
}