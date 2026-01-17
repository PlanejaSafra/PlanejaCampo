class Talhao {
  final String id;
  final String nome;
  final double area;
  final String produtorId;
  final String propriedadeId;
  final List<Map<String, double>>? coordenadas;  // Alterado para lista de mapas

  Talhao({
    required this.id,
    required this.nome,
    required this.area,
    required this.produtorId,
    required this.propriedadeId,
    this.coordenadas,  // Adicionado ao construtor
  });

  // Método factory para criar uma instância a partir de um mapa
  factory Talhao.fromMap(Map<String, dynamic> map, String id) {
    List<Map<String, double>>? coordenadas;
    if (map['coordenadas'] != null) {
      coordenadas = (map['coordenadas'] as List).map<Map<String, double>>((coord) {
        if (coord is List && coord.length >= 2) {
          // Caso antigo: List<List<double>>
          return {
            'lat': (coord[0] as num).toDouble(),
            'lon': (coord[1] as num).toDouble(),
          };
        } else if (coord is Map<String, dynamic>) {
          // Novo caso: List<Map<String, double>>
          return {
            'lat': (coord['lat'] as num?)?.toDouble() ?? 0.0,
            'lon': (coord['lon'] as num?)?.toDouble() ?? 0.0,
          };
        } else {
          // Fallback para formatos inesperados
          return {'lat': 0.0, 'lon': 0.0};
        }
      }).toList();
    }

    return Talhao(
      id: id,
      nome: map['nome'] ?? '',
      area: (map['area'] as num?)?.toDouble() ?? 0.0,
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      coordenadas: coordenadas,  // Conversão das coordenadas
    );
  }

  // Método para converter a instância para um mapa
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'area': area,
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'coordenadas': coordenadas,  // Adiciona as coordenadas ao mapa
    };
  }

  // Método copyWith para criar uma nova instância com algumas alterações
  Talhao copyWith({
    String? id,
    String? nome,
    double? area,
    String? produtorId,
    String? propriedadeId,
    List<Map<String, double>>? coordenadas,  // Suporte para atualizar coordenadas
  }) {
    return Talhao(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      area: area ?? this.area,
      produtorId: produtorId ?? this.produtorId,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      coordenadas: coordenadas ?? this.coordenadas,  // Atualiza coordenadas
    );
  }
}
