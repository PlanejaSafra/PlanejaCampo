// lib/services/agro/adubacao/calculators/calculador_parcelamento.dart

import 'package:planejacampo/models/enums.dart';

class CalculadorParcelamento {
  /// Calcula as parcelas de aplicação para um nutriente específico.
  /// Retorna um mapa onde a chave é a época de aplicação e o valor é a dose a ser aplicada nessa época.
  Map<String, double> calcularParcelas(
      String nutriente,
      double doseTotal,
      bool irrigado,
      TexturaSolo texturaSolo
      ) {
    Map<String, double> parcelas = {};

    // Definição das regras de parcelamento com base no nutriente
    switch (nutriente) {
      case 'N':
        if (irrigado) {
          // Parcelar em 3 aplicações para áreas irrigadas
          parcelas = {
            'Plantio': doseTotal * 0.4,
            'Cobertura1': doseTotal * 0.3,
            'Cobertura2': doseTotal * 0.3,
          };
        } else {
          // Parcelar em 2 aplicações para áreas não irrigadas
          parcelas = {
            'Plantio': doseTotal * 0.6,
            'Cobertura': doseTotal * 0.4,
          };
        }
        break;

      case 'P2O5':
      // Geralmente, P é aplicado totalmente no plantio
        parcelas = {
          'Plantio': doseTotal,
        };
        break;

      case 'K2O':
        if (texturaSolo == TexturaSolo.ARENOSO) {
          // Parcelar em 3 aplicações para solos arenosos
          parcelas = {
            'Plantio': doseTotal * 0.3,
            'Cobertura1': doseTotal * 0.4,
            'Cobertura2': doseTotal * 0.3,
          };
        } else {
          // Parcelar em 2 aplicações para outros tipos de solo
          parcelas = {
            'Plantio': doseTotal * 0.5,
            'Cobertura': doseTotal * 0.5,
          };
        }
        break;

    // Micronutrientes geralmente são aplicados totalmente no plantio
      default:
        parcelas = {
          'Plantio': doseTotal,
        };
        break;
    }

    return parcelas;
  }

  /// Gera observações relacionadas ao parcelamento das doses.
  /// Pode ser expandido para fornecer recomendações mais detalhadas.
  List<String> gerarObservacoesParcelamento() {
    return [
      'Parcelar as doses para otimizar a absorção e minimizar perdas.',
      'Evitar aplicar todas as doses de uma só vez.',
      'Considere as condições de irrigação e textura do solo ao parcelar as doses.',
    ];
  }
}
