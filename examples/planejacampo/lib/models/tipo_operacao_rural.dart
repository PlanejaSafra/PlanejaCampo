class TipoOperacaoRural {
  final String id;
  final String produtorId;
  final String siglaPais;
  final String nome;
  final String descricao;

  TipoOperacaoRural({
    required this.id,
    required this.produtorId,
    required this.siglaPais,
    required this.nome,
    required this.descricao,
  });

  factory TipoOperacaoRural.fromMap(Map<String, dynamic> map, String id) {
    return TipoOperacaoRural(
      id: id,
      produtorId: map['produtorId'] ?? '',
      siglaPais: map['siglaPais'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'siglaPais': siglaPais,
      'nome': nome,
      'descricao': descricao,
    };
  }

  TipoOperacaoRural copyWith({
    String? id,
    String? produtorId,
    String? siglaPais,
    String? nome,
    String? descricao,
  }) {
    return TipoOperacaoRural(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      siglaPais: siglaPais ?? this.siglaPais,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
    );
  }
}
