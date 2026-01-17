class Produtor {
  final String id;
  final String nome;
  final String status;
  final String tipo;
  final String documento;
  final List<Map<String, String>> permissoes;  // Permissões do usuário
  final List<String> usuariosPermitidos; // Campo indexável para consultas eficientes
  final String? criadorId;  // ID do criador do produtor
  final List<Map<String, dynamic>>? licencas;  // Licenças do produtor
  final int databaseVersion;
  final List<Map<String, dynamic>> cargaInicial;

  Produtor({
    required this.id,
    required this.nome,
    required this.status,
    required this.tipo,
    required this.documento,
    required this.permissoes,
    List<String>? usuariosPermitidos,  // Parâmetro opcional para compatibilidade
    required this.criadorId,
    required this.licencas,
    this.databaseVersion = 0,
    this.cargaInicial = const [],
  }) : usuariosPermitidos = usuariosPermitidos ?? _extractUserIds(permissoes);

  // Método de utilidade para extrair IDs de usuário e emails das permissões
  static List<String> _extractUserIds(List<Map<String, String>> permissoes) {
    final Set<String> ids = {};
    for (var permissao in permissoes) {
      if (permissao['usuarioId'] != null && permissao['usuarioId']!.isNotEmpty) {
        ids.add(permissao['usuarioId']!);
      }
      if (permissao['email'] != null && permissao['email']!.isNotEmpty) {
        ids.add('email:${permissao['email']!}');
      }
    }
    return ids.toList();
  }

  factory Produtor.fromMap(Map<String, dynamic> map, String id) {
    final permissoes = List<Map<String, String>>.from(
        map['permissoes']?.map((p) => Map<String, String>.from(p)) ?? []
    );

    // Obter usuariosPermitidos do mapa ou gerar com base nas permissões
    List<String>? usuariosPermitidos;
    if (map['usuariosPermitidos'] != null) {
      usuariosPermitidos = List<String>.from(map['usuariosPermitidos']);
    }

    return Produtor(
      id: id,
      nome: map['nome'] ?? '',
      status: map['status'] ?? '',
      tipo: map['tipo'] ?? '',
      documento: map['documento'] ?? '',
      permissoes: permissoes,
      usuariosPermitidos: usuariosPermitidos,  // Pode ser null, o construtor lida com isso
      criadorId: map['criadorId'],
      licencas: map['licencas'] != null
          ? List<Map<String, dynamic>>.from(
          map['licencas']?.map((l) => Map<String, dynamic>.from(l)) ?? []
      )
          : null,
      databaseVersion: map['database_version'] ?? 0,
      cargaInicial: List<Map<String, dynamic>>.from(
          map['cargaInicial']?.map((p) => Map<String, dynamic>.from(p)) ?? []
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'status': status,
      'tipo': tipo,
      'documento': documento,
      'permissoes': permissoes,
      'usuariosPermitidos': usuariosPermitidos,  // Novo campo para índice
      'criadorId': criadorId,
      'licencas': licencas,
      'database_version': databaseVersion,
      'cargaInicial': cargaInicial,
    };
  }

  Produtor copyWith({
    String? id,
    String? nome,
    String? status,
    String? tipo,
    String? documento,
    List<Map<String, String>>? permissoes,
    List<String>? usuariosPermitidos,
    String? criadorId,
    List<Map<String, dynamic>>? licencas,
    int? databaseVersion,
    List<Map<String, dynamic>>? cargaInicial,
  }) {
    final newPermissoes = permissoes ?? this.permissoes;

    return Produtor(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      status: status ?? this.status,
      tipo: tipo ?? this.tipo,
      documento: documento ?? this.documento,
      permissoes: newPermissoes,
      // Se usuariosPermitidos não for fornecido mas permissões sim, recalcular
      usuariosPermitidos: usuariosPermitidos ??
          (permissoes != null ? _extractUserIds(newPermissoes) : this.usuariosPermitidos),
      criadorId: criadorId ?? this.criadorId,
      licencas: licencas ?? this.licencas,
      databaseVersion: databaseVersion ?? this.databaseVersion,
      cargaInicial: cargaInicial ?? this.cargaInicial,
    );
  }

  static Produtor empty() {
    return Produtor(
      id: '',
      nome: '',
      status: '',
      tipo: '',
      documento: '',
      permissoes: [],
      usuariosPermitidos: [], // Lista vazia para produtores novos
      criadorId: null,
      licencas: null,
      databaseVersion: 0,
      cargaInicial: [],
    );
  }
}