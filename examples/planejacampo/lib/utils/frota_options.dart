import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class FrotaOptions {
  static const List<String> tiposFrota = [
    'Carro',
    'Caminhonete',
    'Caminhão',
    'Trator',
    'Colheitadeira',
    'Pulverizador Autopropelido',
    'Adubador Autopropelido',
    'Outro',
  ];

  static Map<String, String> getLocalizedTiposFrota(BuildContext context) {
    return {
      'Carro': S.of(context).car,
      'Caminhonete': S.of(context).pickup_truck,
      'Caminhão': S.of(context).truck,
      'Trator': S.of(context).tractor,
      'Colheitadeira': S.of(context).harvester,
      'Pulverizador Autopropelido': S.of(context).self_propelled_sprayer,
      'Adubador Autopropelido': S.of(context).self_propelled_fertilizer,
      'Outro': S.of(context).other,
    };
  }

  static List<String> getLocalizedTiposFrotaString(BuildContext context) {
    return getLocalizedTiposFrota(context).values.toList();
  }
}
