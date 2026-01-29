class ItemBalanco {
  final String nome;
  final double valor;
  
  const ItemBalanco(this.nome, this.valor);
}

/// Balanço Patrimonial com vocabulário híbrido (CASH-28)
class BalancoPatrimonial {
  final DateTime data;
  
  /// "O que você tem"
  final List<ItemBalanco> ativos;
  
  /// "O que você deve"
  final List<ItemBalanco> passivos;
  
  final double totalAtivos;
  final double totalPassivos;
  
  /// "O que sobra" (Patrimônio Líquido)
  final double patrimonioLiquido;

  const BalancoPatrimonial({
    required this.data,
    required this.ativos,
    required this.passivos,
    required this.totalAtivos,
    required this.totalPassivos,
    required this.patrimonioLiquido,
  });
}
