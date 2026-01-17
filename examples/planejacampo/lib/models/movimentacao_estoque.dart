import 'package:cloud_firestore/cloud_firestore.dart';

class MovimentacaoEstoque {
  final String id;
  final String propriedadeId;
  final String itemId;
  final String produtorId;  // Novo campo
  final double quantidade;
  final double valorUnitario;
  final String tipo; // entrada, saida
  final String categoria;
  final DateTime data;
  final DateTime timestamp;
  final String unidadeMedida;
  final double estoqueAtual;
  final double cmpAtual;
  final String unidadeMedidaCMP;
  final String origemId;
  final String origemTipo;
  final bool ativo;

  MovimentacaoEstoque({
    required this.id,
    required this.propriedadeId,
    required this.itemId,
    required this.produtorId,  // Adicionado no construtor
    required this.quantidade,
    required this.valorUnitario,
    required this.tipo,
    required this.categoria,
    required this.data,
    required this.timestamp,
    required this.unidadeMedida,
    required this.estoqueAtual,
    required this.cmpAtual,
    required this.unidadeMedidaCMP,
    required this.origemId,
    required this.origemTipo,
    required this.ativo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propriedadeId': propriedadeId,
      'itemId': itemId,
      'produtorId': produtorId,  // Adicionado no toMap
      'quantidade': quantidade,
      'valorUnitario': valorUnitario,
      'tipo': tipo,
      'categoria': categoria,
      'data': Timestamp.fromDate(data), // Converte DateTime para Timestamp
      'timestamp': Timestamp.fromDate(timestamp),
      'unidadeMedida': unidadeMedida,
      'estoqueAtual': estoqueAtual,
      'cmpAtual': cmpAtual,
      'unidadeMedidaCMP': unidadeMedidaCMP,
      'origemId': origemId,
      'origemTipo': origemTipo,
      'ativo': ativo,
    };
  }

  static MovimentacaoEstoque fromMap(Map<String, dynamic> map, String documentId) {
    return MovimentacaoEstoque(
      id: documentId,
      propriedadeId: map['propriedadeId'],
      itemId: map['itemId'],
      produtorId: map['produtorId'] ?? '',  // Adicionado no fromMap
      quantidade: map['quantidade'],
      valorUnitario: map['valorUnitario'],
      tipo: map['tipo'],
      categoria: map['categoria'],
      data: (map['data'] as Timestamp).toDate(), // Converte Timestamp para DateTime
      timestamp: (map['timestamp'] as Timestamp).toDate(), // Converte Timestamp para DateTime
      unidadeMedida: map['unidadeMedida'],
      estoqueAtual: map['estoqueAtual'],
      cmpAtual: map['cmpAtual'],
      unidadeMedidaCMP: map['unidadeMedidaCMP'],
      origemId: map['origemId'],
      origemTipo: map['origemTipo'],
      ativo: map['ativo'],
    );
  }

  MovimentacaoEstoque copyWith({
    String? id,
    String? propriedadeId,
    String? itemId,
    String? produtorId,  // Adicionado no copyWith
    double? quantidade,
    double? valorUnitario,
    String? tipo,
    String? categoria,
    DateTime? data,
    DateTime? timestamp,
    String? unidadeMedida,
    double? estoqueAtual,
    double? cmpAtual,
    String? unidadeMedidaCMP,
    String? origemId,
    String? origemTipo,
    bool? ativo,
  }) {
    return MovimentacaoEstoque(
      id: id ?? this.id,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      itemId: itemId ?? this.itemId,
      produtorId: produtorId ?? this.produtorId,  // Atualiza o campo produtorId
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      estoqueAtual: estoqueAtual ?? this.estoqueAtual,
      cmpAtual: cmpAtual ?? this.cmpAtual,
      unidadeMedidaCMP: unidadeMedidaCMP ?? this.unidadeMedidaCMP,
      origemId: origemId ?? this.origemId,
      origemTipo: origemTipo ?? this.origemTipo,
      ativo: ativo ?? this.ativo,
    );
  }
}
