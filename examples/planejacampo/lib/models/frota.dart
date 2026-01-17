class Frota {
  final String id;  // Autogerado pelo Firebase
  final String nome;
  final String tipo;  // Utiliza FrotaOptions para o tipo de frota
  final String? modelo;
  final int? anoFabricacao;
  final double? valor;
  final double? horimetroOdometro;
  final int? vidaUtil;
  final DateTime? dataAquisicao;
  final String? observacoes;
  final String? identificador;  // Número de série ou placa do veículo
  final String? fotoUrl;  // URL da foto armazenada no banco de dados
  final String? produtorId;
  final String? propriedadeId;  // Relaciona a frota a uma propriedade específica

  Frota({
    required this.id,
    required this.nome,
    required this.tipo,
    this.modelo,
    this.anoFabricacao,
    this.valor,
    this.horimetroOdometro,
    this.vidaUtil,
    this.dataAquisicao,
    this.observacoes,
    this.identificador,
    this.fotoUrl,
    required this.produtorId,
    this.propriedadeId,
  });

  // Factory para criar um Frota a partir de um mapa de dados
  factory Frota.fromMap(Map<String, dynamic> map, String id) {
    return Frota(
      id: id,
      nome: map['nome'] ?? '',
      tipo: map['tipo'] ?? '',
      modelo: map['modelo'],
      anoFabricacao: map['anoFabricacao'],
      valor: map['valor']?.toDouble(),
      horimetroOdometro: map['horimetroOdometro']?.toDouble(),
      vidaUtil: map['vidaUtil'],
      dataAquisicao: map['dataAquisicao'] != null ? DateTime.parse(map['dataAquisicao']) : null,
      observacoes: map['observacoes'],
      identificador: map['identificador'],
      fotoUrl: map['fotoUrl'],
      produtorId: map['produtorId'],
      propriedadeId: map['propriedadeId'],
    );
  }

  // Converte um objeto Frota em um mapa de dados
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'tipo': tipo,
      'modelo': modelo,
      'anoFabricacao': anoFabricacao,
      'valor': valor,
      'horimetroOdometro': horimetroOdometro,
      'vidaUtil': vidaUtil,
      'dataAquisicao': dataAquisicao?.toIso8601String(),
      'observacoes': observacoes,
      'identificador': identificador,
      'fotoUrl': fotoUrl,
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
    };
  }

  // Método para fazer cópias do objeto Frota com novos valores opcionais
  Frota copyWith({
    String? id,
    String? nome,
    String? tipo,
    String? modelo,
    int? anoFabricacao,
    double? valor,
    double? horimetroOdometro,
    int? vidaUtil,
    DateTime? dataAquisicao,
    String? observacoes,
    String? identificador,
    String? fotoUrl,
    String? produtorId,
    String? propriedadeId,
  }) {
    return Frota(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      modelo: modelo ?? this.modelo,
      anoFabricacao: anoFabricacao ?? this.anoFabricacao,
      valor: valor ?? this.valor,
      horimetroOdometro: horimetroOdometro ?? this.horimetroOdometro,
      vidaUtil: vidaUtil ?? this.vidaUtil,
      dataAquisicao: dataAquisicao ?? this.dataAquisicao,
      observacoes: observacoes ?? this.observacoes,
      identificador: identificador ?? this.identificador,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
    );
  }
}
