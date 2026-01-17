class Pessoa {
  final String id;
  final String produtorId;
  final String nome;
  final String vinculo;
  final String? tipo;
  final String? documento;
  final String? telefone;
  final String? email;
  final String? endereco;
  final String? notas;

  Pessoa({
    required this.id,
    required this.produtorId,
    required this.nome,
    required this.vinculo,
    this.tipo,
    this.documento,
    this.telefone,
    this.email,
    this.endereco,
    this.notas,
  });

  factory Pessoa.fromMap(Map<String, dynamic> map, String id) {
    return Pessoa(
      id: id,
      produtorId: map['produtorId'] ?? '',
      nome: map['nome'] ?? '',
      vinculo: map['vinculo'] ?? '',
      tipo: map['tipo'],
      documento: map['documento'],
      telefone: map['telefone'],
      email: map['email'],
      endereco: map['endereco'],
      notas: map['notas'],
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produtorId': produtorId,
      'nome': nome,
      'vinculo': vinculo,
      'tipo': tipo,
      'documento': documento,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      'notas': notas,
    };
  }

  Pessoa copyWith({
    String? id,
    String? produtorId,
    String? nome,
    String? vinculo,
    String? tipo,
    String? documento,
    String? telefone,
    String? email,
    String? endereco,
    String? notas,
  }) {
    return Pessoa(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      nome: nome ?? this.nome,
      vinculo: vinculo ?? this.vinculo,
      tipo: tipo ?? this.tipo,
      documento: documento ?? this.documento,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      endereco: endereco ?? this.endereco,
      notas: notas ?? this.notas,
    );
  }
}
