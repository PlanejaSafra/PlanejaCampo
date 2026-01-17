class ItemManutencaoFrota {
  final String id;
  final String produtorId;
  final String manutencaoFrotaId;
  final String propriedadeId; // Indica o estoque da propriedade
  final String itemId;
  final DateTime dataUtilizacao;
  final double quantidadeUtilizada;
  final String unidadeMedida;
  final double cmpAtual;
  final String unidadeMedidaCMP;
  final String tipoMovimentacaoEstoque;
  final String categoriaMovimentacaoEstoque;

  ItemManutencaoFrota({
    required this.id,
    required this.produtorId,
    required this.manutencaoFrotaId,
    required this.propriedadeId,
    required this.itemId,
    required this.dataUtilizacao,
    required this.quantidadeUtilizada,
    required this.unidadeMedida,
    required this.cmpAtual,
    required this.unidadeMedidaCMP,
    this.tipoMovimentacaoEstoque = 'Saida',
    this.categoriaMovimentacaoEstoque = 'Consumo',
  });

  factory ItemManutencaoFrota.fromMap(Map<String, dynamic> map, String id) {
    return ItemManutencaoFrota(
      id: id,
      produtorId: map['produtorId'] ?? '',
      manutencaoFrotaId: map['manutencaoFrotaId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      itemId: map['itemId'] ?? '',
      dataUtilizacao: DateTime.parse(map['dataUtilizacao']),
      quantidadeUtilizada: (map['quantidadeUtilizada']?.toDouble()) ?? 0.0,
      unidadeMedida: map['unidadeMedida'] ?? '',
      cmpAtual: (map['cmpAtual']?.toDouble()) ?? 0.0,
      unidadeMedidaCMP: map['unidadeMedidaCMP'] ?? '',
      tipoMovimentacaoEstoque: map['tipoMovimentacaoEstoque'] ?? 'Saida',
      categoriaMovimentacaoEstoque: map['categoriaMovimentacaoEstoque'] ?? 'Consumo',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'manutencaoFrotaId': manutencaoFrotaId,
      'propriedadeId': propriedadeId,
      'itemId': itemId,
      'dataUtilizacao': dataUtilizacao.toIso8601String(),
      'quantidadeUtilizada': quantidadeUtilizada,
      'unidadeMedida': unidadeMedida,
      'cmpAtual': cmpAtual,
      'unidadeMedidaCMP': unidadeMedidaCMP,
      'tipoMovimentacaoEstoque': tipoMovimentacaoEstoque,
      'categoriaMovimentacaoEstoque': categoriaMovimentacaoEstoque,
    };
  }

  ItemManutencaoFrota copyWith({
    String? id,
    String? produtorId,
    String? manutencaoFrotaId,
    String? propriedadeId,
    String? itemId,
    DateTime? dataUtilizacao,
    double? quantidadeUtilizada,
    String? unidadeMedida,
    double? cmpAtual,
    String? unidadeMedidaCMP,
    String? tipoMovimentacaoEstoque,
    String? categoriaMovimentacaoEstoque,
  }) {
    return ItemManutencaoFrota(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      manutencaoFrotaId: manutencaoFrotaId ?? this.manutencaoFrotaId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      itemId: itemId ?? this.itemId,
      dataUtilizacao: dataUtilizacao ?? this.dataUtilizacao,
      quantidadeUtilizada: quantidadeUtilizada ?? this.quantidadeUtilizada,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      cmpAtual: cmpAtual ?? this.cmpAtual,
      unidadeMedidaCMP: unidadeMedidaCMP ?? this.unidadeMedidaCMP,
      tipoMovimentacaoEstoque:
      tipoMovimentacaoEstoque ?? this.tipoMovimentacaoEstoque,
      categoriaMovimentacaoEstoque:
      categoriaMovimentacaoEstoque ?? this.categoriaMovimentacaoEstoque,
    );
  }
}
