class Licenses {
  static const Map<String, Map<String, dynamic>> licenses = {
    'AcessoBasico': {
      'maxProdutores': 1,  // Limite de 1 produtor
      'maxUsuarios': 1,  // Limite de 1 produtor
      'maxPropriedades': 1,  // Limite de 1 propriedade
      'propriedades': true,
      'talhoes': true,
      'itens': true,
      'pessoas': true,
      'compras': true,
      'registrosChuvas': true,
      'bancos': false,
      'registrosColetas': true,
      'registrosEntregas': true,
      'atividadesRurais': true,
      'operacoesRurais': true,
      'tiposOperacoesRurais': true,
      'frotas': true,
      'recomendacoesAdubacao': true,
      'contabil': false,
    },
    'AcessoCompletoPequenoProdutor': {
      'maxProdutores': 1,  // Limite de 1 produtor
      'maxUsuarios': 2,  // Limite de 2 produtores
      'maxPropriedades': 4,  // Limite de 4 propriedade
      'propriedades': true,
      'talhoes': true,
      'itens': true,
      'pessoas': true,
      'compras': true,
      'registrosChuvas': true,
      'bancos': true,
      'registrosColetas': true,
      'registrosEntregas': true,
      'atividadesRurais': true,
      'operacoesRurais': true,
      'tiposOperacoesRurais': true,
      'frotas': true,
      'recomendacoesAdubacao': true,
      'contabil': true,
    },
    'AcessoCompletoMedioProdutor': {
      'maxProdutores': 2,  // Limite de 1 produtor
      'maxUsuarios': 4,  // Limite de 5 produtores
      'maxPropriedades': 8,  // Limite de 8 propriedade
      'propriedades': true,
      'talhoes': true,
      'itens': true,
      'pessoas': true,
      'compras': true,
      'registrosChuvas': true,
      'bancos': true,
      'registrosColetas': true,
      'registrosEntregas': true,
      'atividadesRurais': true,
      'operacoesRurais': true,
      'tiposOperacoesRurais': true,
      'frotas': true,
      'recomendacoesAdubacao': true,
      'contabil': true,
    },
    'LicencaPermanente': {
      'maxProdutores': null,  // Limite de 1 produtor
      'maxUsuarios': null,  // Ilimitado
      'maxPropriedades': null,  // Ilimitado
      'propriedades': true,
      'talhoes': true,
      'itens': true,
      'pessoas': true,
      'compras': true,
      'registrosChuvas': true,
      'bancos': true,
      'registrosColetas': true,
      'registrosEntregas': true,
      'atividadesRurais': true,
      'operacoesRurais': true,
      'tiposOperacoesRurais': true,
      'frotas': true,
      'recomendacoesAdubacao': true,
      'contabil': true,
    },
    'Admin': {
      'maxProdutores': null,  // Limite de 1 produtor
      'maxUsuarios': null,  // Ilimitado
      'maxPropriedades': null,  // Ilimitado
      'propriedades': true,
      'talhoes': true,
      'itens': true,
      'pessoas': true,
      'compras': true,
      'registrosChuvas': true,
      'bancos': true,
      'registrosColetas': true,
      'registrosEntregas': true,
      'atividadesRurais': true,
      'operacoesRurais': true,
      'tiposOperacoesRurais': true,
      'frotas': true,
      'recomendacoesAdubacao': true,
      'contabil': true,
    }
  };

  // Método para verificar se uma licença pode acessar um módulo específico
  static bool canAccessModule(String licenseType, String module) {
    return licenses[licenseType]?[module] ?? false;  // Retorna false se o módulo não for encontrado
  }

  // Método para obter o limite de usuários com acesso ao produtor ativo no contexto com base na licença
  static int? getMaxUsuarios(String licenseType) {
    return licenses[licenseType]?['maxUsuarios'];
  }

  // Método para obter o limite de produtores com base na licença
  static int? getMaxProdutores(String licenseType) {
    return licenses[licenseType]?['maxProdutores'];
  }

  // Adicionar método para obter limite de propriedades
  static int? getMaxPropriedades(String licenseType) {
    return licenses[licenseType]?['maxPropriedades'];
  }
}
