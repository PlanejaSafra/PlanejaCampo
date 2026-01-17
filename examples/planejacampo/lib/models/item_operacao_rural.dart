class ItemOperacaoRural {
  final String id;
  final String operacaoRuralId;  // Relaciona à operação rural específica
  final String produtorId;
  final String propriedadeId;
  final String itemId;  // O item utilizado na operação
  final DateTime dataUtilizacao;  // Data de utilização do insumo
  final double quantidadeUtilizada;  // Quantidade do insumo utilizado
  final String unidadeMedida;  // Unidade de medida do insumo
  final double cmpAtual;  // Controle de Movimentação de Produtos (CMP) atual
  final String unidadeMedidaCMP;  // Unidade de medida do CMP
  final String tipoMovimentacaoEstoque;  // Tipo de movimentação: 'Entrada' ou 'Saida'
  final String categoriaMovimentacaoEstoque;  // Categoria da movimentação

  ItemOperacaoRural({
    required this.id,
    required this.operacaoRuralId,
    required this.produtorId,
    required this.propriedadeId,
    required this.itemId,
    required this.dataUtilizacao,
    required this.quantidadeUtilizada,
    required this.unidadeMedida,
    required this.cmpAtual,
    required this.unidadeMedidaCMP,
    required this.tipoMovimentacaoEstoque,  // Novo campo
    required this.categoriaMovimentacaoEstoque,  // Novo campo
  });

  factory ItemOperacaoRural.fromMap(Map<String, dynamic> map, String id) {
    return ItemOperacaoRural(
      id: id,
      operacaoRuralId: map['operacaoRuralId'] ?? '',
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      itemId: map['itemId'] ?? '',
      dataUtilizacao: DateTime.parse(map['dataUtilizacao']),
      quantidadeUtilizada: map['quantidadeUtilizada'] ?? 0.0,
      unidadeMedida: map['unidadeMedida'] ?? '',
      cmpAtual: map['cmpAtual'] ?? 0.0,
      unidadeMedidaCMP: map['unidadeMedidaCMP'] ?? '',
      tipoMovimentacaoEstoque: map['tipoMovimentacaoEstoque'] ?? 'Saida',  // Novo campo
      categoriaMovimentacaoEstoque: map['categoriaMovimentacaoEstoque'] ?? 'Consumo',  // Novo campo
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'operacaoRuralId': operacaoRuralId,
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'itemId': itemId,
      'dataUtilizacao': dataUtilizacao.toIso8601String(),
      'quantidadeUtilizada': quantidadeUtilizada,
      'unidadeMedida': unidadeMedida,
      'cmpAtual': cmpAtual,
      'unidadeMedidaCMP': unidadeMedidaCMP,
      'tipoMovimentacaoEstoque': tipoMovimentacaoEstoque,  // Novo campo
      'categoriaMovimentacaoEstoque': categoriaMovimentacaoEstoque,  // Novo campo
    };
  }

  ItemOperacaoRural copyWith({
    String? id,
    String? operacaoRuralId,
    String? produtorId,
    String? propriedadeId,
    String? itemId,
    DateTime? dataUtilizacao,
    double? quantidadeUtilizada,
    String? unidadeMedida,
    double? cmpAtual,
    String? unidadeMedidaCMP,
    String? tipoMovimentacaoEstoque,  // Novo campo
    String? categoriaMovimentacaoEstoque,  // Novo campo
  }) {
    return ItemOperacaoRural(
      id: id ?? this.id,
      operacaoRuralId: operacaoRuralId ?? this.operacaoRuralId,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      itemId: itemId ?? this.itemId,
      dataUtilizacao: dataUtilizacao ?? this.dataUtilizacao,
      quantidadeUtilizada: quantidadeUtilizada ?? this.quantidadeUtilizada,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      cmpAtual: cmpAtual ?? this.cmpAtual,
      unidadeMedidaCMP: unidadeMedidaCMP ?? this.unidadeMedidaCMP,
      tipoMovimentacaoEstoque: tipoMovimentacaoEstoque ?? this.tipoMovimentacaoEstoque,  // Novo campo
      categoriaMovimentacaoEstoque: categoriaMovimentacaoEstoque ?? this.categoriaMovimentacaoEstoque,  // Novo campo
    );
  }
}
