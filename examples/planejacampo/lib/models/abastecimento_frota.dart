class AbastecimentoFrota {
  final String id;
  final String produtorId;
  final String propriedadeId; // Indica a propriedade de vínculo obrigatório
  final String frotaId;
  final String itemId; // Representa o combustível ou insumo específico
  final DateTime data;
  final double quantidadeUtilizada;
  final String unidadeMedida;
  final double cmpAtual;
  final String unidadeMedidaCMP;
  final String tipoMovimentacaoEstoque;
  final String categoriaMovimentacaoEstoque;
  final bool externo;
  final String? compraId; // Automático no caso de abastecimento externo
  final String? operacaoRuralId; // Opcional, vincula a uma operação rural específica
  final String? fornecedorId; // Novo atributo opcional
  final double? valorTotal; // Novo atributo opcional
  final String? meioPagamento; // Novo atributo opcional
  final String? contaId; // Novo atributo opcional
  final int? numeroParcelas; // Novo atributo opcional

  AbastecimentoFrota({
    required this.id,
    required this.produtorId,
    required this.propriedadeId, // Agora obrigatório
    required this.frotaId,
    required this.itemId,
    required this.data,
    required this.quantidadeUtilizada,
    required this.unidadeMedida,
    required this.cmpAtual,
    required this.unidadeMedidaCMP,
    this.tipoMovimentacaoEstoque = 'Saida',
    this.categoriaMovimentacaoEstoque = 'Consumo',
    this.externo = false,
    this.compraId,
    this.operacaoRuralId,
    this.fornecedorId,
    this.valorTotal,
    this.meioPagamento,
    this.contaId,
    this.numeroParcelas,
  });

  factory AbastecimentoFrota.fromMap(Map<String, dynamic> map, String id) {
    return AbastecimentoFrota(
      id: id,
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '', // Obrigatório no mapa
      frotaId: map['frotaId'] ?? '',
      itemId: map['itemId'] ?? '',
      data: DateTime.parse(map['data']),
      quantidadeUtilizada: (map['quantidadeUtilizada']?.toDouble()) ?? 0.0,
      unidadeMedida: map['unidadeMedida'] ?? '',
      cmpAtual: (map['cmpAtual']?.toDouble()) ?? 0.0,
      unidadeMedidaCMP: map['unidadeMedidaCMP'] ?? '',
      tipoMovimentacaoEstoque: map['tipoMovimentacaoEstoque'] ?? 'Saida',
      categoriaMovimentacaoEstoque: map['categoriaMovimentacaoEstoque'] ?? 'Consumo',
      externo: map['externo'] ?? false,
      compraId: map['compraId'],
      operacaoRuralId: map['operacaoRuralId'],
      fornecedorId: map['fornecedorId'],
      valorTotal: (map['valorTotal']?.toDouble()),
      meioPagamento: map['meioPagamento'],
      contaId: map['contaId'],
      numeroParcelas: map['numeroParcelas'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'propriedadeId': propriedadeId, // Agora obrigatório no mapa
      'frotaId': frotaId,
      'itemId': itemId,
      'data': data.toIso8601String(),
      'quantidadeUtilizada': quantidadeUtilizada,
      'unidadeMedida': unidadeMedida,
      'cmpAtual': cmpAtual,
      'unidadeMedidaCMP': unidadeMedidaCMP,
      'tipoMovimentacaoEstoque': tipoMovimentacaoEstoque,
      'categoriaMovimentacaoEstoque': categoriaMovimentacaoEstoque,
      'externo': externo,
      'compraId': compraId,
      'operacaoRuralId': operacaoRuralId,
      'fornecedorId': fornecedorId,
      'valorTotal': valorTotal,
      'meioPagamento': meioPagamento,
      'contaId': contaId,
      'numeroParcelas': numeroParcelas,
    };
  }

  AbastecimentoFrota copyWith({
    String? id,
    String? produtorId,
    String? propriedadeId,
    String? frotaId,
    String? itemId,
    DateTime? data,
    double? quantidadeUtilizada,
    String? unidadeMedida,
    double? cmpAtual,
    String? unidadeMedidaCMP,
    String? tipoMovimentacaoEstoque,
    String? categoriaMovimentacaoEstoque,
    bool? externo,
    String? compraId,
    String? operacaoRuralId,
    String? fornecedorId,
    double? valorTotal,
    String? meioPagamento,
    String? contaId,
    int? numeroParcelas,
  }) {
    return AbastecimentoFrota(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      frotaId: frotaId ?? this.frotaId,
      itemId: itemId ?? this.itemId,
      data: data ?? this.data,
      quantidadeUtilizada: quantidadeUtilizada ?? this.quantidadeUtilizada,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      cmpAtual: cmpAtual ?? this.cmpAtual,
      unidadeMedidaCMP: unidadeMedidaCMP ?? this.unidadeMedidaCMP,
      tipoMovimentacaoEstoque: tipoMovimentacaoEstoque ?? this.tipoMovimentacaoEstoque,
      categoriaMovimentacaoEstoque: categoriaMovimentacaoEstoque ?? this.categoriaMovimentacaoEstoque,
      externo: externo ?? this.externo,
      compraId: compraId ?? this.compraId,
      operacaoRuralId: operacaoRuralId ?? this.operacaoRuralId,
      fornecedorId: fornecedorId ?? this.fornecedorId,
      valorTotal: valorTotal ?? this.valorTotal,
      meioPagamento: meioPagamento ?? this.meioPagamento,
      contaId: contaId ?? this.contaId,
      numeroParcelas: numeroParcelas ?? this.numeroParcelas,
    );
  }
}
