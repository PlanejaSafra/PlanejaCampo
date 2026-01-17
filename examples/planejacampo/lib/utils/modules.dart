class Modules {
  static const Map<String, Map<String, dynamic>> modules = {
    'propriedades': {
      'All': 'All', // Indica que este módulo é acessível para todos os tipos de atividades e subtipos
    },
    'talhoes': {
      'All': 'All', // Indica que este módulo é acessível para todos os tipos de atividades e subtipos
    },
    'itens': {
      'All': 'All', // Indica que este módulo é acessível para todos os tipos de atividades e subtipos
    },
    'pessoas': {
      'All': 'All',
    },
    'compras': {
      'All': 'All',
    },
    'registrosChuvas': {
      'All': 'All', // Indica que este módulo é acessível para todos os tipos de atividades e subtipos
    },
    'bancos': {
      'All': 'All', // Indica que este módulo é acessível para todos os tipos de atividades e subtipos
    },
    'registrosColetas': {
      'Silvicultura': ['Seringueira', 'Eucalipto', 'Mogno'], // Somente para esses subtipos de Silvicultura
      'Apicultura': ['Produção de Mel', 'Produção de Própolis'], // Para Apicultura com subtipos específicos
    },
    'registrosEntregas': {
      'Silvicultura': ['Seringueira', 'Eucalipto', 'Mogno'], // Somente para esses subtipos de Silvicultura
      'Apicultura': ['Produção de Mel', 'Produção de Própolis'], // Para Apicultura com subtipos específicos
    },
    'atividadesRurais': {
      'All': 'All',
    },
    'operacoesRurais': {
      'All': 'All',
    },
    'tiposOperacoesRurais': {
      'All': 'All',
    },
    'frotas': {
      'All': 'All',
    },
    'recomendacoesAdubacao': {
      'All': 'All',
    },
    'contabil': {
      'All': 'All',
    },
  };


  /// Função para verificar se o módulo permite o tipo de atividade e subtipo fornecidos
  static bool canAccessModule(String moduleName, String? tipoAtividade, String? subtipoAtividade) {
    final moduleConfig = modules[moduleName];
    if (moduleConfig == null) {
      return false; // Módulo não encontrado
    }

    if (moduleConfig['All'] == 'All') {
      return true; // Acesso liberado para todos os tipos e subtipos de atividades
    }

    if (moduleConfig.containsKey(tipoAtividade)) {
      final subtipoConfig = moduleConfig[tipoAtividade];
      if (subtipoConfig == 'All') {
        return true; // Acesso liberado para todos os subtipos do tipo de atividade
      } else if (subtipoConfig is List && subtipoConfig.contains(subtipoAtividade)) {
        return true; // Acesso permitido para o subtipo específico
      }
    }

    return false; // Acesso negado
  }
}
