import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroColeta {
  final String id;
  final String produtorId;
  final String propriedadeId;
  final String atividadeId;  // Novo campo
  final DateTime dataColeta;
  final double? quantidadeCaixa;
  final double? pesoMedioCaixa;
  final double? pesoTotal;

  RegistroColeta({
    required this.id,
    required this.produtorId,
    required this.propriedadeId,
    required this.atividadeId,  // Adicionado ao construtor
    required this.dataColeta,
    required this.quantidadeCaixa,
    required this.pesoMedioCaixa,
    required this.pesoTotal,
  });

  factory RegistroColeta.fromMap(Map<String, dynamic> map, String id) {
    return RegistroColeta(
      id: id,
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      atividadeId: map['atividadeId'] ?? '',  // Adicionado ao fromMap
      dataColeta: (map['dataColeta'] as Timestamp).toDate(),
      quantidadeCaixa: map['quantidadeCaixa'],
      pesoMedioCaixa: map['pesoMedioCaixa'],
      pesoTotal: map['pesoTotal'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'atividadeId': atividadeId,  // Adicionado ao toMap
      'dataColeta': Timestamp.fromDate(dataColeta),
      'quantidadeCaixa': quantidadeCaixa,
      'pesoMedioCaixa': pesoMedioCaixa,
      'pesoTotal': pesoTotal,
    };
  }

  RegistroColeta copyWith({
    String? id,
    String? produtorId,
    String? propriedadeId,
    String? atividadeId,  // Adicionado ao copyWith
    DateTime? dataColeta,
    double? quantidadeCaixa,
    double? pesoMedioCaixa,
    double? pesoTotal,
  }) {
    return RegistroColeta(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      atividadeId: atividadeId ?? this.atividadeId,  // Adicionado ao retorno do copyWith
      dataColeta: dataColeta ?? this.dataColeta,
      quantidadeCaixa: quantidadeCaixa ?? this.quantidadeCaixa,
      pesoMedioCaixa: pesoMedioCaixa ?? this.pesoMedioCaixa,
      pesoTotal: pesoTotal ?? this.pesoTotal,
    );
  }
}