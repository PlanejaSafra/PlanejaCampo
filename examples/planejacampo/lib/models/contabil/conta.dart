class Conta {
  final String id;
  final String nome;
  final String tipo;  // Tipo de conta (ex: Corrente, Poupança, etc.)
  final String? numeroConta;
  final String? bancoId;  // Modificado para referenciar id de Banco
  final double saldoInicial;
  final String? cartaoBandeira;  // Bandeira do cartão de crédito (se aplicável)
  final double? limiteCredito;
  final int? diaFechamentoFatura;
  final int? diaVencimentoFatura;
  final String? descricao;  // Descrição ou observações adicionais
  final String? produtorId;  // ID do produtor para vincular bancos personalizados
  final String? contaContabilId;  // Novo atributo

  Conta({
    required this.id,
    required this.nome,
    required this.tipo,
    this.numeroConta,
    this.bancoId,
    required this.saldoInicial,
    this.cartaoBandeira,
    this.limiteCredito,
    this.diaFechamentoFatura,
    this.diaVencimentoFatura,
    this.descricao,
    required this.produtorId,
    this.contaContabilId,
  });

  // Construtor de fábrica para mapear dados de um mapa para um objeto Conta
  factory Conta.fromMap(Map<String, dynamic> map, String id) {
    return Conta(
      id: id,
      nome: map['nome'] ?? '',
      tipo: map['tipo'] ?? '',
      numeroConta: map['numeroConta'] ?? '',
      bancoId: map['bancoId'] ?? '',
      saldoInicial: map['saldoInicial'] ?? 0.0,
      cartaoBandeira: map['cartaoBandeira'],
      limiteCredito: map['limiteCredito'],
      diaFechamentoFatura: map['diaFechamentoFatura'],
      diaVencimentoFatura: map['diaVencimentoFatura'],
      descricao: map['descricao'],
      produtorId: map['produtorId'] ?? '',
      contaContabilId: map['contaContabilId'] ?? '',
    );
  }

  // Converte o objeto Conta para um mapa (para salvar no banco de dados, por exemplo)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'tipo': tipo,
      'numeroConta': numeroConta,
      'bancoId': bancoId,
      'saldoInicial': saldoInicial,
      'cartaoBandeira': cartaoBandeira,
      'limiteCredito': limiteCredito,
      'diaFechamentoFatura': diaFechamentoFatura,
      'diaVencimentoFatura': diaVencimentoFatura,
      'descricao': descricao,
      'produtorId': produtorId,
      'contaContabilId': contaContabilId,
    };
  }

  // Método para copiar e atualizar propriedades de uma conta
  Conta copyWith({
    String? id,
    String? nome,
    String? tipo,
    String? numeroConta,
    String? bancoId,
    double? saldoInicial,
    String? cartaoBandeira,
    double? limiteCredito,
    int? diaFechamentoFatura,
    int? diaVencimentoFatura,
    String? descricao,
    String? produtorId,
    String? contaContabilId,
  }) {
    return Conta(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      numeroConta: numeroConta ?? this.numeroConta,
      bancoId: bancoId ?? this.bancoId,
      saldoInicial: saldoInicial ?? this.saldoInicial,
      cartaoBandeira: cartaoBandeira ?? this.cartaoBandeira,
      limiteCredito: limiteCredito ?? this.limiteCredito,
      diaFechamentoFatura: diaFechamentoFatura ?? this.diaFechamentoFatura,
      diaVencimentoFatura: diaVencimentoFatura ?? this.diaVencimentoFatura,
      descricao: descricao ?? this.descricao,
      produtorId: produtorId ?? this.produtorId,
      contaContabilId: contaContabilId ?? this.contaContabilId,
    );
  }
}
