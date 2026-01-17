class Item {
  final String id;
  final String produtorId;
  final String nome;
  final String tipo;
  final String categoria;
  final String unidadeMedida;
  final String descricao;
  final double fatorDecaimento;
  final bool movimentaEstoque;

  Item({
    required this.id,
    required this.produtorId,
    required this.nome,
    required this.tipo,
    required this.categoria,
    required this.unidadeMedida,
    required this.descricao,
    this.fatorDecaimento = 0.95,
    this.movimentaEstoque = false,
  });

  factory Item.fromMap(Map<String, dynamic> map, String id) {
    return Item(
      id: id,
      produtorId: map['produtorId'] ?? '',
      nome: map['nome'] ?? '',
      tipo: map['tipo'] ?? '',
      categoria: map['categoria'] ?? '',
      unidadeMedida: map['unidadeMedida'] ?? '',
      descricao: map['descricao'] ?? '',
      fatorDecaimento: map['fatorDecaimento'] ?? 0.95,
      movimentaEstoque: map['movimentaEstoque'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'produtorId': produtorId,
      'tipo': tipo,
      'categoria': categoria,
      'unidadeMedida': unidadeMedida,
      'descricao': descricao,
      'fatorDecaimento': fatorDecaimento,
      'movimentaEstoque': movimentaEstoque,
    };
  }

  Item copyWith({
    String? id,
    String? produtorId,
    String? nome,
    String? tipo,
    String? categoria,
    String? unidadeMedida,
    String? descricao,
    double? fatorDecaimento,
    bool? movimentaEstoque,
  }) {
    return Item(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      descricao: descricao ?? this.descricao,
      fatorDecaimento: fatorDecaimento ?? this.fatorDecaimento,
      movimentaEstoque: movimentaEstoque ?? this.movimentaEstoque,
    );
  }
}
