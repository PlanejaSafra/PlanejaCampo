import 'package:cloud_firestore/cloud_firestore.dart';

class Estoque {
  String id;
  final String itemId;
  final String propriedadeId;
  final String produtorId;
  final double quantidade;
  final String unidadeMedida;
  final double cmp;
  final String unidadeMedidaCmp;
  final DateTime ultimaAtualizacaoCmp;
  final String? origemId;          // Optional
  final String? origemTipo;        // Optional
  final bool emProcessamento;  // Optional with default value inativo. Pode ser Processando ou Inativo

  Estoque({
    required this.id,
    required this.itemId,
    required this.propriedadeId,
    required this.produtorId,
    required this.quantidade,
    required this.unidadeMedida,
    required this.cmp,
    required this.unidadeMedidaCmp,
    required this.ultimaAtualizacaoCmp,
    this.origemId,                         // Optional parameter
    this.origemTipo,                       // Optional parameter
    this.emProcessamento = false,      // Defaults to false (inactive)
  });

  factory Estoque.fromMap(Map<String, dynamic> map, String id) {
    return Estoque(
      id: id,
      itemId: map['itemId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      produtorId: map['produtorId'] ?? '',
      quantidade: map['quantidade'] ?? 0.0,
      unidadeMedida: map['unidadeMedida'] ?? '',
      cmp: map['cmp'] ?? 0.0,
      unidadeMedidaCmp: map['unidadeMedidaCmp'] ?? '',
      ultimaAtualizacaoCmp: (map['ultimaAtualizacaoCmp'] as Timestamp).toDate(),
      origemId: map['origemId'],                      // Optional field
      origemTipo: map['origemTipo'],                  // Optional field
      emProcessamento: map['emProcessamento'] ?? false,  // Defaults to false
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'propriedadeId': propriedadeId,
      'produtorId': produtorId,
      'quantidade': quantidade,
      'unidadeMedida': unidadeMedida,
      'cmp': cmp,
      'unidadeMedidaCmp': unidadeMedidaCmp,
      'ultimaAtualizacaoCmp': ultimaAtualizacaoCmp,
      'origemId': origemId,                          // Optional field
      'origemTipo': origemTipo,                      // Optional field
      'emProcessamento': emProcessamento,    // Optional field
    };
  }

  Estoque copyWith({
    String? id,
    String? itemId,
    String? propriedadeId,
    String? produtorId,
    double? quantidade,
    String? unidadeMedida,
    double? cmp,
    String? unidadeMedidaCmp,
    DateTime? ultimaAtualizacaoCmp,
    String? origemId,
    String? origemTipo,
    bool? emProcessamento,
  }) {
    return Estoque(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      produtorId: produtorId ?? this.produtorId,
      quantidade: quantidade ?? this.quantidade,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      cmp: cmp ?? this.cmp,
      unidadeMedidaCmp: unidadeMedidaCmp ?? this.unidadeMedidaCmp,
      ultimaAtualizacaoCmp: ultimaAtualizacaoCmp ?? this.ultimaAtualizacaoCmp,
      origemId: origemId ?? this.origemId,
      origemTipo: origemTipo ?? this.origemTipo,
      emProcessamento: emProcessamento ?? this.emProcessamento,
    );
  }
}
