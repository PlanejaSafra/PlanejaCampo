class Propriedade {
  final String id;
  final String produtorId;
  final String nome;
  final double area;
  final String modoMovimentacaoEstoque; // Novo campo

  Propriedade({
    required this.id,
    required this.produtorId,
    required this.nome,
    required this.area,
    required this.modoMovimentacaoEstoque, // Novo campo
  });

  factory Propriedade.fromMap(Map<String, dynamic> map, String id) {
    return Propriedade(
      id: id,
      produtorId: map['produtorId'] ?? '',
      nome: map['nome'] ?? '',
      area: map['area'] ?? 0.0,
      modoMovimentacaoEstoque: map['modoMovimentacaoEstoque'] ?? 'Auto', // Novo campo
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'nome': nome,
      'area': area,
      'modoMovimentacaoEstoque': modoMovimentacaoEstoque, // Novo campo
    };
  }

  Propriedade copyWith({
    String? id,
    String? produtorId,
    String? nome,
    double? area,
    String? modoMovimentacaoEstoque, // Novo campo
  }) {
    return Propriedade(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      nome: nome ?? this.nome,
      area: area ?? this.area,
      modoMovimentacaoEstoque: modoMovimentacaoEstoque ?? this.modoMovimentacaoEstoque, // Novo campo
    );
  }
}
