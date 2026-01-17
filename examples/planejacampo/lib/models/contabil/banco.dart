class Banco {
  final String id;  // Identificador único do banco
  final String nome;  // Nome do banco
  final String siglaPais;  // Sigla do país ao qual o banco pertence (ex: 'BR', 'US', 'ES')
  final String? endereco;  // Endereço (opcional)
  final String? telefone;  // Telefone de contato (opcional)
  final String? contato;  // Website (opcional)
  final String? produtorId;  // ID do produtor para vincular bancos personalizados

  Banco({
    required this.id,
    required this.nome,
    required this.siglaPais,
    this.endereco,
    this.telefone,
    this.contato,
    required this.produtorId,
  });

  // Construtor de fábrica para mapear dados de um mapa para um objeto Banco
  factory Banco.fromMap(Map<String, dynamic> map, String id) {
    return Banco(
      id: id,
      nome: map['nome'] ?? '',
      siglaPais: map['siglaPais'] ?? '',
      endereco: map['endereco'],
      telefone: map['telefone'],
      contato: map['site'],
      produtorId: map['produtorId'],
    );
  }

  // Converte o objeto Banco para um mapa (para salvar no banco de dados, por exemplo)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'siglaPais': siglaPais,
      'endereco': endereco,
      'telefone': telefone,
      'site': contato,
      'produtorId': produtorId,
    };
  }

  // Método para copiar e atualizar propriedades de um banco
  Banco copyWith({
    String? id,
    String? nome,
    String? siglaPais,
    String? endereco,
    String? telefone,
    String? contato,
    String? produtorId,
  }) {
    return Banco(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      siglaPais: siglaPais ?? this.siglaPais,
      endereco: endereco ?? this.endereco,
      telefone: telefone ?? this.telefone,
      contato: contato ?? this.contato,
      produtorId: produtorId ?? this.produtorId,
    );
  }

}
