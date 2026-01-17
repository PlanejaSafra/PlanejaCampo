import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class AtividadeRuralOptions {
  static const List<String> tiposAtividade = [
    'Agricultura',
    'Pecuária',
    'Avicultura',
    'Suinocultura',
    'Silvicultura',
    'Aquicultura',
    'Apicultura',
    'Outros',
  ];

  static const Map<String, List<String>> subtiposAtividades = {
    'Agricultura': ['Milho', 'Soja', 'Feijão', 'Trigo', 'Cana-de-Açúcar', 'Arroz', 'Sorgo', 'Algodão', 'Fruticultura', 'Hortaliças', 'Outros'],
    'Pecuária': ['Bovinos de Corte', 'Bovinos de Leite', 'Caprinos', 'Ovinos', 'Outros'],
    'Avicultura': ['Frango de Corte', 'Produção de Ovos', 'Frango Caipira', 'Outros'],
    'Suinocultura': ['Suínos para Corte', 'Recria de Suínos', 'Outros'],
    'Silvicultura': ['Seringueira', 'Eucalipto', 'Mogno', 'Outros'],
    'Aquicultura': ['Tilápia', 'Tambaqui', 'Pirarucu', 'Outros'],
    'Apicultura': ['Produção de Mel', 'Produção de Própolis', 'Outros'],
    'Outros': ['Outros'],
  };

  static Map<String, String> getLocalizedTiposAtividades(BuildContext context) {
    return {
      'Agricultura': S.of(context).agriculture,
      'Pecuária': S.of(context).cattle_rearing,
      'Avicultura': S.of(context).poultry_farming,
      'Suinocultura': S.of(context).swine_farming,
      'Silvicultura': S.of(context).forestry,
      'Aquicultura': S.of(context).aquaculture,
      'Apicultura': S.of(context).beekeeping,
      'Outros': S.of(context).other_activities,
    };
  }

  static List<String> getLocalizedTiposAtividadesString(BuildContext context) {
    return getLocalizedTiposAtividades(context).values.toList();
  }

  static List<String> getSubtipos(String tipo) {
    return subtiposAtividades[tipo] ?? [];
  }

  static Map<String, List<String>> getLocalizedSubtiposAtividades(BuildContext context) {
    return {
      'Agricultura': [
        S.of(context).corn, S.of(context).soy, S.of(context).beans, S.of(context).wheat,
        S.of(context).sugar_cane, S.of(context).rice, S.of(context).sorghum, S.of(context).cotton,
        S.of(context).fruits, S.of(context).vegetables, S.of(context).other
      ],
      'Pecuária': [
        S.of(context).beef_cattle, S.of(context).dairy_cattle, S.of(context).goats, S.of(context).sheep, S.of(context).other
      ],
      'Avicultura': [
        S.of(context).broiler_chickens, S.of(context).egg_production, S.of(context).free_range_chickens, S.of(context).other
      ],
      'Suinocultura': [
        S.of(context).swine_for_slaughter, S.of(context).swine_rearing, S.of(context).other
      ],
      'Silvicultura': [
        S.of(context).rubber_tree, S.of(context).eucalyptus, S.of(context).mahogany, S.of(context).other
      ],
      'Aquicultura': [
        S.of(context).tilapia, S.of(context).tambaqui, S.of(context).pirarucu, S.of(context).other
      ],
      'Apicultura': [
        S.of(context).honey_production, S.of(context).propolis_production, S.of(context).other
      ],
      'Outros': [
        S.of(context).other
      ],
    };
  }

  static List<String> getLocalizedSubtiposString(BuildContext context, String tipo) {
    return getLocalizedSubtiposAtividades(context)[tipo] ?? [];
  }
}
