import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroEntrega {
  final String id;
  final String produtorId;
  final String propriedadeId;
  final String atividadeId;  // Novo campo
  final DateTime dataEntrega;
  final double quantidadeCaixas;
  final double pesoTotalEntrega;
  final double pesoProdutor;
  final String? sangradorId;
  final String? pesoSangrador;
  final String? compradorId;
  final DateTime? dataPrevistaRecebimento;
  final double? valorNegociadoPorKg;
  final double? valorProdutor;
  final double? valorTotal;
  final double? quantidadeJaRecebida;

  RegistroEntrega({
    required this.id,
    required this.produtorId,
    required this.propriedadeId,
    required this.atividadeId,  // Adicionado ao construtor
    required this.dataEntrega,
    required this.quantidadeCaixas,
    required this.pesoTotalEntrega,
    required this.pesoProdutor,
    this.sangradorId,
    this.pesoSangrador,
    this.compradorId,
    this.dataPrevistaRecebimento,
    this.valorNegociadoPorKg,
    this.valorProdutor,
    this.valorTotal,
    this.quantidadeJaRecebida,
  });

  factory RegistroEntrega.fromMap(Map<String, dynamic> map, String id) {
    return RegistroEntrega(
      id: id,
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      atividadeId: map['atividadeId'] ?? '',  // Adicionado ao fromMap
      dataEntrega: (map['dataEntrega'] as Timestamp).toDate(),
      quantidadeCaixas: map['quantidadeCaixas'] ?? 0.0,
      pesoTotalEntrega: map['pesoTotalEntrega'] ?? 0.0,
      pesoProdutor: map['pesoProdutor'] ?? 0.0,
      sangradorId: map['sangradorId'],
      pesoSangrador: map['pesoSangrador'],
      compradorId: map['compradorId'],
      dataPrevistaRecebimento: (map['dataPrevistaRecebimento'] as Timestamp?)?.toDate(),
      valorNegociadoPorKg: map['valorNegociadoPorKg'],
      valorProdutor: map['valorProdutor'],
      valorTotal: map['valorTotal'],
      quantidadeJaRecebida: map['quantidadeJaRecebida'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'atividadeId': atividadeId,  // Adicionado ao toMap
      'dataEntrega': Timestamp.fromDate(dataEntrega),
      'quantidadeCaixas': quantidadeCaixas,
      'pesoTotalEntrega': pesoTotalEntrega,
      'pesoProdutor': pesoProdutor,
      'sangradorId': sangradorId,
      'pesoSangrador': pesoSangrador,
      'compradorId': compradorId,
      'dataPrevistaRecebimento': dataPrevistaRecebimento != null ? Timestamp.fromDate(dataPrevistaRecebimento!) : null,
      'valorNegociadoPorKg': valorNegociadoPorKg,
      'valorProdutor': valorProdutor,
      'valorTotal': valorTotal,
      'quantidadeJaRecebida': quantidadeJaRecebida,
    };
  }

  RegistroEntrega copyWith({
    String? id,
    String? produtorId,
    String? propriedadeId,
    String? atividadeId,  // Adicionado ao copyWith
    DateTime? dataEntrega,
    double? quantidadeCaixas,
    double? pesoTotalEntrega,
    double? pesoProdutor,
    String? sangradorId,
    String? pesoSangrador,
    String? compradorId,
    DateTime? dataPrevistaRecebimento,
    double? valorNegociadoPorKg,
    double? valorProdutor,
    double? valorTotal,
    double? quantidadeJaRecebida,
  }) {
    return RegistroEntrega(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      atividadeId: atividadeId ?? this.atividadeId,  // Adicionado ao retorno do copyWith
      dataEntrega: dataEntrega ?? this.dataEntrega,
      quantidadeCaixas: quantidadeCaixas ?? this.quantidadeCaixas,
      pesoTotalEntrega: pesoTotalEntrega ?? this.pesoTotalEntrega,
      pesoProdutor: pesoProdutor ?? this.pesoProdutor,
      sangradorId: sangradorId ?? this.sangradorId,
      pesoSangrador: pesoSangrador ?? this.pesoSangrador,
      compradorId: compradorId ?? this.compradorId,
      dataPrevistaRecebimento: dataPrevistaRecebimento ?? this.dataPrevistaRecebimento,
      valorNegociadoPorKg: valorNegociadoPorKg ?? this.valorNegociadoPorKg,
      valorProdutor: valorProdutor ?? this.valorProdutor,
      valorTotal: valorTotal ?? this.valorTotal,
      quantidadeJaRecebida: quantidadeJaRecebida ?? this.quantidadeJaRecebida,
    );
  }
}