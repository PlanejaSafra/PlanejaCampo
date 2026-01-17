import 'package:cloud_firestore/cloud_firestore.dart';

class ProcessamentoStatus {
  final String id;
  final String produtorId;
  final String itemId;
  final String propriedadeId;
  final String deviceId;
  final DateTime inicioProcessamento;
  final DateTime ultimaAtualizacao;
  final bool emProcessamento;
  final String? ultimoErro;

  ProcessamentoStatus({
    required this.id,
    required this.produtorId,
    required this.itemId,
    required this.propriedadeId,
    required this.deviceId,
    required this.inicioProcessamento,
    required this.ultimaAtualizacao,
    required this.emProcessamento,
    this.ultimoErro,
  });

  factory ProcessamentoStatus.fromMap(Map<String, dynamic> map, String id) {
    return ProcessamentoStatus(
      id: id,
      produtorId: map['produtorId'] ?? '',
      itemId: map['itemId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      inicioProcessamento: (map['inicioProcessamento'] as Timestamp).toDate(),
      ultimaAtualizacao: (map['ultimaAtualizacao'] as Timestamp).toDate(),
      emProcessamento: map['emProcessamento'] ?? false,
      ultimoErro: map['ultimoErro'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'itemId': itemId,
      'propriedadeId': propriedadeId,
      'deviceId': deviceId,
      'inicioProcessamento': Timestamp.fromDate(inicioProcessamento),
      'ultimaAtualizacao': Timestamp.fromDate(ultimaAtualizacao),
      'emProcessamento': emProcessamento,
      'ultimoErro': ultimoErro,
    };
  }

  ProcessamentoStatus copyWith({
    String? id,
    String? produtorId,
    String? itemId,
    String? propriedadeId,
    String? deviceId,
    DateTime? inicioProcessamento,
    DateTime? ultimaAtualizacao,
    bool? emProcessamento,
    String? ultimoErro,
  }) {
    return ProcessamentoStatus(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      itemId: itemId ?? this.itemId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      deviceId: deviceId ?? this.deviceId,
      inicioProcessamento: inicioProcessamento ?? this.inicioProcessamento,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
      emProcessamento: emProcessamento ?? this.emProcessamento,
      ultimoErro: ultimoErro ?? this.ultimoErro,
    );
  }
}
