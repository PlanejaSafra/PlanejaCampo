class AtividadeRural {
  final String id;
  final String produtorId;
  final String propriedadeId;
  final String tipo;
  final String subtipo;  // Novo campo subtipo
  final String nome;  // Agora obrigatório
  final DateTime dataInicio;  // Agora obrigatório
  final DateTime? dataFim;
  final List<String>? talhoes;

  AtividadeRural({
    required this.id,
    required this.produtorId,
    required this.propriedadeId,
    required this.tipo,
    required this.subtipo,  // Novo campo subtipo obrigatório
    required this.nome,  // Agora obrigatório
    required this.dataInicio,  // Agora obrigatório
    this.dataFim,
    this.talhoes,
  });

  factory AtividadeRural.fromMap(Map<String, dynamic> map, String id) {
    return AtividadeRural(
      id: id,
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      tipo: map['tipo'] ?? '',
      subtipo: map['subtipo'] ?? '',  // Fornece um valor padrão caso seja null
      nome: map['nome'] ?? '',  // Fornece um valor padrão caso seja null
      dataInicio: DateTime.parse(map['dataInicio'] ?? ''),  // Fornece um valor padrão caso seja null
      dataFim: map['dataFim'] != null ? DateTime.parse(map['dataFim']) : null,
      talhoes: map['talhoes'] != null ? List<String>.from(map['talhoes']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'tipo': tipo,
      'subtipo': subtipo,  // Inclui subtipo no mapa
      'nome': nome,
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim?.toIso8601String(),
      'talhoes': talhoes ?? [],
    };
  }

  AtividadeRural copyWith({
    String? id,
    String? produtorId,
    String? propriedadeId,
    String? tipo,
    String? subtipo,
    String? nome,
    DateTime? dataInicio,
    DateTime? dataFim,
    List<String>? talhoes,
  }) {
    return AtividadeRural(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      tipo: tipo ?? this.tipo,
      subtipo: subtipo ?? this.subtipo,  // Permite cópia com subtipo atualizado
      nome: nome ?? this.nome,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      talhoes: talhoes ?? this.talhoes,
    );
  }
}
