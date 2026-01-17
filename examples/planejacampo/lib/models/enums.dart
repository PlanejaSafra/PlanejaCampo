// lib/models/enums.dart

import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

enum OperationType {
  add,
  update,
  delete,
}

enum ClasseResposta {
  ALTA,
  MEDIA_BAIXA;

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case ClasseResposta.ALTA:
        return S.of(context).high_response;
      case ClasseResposta.MEDIA_BAIXA:
        return S.of(context).medium_low_response;
    }
  }

  String getLocalizedDescription(BuildContext context) {
    switch (this) {
      case ClasseResposta.ALTA:
        return S.of(context).high_response_description;
      case ClasseResposta.MEDIA_BAIXA:
        return S.of(context).medium_low_response_description;
    }
  }

  static ClasseResposta fromString(String value) {
    return ClasseResposta.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == value.toUpperCase(),
      orElse: () => ClasseResposta.MEDIA_BAIXA,
    );
  }
}

enum EpocaPlantio {
  SAFRA_VERAO,
  SAFRINHA,
  ANO_TODO;

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case EpocaPlantio.SAFRA_VERAO:
        return S.of(context).summer_harvest;
      case EpocaPlantio.SAFRINHA:
        return S.of(context).off_season;
      case EpocaPlantio.ANO_TODO:
        return S.of(context).year_round;
    }
  }

  static EpocaPlantio fromString(String value) {
    return EpocaPlantio.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == value.toUpperCase(),
      orElse: () => EpocaPlantio.ANO_TODO,
    );
  }
}

enum SistemaCultivo {
  CONVENCIONAL,
  PLANTIO_DIRETO,
  MINIMO;

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case SistemaCultivo.CONVENCIONAL:
        return S.of(context).conventional;
      case SistemaCultivo.PLANTIO_DIRETO:
        return S.of(context).direct_sowing;
      case SistemaCultivo.MINIMO:
        return S.of(context).minimum;
    }
  }

  static SistemaCultivo fromString(String value) {
    return SistemaCultivo.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == value.toUpperCase(),
      orElse: () => SistemaCultivo.CONVENCIONAL,
    );
  }
}

enum TexturaSolo {
  ARENOSO,
  MEDIO,
  ARGILOSO;

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case TexturaSolo.ARENOSO:
        return S.of(context).sandy_soil;
      case TexturaSolo.MEDIO:
        return S.of(context).medium_soil;
      case TexturaSolo.ARGILOSO:
        return S.of(context).clay_soil;
    }
  }

  String get name => toString().split('.').last;

  static TexturaSolo fromString(String value) {
    return TexturaSolo.values.firstWhere(
          (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => TexturaSolo.MEDIO,
    );
  }
}

enum TipoCultura {
  MILHO_GRAO,
  MILHO_SILAGEM,
  MILHO_PIPOCA,
  SOJA,
  AMENDOIM,
  CANA_DE_ACUCAR,
  FEIJAO,
  ALGODAO,
  TRIGO,
  ARROZ,
  CAFE,
  CANA;

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case TipoCultura.MILHO_GRAO:
        return S.of(context).corn_grain;
      case TipoCultura.MILHO_SILAGEM:
        return S.of(context).corn_silage;
      case TipoCultura.MILHO_PIPOCA:
        return S.of(context).popcorn;
      case TipoCultura.SOJA:
        return S.of(context).soybean;
      case TipoCultura.AMENDOIM:
        return S.of(context).peanut;
      case TipoCultura.CANA_DE_ACUCAR:
        return S.of(context).sugarcane;
      case TipoCultura.FEIJAO:
        return S.of(context).bean;
      case TipoCultura.ALGODAO:
        return S.of(context).cotton;
      case TipoCultura.TRIGO:
        return S.of(context).wheat;
      case TipoCultura.ARROZ:
        return S.of(context).rice;
      case TipoCultura.CAFE:
        return S.of(context).coffee;
      case TipoCultura.CANA:
        return S.of(context).sugarcane;
    }
  }

  static TipoCultura fromString(String value) {
    return TipoCultura.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == value.toUpperCase(),
      orElse: () => TipoCultura.SOJA,
    );
  }
}

enum CicloCultura {
  SAFRA,
  SAFRINHA,
  PLANTA,
  SOCA;

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case CicloCultura.SAFRA:
        return S.of(context).main_season;
      case CicloCultura.SAFRINHA:
        return S.of(context).second_season;
      case CicloCultura.PLANTA:
        return S.of(context).plant_cycle;
      case CicloCultura.SOCA:
        return S.of(context).ratoon_cycle;
    }
  }

  static CicloCultura fromString(String value) {
    return CicloCultura.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == value.toUpperCase(),
      orElse: () => CicloCultura.SAFRA,
    );
  }
}

enum CondicaoClimatica {
  SECO,
  UMIDO,
  MUITO_UMIDO,
  POS_CHUVA,
  NORMAL;

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case CondicaoClimatica.SECO:
        return S.of(context).dry_soil;
      case CondicaoClimatica.UMIDO:
        return S.of(context).moist_soil;
      case CondicaoClimatica.MUITO_UMIDO:
        return S.of(context).very_moist_soil;
      case CondicaoClimatica.POS_CHUVA:
        return S.of(context).after_rain;
      case CondicaoClimatica.NORMAL:
        return S.of(context).normal_conditions;
    }
  }

  static CondicaoClimatica fromString(String value) {
    return CondicaoClimatica.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == value.toUpperCase(),
      orElse: () => CondicaoClimatica.NORMAL,
    );
  }
}

enum ProfundidadeAmostra {
  SUPERFICIAL,     // 0-20 cm  (padrão para maioria das culturas)
  SUBSUPERFICIAL,  // 20-40 cm (padrão para maioria das culturas)
  CANA_SUPERFICIAL,       // 0-25 cm  (específico para cana)
  CANA_SUBSUPERFICIAL;    // 25-50 cm (específico para cana)

  String get descricao {
    switch (this) {
      case ProfundidadeAmostra.SUPERFICIAL:
        return "0-20";
      case ProfundidadeAmostra.SUBSUPERFICIAL:
        return "20-40";
      case ProfundidadeAmostra.CANA_SUPERFICIAL:
        return "0-25";
      case ProfundidadeAmostra.CANA_SUBSUPERFICIAL:
        return "25-50";
    }
  }

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case ProfundidadeAmostra.SUPERFICIAL:
        return S.of(context).surface_layer;
      case ProfundidadeAmostra.SUBSUPERFICIAL:
        return S.of(context).subsurface_layer;
      case ProfundidadeAmostra.CANA_SUPERFICIAL:
        return S.of(context).sugarcane_surface_layer;
      case ProfundidadeAmostra.CANA_SUBSUPERFICIAL:
        return S.of(context).sugarcane_subsurface_layer;
    }
  }

  // Retorna a profundidade inicial em cm
  int get profundidadeInicial {
    switch (this) {
      case ProfundidadeAmostra.SUPERFICIAL:
        return 0;
      case ProfundidadeAmostra.SUBSUPERFICIAL:
        return 20;
      case ProfundidadeAmostra.CANA_SUPERFICIAL:
        return 0;
      case ProfundidadeAmostra.CANA_SUBSUPERFICIAL:
        return 25;
    }
  }

  // Retorna a profundidade final em cm
  int get profundidadeFinal {
    switch (this) {
      case ProfundidadeAmostra.SUPERFICIAL:
        return 20;
      case ProfundidadeAmostra.SUBSUPERFICIAL:
        return 40;
      case ProfundidadeAmostra.CANA_SUPERFICIAL:
        return 25;
      case ProfundidadeAmostra.CANA_SUBSUPERFICIAL:
        return 50;
    }
  }

  /// Retorna a lista de profundidades aplicáveis para cada cultura
  static List<ProfundidadeAmostra> getProfundidadesPorCultura(TipoCultura cultura) {
    switch (cultura) {
      case TipoCultura.CANA_DE_ACUCAR:
      case TipoCultura.CANA:
        return [ProfundidadeAmostra.CANA_SUPERFICIAL, ProfundidadeAmostra.CANA_SUBSUPERFICIAL];

      case TipoCultura.SOJA:
      case TipoCultura.MILHO_GRAO:
      case TipoCultura.MILHO_SILAGEM:
      case TipoCultura.MILHO_PIPOCA:
      case TipoCultura.AMENDOIM:
      case TipoCultura.FEIJAO:
      case TipoCultura.ALGODAO:
      case TipoCultura.TRIGO:
      case TipoCultura.ARROZ:
      case TipoCultura.CAFE:
        return [ProfundidadeAmostra.SUPERFICIAL, ProfundidadeAmostra.SUBSUPERFICIAL];
    }

    // Retorno padrão para evitar erro de não-retorno
    return [ProfundidadeAmostra.SUPERFICIAL, ProfundidadeAmostra.SUBSUPERFICIAL];
  }

  // Método para obter profundidade superficial por cultura
  static ProfundidadeAmostra getSuperficiePorCultura(TipoCultura cultura) {
    switch (cultura) {
      case TipoCultura.CANA_DE_ACUCAR:
        return CANA_SUPERFICIAL;
      default:
        return SUPERFICIAL;
    }
  }

  // Método para obter profundidade subsuperficial por cultura
  static ProfundidadeAmostra getSubsuperficiePorCultura(TipoCultura cultura) {
    switch (cultura) {
      case TipoCultura.CANA_DE_ACUCAR:
        return CANA_SUBSUPERFICIAL;
      default:
        return SUBSUPERFICIAL;
    }
  }

  static ProfundidadeAmostra fromString(String value) {
    return ProfundidadeAmostra.values.firstWhere(
          (e) => e.descricao == value,
      orElse: () => ProfundidadeAmostra.SUPERFICIAL,
    );
  }
}

enum MetodoExtracao {
  MEHLICH,
  RESINA,
  DTPA,
  KCL,
  AGUA_QUENTE
}

extension MetodoExtracaoExtension on MetodoExtracao {
  String getLocalizedName(BuildContext context) {
    switch (this) {
      case MetodoExtracao.MEHLICH:
        return S.of(context).mehlich;
      case MetodoExtracao.RESINA:
        return S.of(context).resin;
      case MetodoExtracao.DTPA:
        return 'DTPA';
      case MetodoExtracao.KCL:
        return 'KCl';
      case MetodoExtracao.AGUA_QUENTE:
        return S.of(context).hot_water;
    }
  }
}

// Adição ao arquivo enums.dart
enum TipoMovimentacaoFinanceira {
  CREDITO,
  DEBITO;

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case TipoMovimentacaoFinanceira.CREDITO:
        return S.of(context).credit;
      case TipoMovimentacaoFinanceira.DEBITO:
        return S.of(context).debit;
    }
  }

  static TipoMovimentacaoFinanceira fromString(String value) {
    return TipoMovimentacaoFinanceira.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == value.toUpperCase(),
      orElse: () => TipoMovimentacaoFinanceira.CREDITO,
    );
  }
}

enum CategoriaMovimentacaoFinanceira {
  // Entradas
  VENDA,
  RECEBIMENTO,
  TRANSFERENCIA_ENTRADA,
  ESTORNO_SAIDA,
  EMPRESTIMO,
  INVESTIMENTO,
  OUTRAS_ENTRADAS,

  // Saídas
  COMPRA,
  PAGAMENTO,
  TRANSFERENCIA_SAIDA,
  ESTORNO_ENTRADA,
  DEVOLUCAO_EMPRESTIMO,
  RESGATE_DINHEIRO,
  OUTRAS_SAIDAS;

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case CategoriaMovimentacaoFinanceira.VENDA:
        return S.of(context).sale;
      case CategoriaMovimentacaoFinanceira.RECEBIMENTO:
        return S.of(context).receivement;
      case CategoriaMovimentacaoFinanceira.TRANSFERENCIA_ENTRADA:
        return S.of(context).transfer_in;
      case CategoriaMovimentacaoFinanceira.ESTORNO_SAIDA:
        return S.of(context).outflow_reversal;
      case CategoriaMovimentacaoFinanceira.EMPRESTIMO:
        return S.of(context).loan;
      case CategoriaMovimentacaoFinanceira.INVESTIMENTO:
        return S.of(context).investment;
      case CategoriaMovimentacaoFinanceira.OUTRAS_ENTRADAS:
        return S.of(context).other_inflows;
      case CategoriaMovimentacaoFinanceira.COMPRA:
        return S.of(context).purchase;
      case CategoriaMovimentacaoFinanceira.PAGAMENTO:
        return S.of(context).payment;
      case CategoriaMovimentacaoFinanceira.TRANSFERENCIA_SAIDA:
        return S.of(context).transfer_out;
      case CategoriaMovimentacaoFinanceira.ESTORNO_ENTRADA:
        return S.of(context).inflow_reversal;
      case CategoriaMovimentacaoFinanceira.DEVOLUCAO_EMPRESTIMO:
        return S.of(context).loan_repayment;
      case CategoriaMovimentacaoFinanceira.RESGATE_DINHEIRO:
        return S.of(context).money_withdrawal;
      case CategoriaMovimentacaoFinanceira.OUTRAS_SAIDAS:
        return S.of(context).other_outflows;
    }
  }

  bool get isCredito {
    return [
      VENDA,
      RECEBIMENTO,
      TRANSFERENCIA_ENTRADA,
      ESTORNO_SAIDA,
      EMPRESTIMO,
      INVESTIMENTO,
      OUTRAS_ENTRADAS
    ].contains(this);
  }

  bool get isDebito {
    return !isCredito;
  }

  bool get isEstorno {
    return this == ESTORNO_ENTRADA || this == ESTORNO_SAIDA;
  }

  bool get isTransferencia {
    return this == TRANSFERENCIA_ENTRADA || this == TRANSFERENCIA_SAIDA;
  }

  static CategoriaMovimentacaoFinanceira fromString(String value) {
    return CategoriaMovimentacaoFinanceira.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == value.toUpperCase(),
      orElse: () => CategoriaMovimentacaoFinanceira.OUTRAS_SAIDAS,
    );
  }
}

enum ListenerState {
  IDLE,
  INITIALIZING,
  ACTIVE,
  STOPPING
}

enum InterpretacaoNutriente {
  MUITO_BAIXO,
  BAIXO,
  MEDIO,
  ADEQUADO,
  ALTO,
  MUITO_ALTO;

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case InterpretacaoNutriente.MUITO_BAIXO:
        return S.of(context).very_low;
      case InterpretacaoNutriente.BAIXO:
        return S.of(context).low;
      case InterpretacaoNutriente.MEDIO:
        return S.of(context).medium;
      case InterpretacaoNutriente.ADEQUADO:
        return S.of(context).adequate;
      case InterpretacaoNutriente.ALTO:
        return S.of(context).high;
      case InterpretacaoNutriente.MUITO_ALTO:
        return S.of(context).very_high;
    }
  }

  static InterpretacaoNutriente fromString(String value) {
    return InterpretacaoNutriente.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == value.toUpperCase(),
      orElse: () => InterpretacaoNutriente.MEDIO,
    );
  }
}

// Definição do enum
enum FaseAplicacao {
  N_PLANT, N_COB1, N_COB2,
  P_PLANT,
  K_PLANT, K_COB1,
  S_PLANT, S_PRE,
  MICRO_PLANT;

  // Método para obter um FaseAplicacao a partir de uma string
  static FaseAplicacao fromString(String value) {
    try {
      return FaseAplicacao.values.firstWhere(
              (e) => e.toString().split('.').last == value,
          orElse: () => FaseAplicacao.N_PLANT // valor padrão
      );
    } catch (e) {
      print('Erro ao converter string para FaseAplicacao: $e');
      return FaseAplicacao.N_PLANT;
    }
  }

  // Retorna a chave de tradução para esta fase
  String get translationKey {
    switch (this) {
      case FaseAplicacao.N_PLANT: return 'planting';
      case FaseAplicacao.N_COB1: return 'coverage_1';
      case FaseAplicacao.N_COB2: return 'coverage_2';
      case FaseAplicacao.P_PLANT: return 'planting_total';
      case FaseAplicacao.K_PLANT: return 'planting_partial';
      case FaseAplicacao.K_COB1: return 'coverage_1_remaining';
      case FaseAplicacao.S_PLANT: return 'planting';
      case FaseAplicacao.S_PRE: return 'pre_planting';
      case FaseAplicacao.MICRO_PLANT: return 'planting_micro';
    }
  }

  // Obtém a descrição traduzida usando o contexto
  String getLocalizedName(BuildContext context) {
    // Aqui você usaria o acesso ao S.of(context)
    // Supondo que exista um método para cada chave de tradução
    switch (this) {
      case FaseAplicacao.N_PLANT: return S.of(context).planting;
      case FaseAplicacao.N_COB1: return S.of(context).coverage_1;
      case FaseAplicacao.N_COB2: return S.of(context).coverage_2;
      case FaseAplicacao.P_PLANT: return S.of(context).planting_total;
      case FaseAplicacao.K_PLANT: return S.of(context).planting_partial;
      case FaseAplicacao.K_COB1: return S.of(context).coverage_1_remaining;
      case FaseAplicacao.S_PLANT: return S.of(context).planting;
      case FaseAplicacao.S_PRE: return S.of(context).pre_planting;
      case FaseAplicacao.MICRO_PLANT: return S.of(context).planting_micro;
    }
  }

  // Alternativa que usa os dados nos parâmetros da cultura
  String getDescriptionFromParams(Map<String, Map<String, dynamic>> epocasAplicacao) {
    final String key = toString().split('.').last;
    if (epocasAplicacao.containsKey(key)) {
      return epocasAplicacao[key]!['descricao'] as String;
    }
    return key;
  }
}
/// Enum defining standardized application modes.
enum ModoAplicacao {
  SULCO_PLANTIO,
  LANCO_COBERTURA,
  LANCO_PRE_PLANTIO,
  INCORPORADO,
  FOLIAR,
  NAO_ESPECIFICADO; // Default/fallback value

  /// Gets a human-readable description for the application mode.
  /// This can be used for display purposes if needed.
  String get descricao {
    // Note: Consider using localization here as well if these descriptions are user-facing
    switch (this) {
      case ModoAplicacao.SULCO_PLANTIO:
        return 'Sulco de plantio';
      case ModoAplicacao.LANCO_COBERTURA:
        return 'Lanço em cobertura';
      case ModoAplicacao.LANCO_PRE_PLANTIO:
        return 'Lanço em pré-plantio';
      case ModoAplicacao.INCORPORADO:
        return 'Incorporado';
      case ModoAplicacao.FOLIAR:
        return 'Aplicação foliar';
      case ModoAplicacao.NAO_ESPECIFICADO:
      default: // Added default for safety
        return 'Não especificado';
    }
  }

  /// Parses a string to find the corresponding [ModoAplicacao].
  /// Case-insensitive matching against enum names.
  /// Includes basic keyword matching as a fallback.
  static ModoAplicacao fromString(String? texto) {
    if (texto == null || texto.isEmpty) {
      return ModoAplicacao.NAO_ESPECIFICADO;
    }
    final upperValue = texto.toUpperCase().trim();

    // Primary matching: Enum name (like CULTURA does)
    for (var modo in ModoAplicacao.values) {
      if (modo.name == upperValue) { // .name gives the enum identifier string (e.g., "SULCO_PLANTIO")
        return modo;
      }
    }

    // Secondary matching: Keywords (like the original inference logic)
    // This provides some flexibility if the stored string isn't the exact enum name
    final lowerValue = texto.toLowerCase().trim();
    if (lowerValue.contains('sulco')) return ModoAplicacao.SULCO_PLANTIO;
    if (lowerValue.contains('lanço') || lowerValue.contains('lanco')) {
      if (lowerValue.contains('pré') || lowerValue.contains('pre') || lowerValue.contains('pré-plantio')) {
        return ModoAplicacao.LANCO_PRE_PLANTIO;
      }
      if (lowerValue.contains('cobertura')) {
        return ModoAplicacao.LANCO_COBERTURA;
      }
      return ModoAplicacao.LANCO_COBERTURA; // Default lanço type if context missing
    }
    if (lowerValue.contains('incorporado')) return ModoAplicacao.INCORPORADO;
    if (lowerValue.contains('foliar')) return ModoAplicacao.FOLIAR;
    if (lowerValue.contains('plantio')) return ModoAplicacao.SULCO_PLANTIO; // Assume plantio -> sulco
    if (lowerValue.contains('cobertura')) return ModoAplicacao.LANCO_COBERTURA; // Assume cobertura -> lanço


    // Final fallback if no match
    print("Aviso: Não foi possível parsear '$texto' para ModoAplicacao. Usando NAO_ESPECIFICADO.");
    return ModoAplicacao.NAO_ESPECIFICADO;
  }

  // Optional: If you need localized names similar to other enums
  String getLocalizedName(BuildContext context) {
    // Example - Adapt keys to your actual localization file (S.of(context).*)
    switch (this) {
      case ModoAplicacao.SULCO_PLANTIO: return S.of(context).planting_furrow; // Example key
      case ModoAplicacao.LANCO_COBERTURA: return S.of(context).broadcast_topdressing; // Example key
      case ModoAplicacao.LANCO_PRE_PLANTIO: return S.of(context).broadcast_pre_planting; // Example key
      case ModoAplicacao.INCORPORADO: return S.of(context).incorporated; // Example key
      case ModoAplicacao.FOLIAR: return S.of(context).foliar_application; // Example key
      case ModoAplicacao.NAO_ESPECIFICADO: return S.of(context).unspecified; // Example key
      default: return S.of(context).unspecified;
    }
  }
}

/// Enum defining standardized codes for application epochs (optional).
enum CodigoEpoca {
  PLANTIO,
  PRE_PLANTIO,
  COBERTURA_1,
  COBERTURA_2,
  COBERTURA_3;

  /// Gets the standardized code string for the epoch.
  String get codigo {
    switch (this) {
      case CodigoEpoca.PLANTIO:
        return 'PLANT';
      case CodigoEpoca.PRE_PLANTIO:
        return 'PRE';
      case CodigoEpoca.COBERTURA_1:
        return 'COB1';
      case CodigoEpoca.COBERTURA_2:
        return 'COB2';
      case CodigoEpoca.COBERTURA_3:
      default: // Added default for safety
        return 'COB3';
    }
  }

  /// Parses a string code to find the corresponding [CodigoEpoca].
  static CodigoEpoca? fromCodigo(String? codigo) {
    if (codigo == null) return null;
    final upperCodigo = codigo.toUpperCase().trim();
    for (var epoca in CodigoEpoca.values) {
      if (epoca.codigo == upperCodigo || epoca.name == upperCodigo) { // Check code and name
        return epoca;
      }
    }
    return null; // Return null if no match found
  }

  // Optional: Localized names if needed
  String getLocalizedName(BuildContext context) {
    // Example - Adapt keys
    switch (this) {
      case CodigoEpoca.PLANTIO: return S.of(context).planting_epoch; // Example key
      case CodigoEpoca.PRE_PLANTIO: return S.of(context).pre_planting_epoch; // Example key
      case CodigoEpoca.COBERTURA_1: return S.of(context).coverage_1_epoch; // Example key
      case CodigoEpoca.COBERTURA_2: return S.of(context).coverage_2_epoch; // Example key
      case CodigoEpoca.COBERTURA_3: return S.of(context).coverage_3_epoch; // Example key
      default: return S.of(context).unknown_epoch; // Example key
    }
  }
}