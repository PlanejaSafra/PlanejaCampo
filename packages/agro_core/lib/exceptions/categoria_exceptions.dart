class CategoriaNotFoundException implements Exception {
  final String id;
  const CategoriaNotFoundException(this.id);
  @override
  String toString() => 'CategoriaNotFoundException: Categoria $id não encontrada.';
}

class CategoriaCoreKeyImmutableException implements Exception {
  @override
  String toString() => 'CategoriaCoreKeyImmutableException: Não é permitido alterar o coreKey de uma categoria.';
}

class CategoriaTypeChangeException implements Exception {
  @override
  String toString() => 'CategoriaTypeChangeException: Não é permitido alterar o tipo (Receita/Despesa) de uma categoria em uso.';
}

class CategoriaCoreDeleteException implements Exception {
  @override
  String toString() => 'CategoriaCoreDeleteException: Não é permitido excluir uma categoria do sistema (Core). Tente arquivá-la.';
}
