class ItemCompra {
  final String id;
  final String compraId;    // Novo campo compraId
  final String produtorId;  // Campo produtorId
  final String propriedadeId;
  final String itemId;
  final double quantidade;
  final double precoUnitario;
  final double valorTotal;
  final String unidadeMedida;

  ItemCompra({
    required this.id,
    required this.compraId,    // Construtor com compraId
    required this.produtorId,  // Construtor com produtorId
    required this.propriedadeId,
    required this.itemId,
    required this.quantidade,
    required this.precoUnitario,
    required this.valorTotal,
    required this.unidadeMedida,
  });

  factory ItemCompra.fromMap(Map<String, dynamic> map, String id) {
    return ItemCompra(
      id: id,
      compraId: map['compraId'] ?? '',      // Inclui compraId
      produtorId: map['produtorId'] ?? '',  // Inclui produtorId
      propriedadeId: map['propriedadeId'] ?? '',
      itemId: map['itemId'] ?? '',
      quantidade: map['quantidade'] ?? 0.0,
      precoUnitario: map['precoUnitario'] ?? 0.0,
      valorTotal: map['valorTotal'] ?? 0.0,
      unidadeMedida: map['unidadeMedida'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'compraId': compraId,      // Inclui compraId no toMap
      'produtorId': produtorId,  // Inclui produtorId no toMap
      'propriedadeId': propriedadeId,
      'quantidade': quantidade,
      'precoUnitario': precoUnitario,
      'valorTotal': valorTotal,
      'unidadeMedida': unidadeMedida,
    };
  }

  ItemCompra copyWith({
    String? id,
    String? produtorId,  // Inclui produtorId no copyWith
    String? propriedadeId,
    String? compraId,    // Inclui compraId no copyWith
    String? itemId,
    double? quantidade,
    double? precoUnitario,
    double? valorTotal,
    String? unidadeMedida,
  }) {
    return ItemCompra(
      id: id ?? this.id,
      compraId: compraId ?? this.compraId,        // Atualiza compraId
      produtorId: produtorId ?? this.produtorId,  // Atualiza produtorId
      propriedadeId: propriedadeId ?? this.propriedadeId,
      itemId: itemId ?? this.itemId,
      quantidade: quantidade ?? this.quantidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      valorTotal: valorTotal ?? this.valorTotal,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
    );
  }
}
