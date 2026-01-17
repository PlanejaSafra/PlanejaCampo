import 'package:cloud_firestore/cloud_firestore.dart';

class Compra {
  final String id;
  final String produtorId;
  final String fornecedorId;
  final DateTime data;
  final double valorTotal;

  Compra({
    required this.id,
    required this.produtorId,
    required this.fornecedorId,
    required this.data,
    required this.valorTotal,
  });

  factory Compra.fromMap(Map<String, dynamic> map, String id) {
    return Compra(
      id: id,
      produtorId: map['produtorId'] ?? '',
      fornecedorId: map['fornecedorId'] ?? '',
      data: (map['data'] as Timestamp).toDate().toLocal(), // Converte Timestamp para DateTime e ajusta para o horário local
      valorTotal: map['valorTotal'] ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fornecedorId': fornecedorId,
      'produtorId': produtorId,
      'data': Timestamp.fromDate(data.toUtc()), // Converte DateTime para Timestamp e ajusta para UTC
      'valorTotal': valorTotal,
    };
  }

  Compra copyWith({
    String? id,
    String? produtorId,
    String? fornecedorId,
    DateTime? data,
    double? valorTotal,
  }) {
    return Compra(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      fornecedorId: fornecedorId ?? this.fornecedorId,
      data: data ?? this.data,
      valorTotal: valorTotal ?? this.valorTotal,
    );
  }
}
