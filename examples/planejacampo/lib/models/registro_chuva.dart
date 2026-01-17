import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroChuva {
  final String id;
  final String produtorId;
  final String propriedadeId;
  final DateTime data;
  final double quantidade; // Quantidade de chuva em mm

  RegistroChuva({
    required this.id,
    required this.produtorId,
    required this.propriedadeId,
    required this.data,
    required this.quantidade,
  });

  factory RegistroChuva.fromMap(Map<String, dynamic> map, String id) {
    return RegistroChuva(
      id: id,
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      data: (map['data'] as Timestamp).toDate().toLocal(),
      quantidade: map['quantidade']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'data': Timestamp.fromDate(data.toUtc()),
      'quantidade': quantidade,
    };
  }

  RegistroChuva copyWith({
    String? id,
    String? produtorId,
    String? propriedadeId,
    DateTime? data,
    double? quantidade,
  }) {
    return RegistroChuva(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      data: data ?? this.data,
      quantidade: quantidade ?? this.quantidade,
    );
  }
}
