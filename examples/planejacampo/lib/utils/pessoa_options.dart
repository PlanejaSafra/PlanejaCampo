import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class PessoaOptions {
  static const List<String> tipos = ['Pessoa Física', 'Pessoa Jurídica'];
  static const List<String> vinculos = ['Diversos', 'Cliente', 'Fornecedor', 'Funcionário', 'Parceiro'];

  // Mapeamento dos valores internos para as strings internacionalizadas
  static Map<String, String> getLocalizedTipos(BuildContext context) {
    return {
      'Pessoa Física': S.of(context).individual,
      'Pessoa Jurídica': S.of(context).legal_entity,
    };
  }

  static Map<String, String> getLocalizedVinculos(BuildContext context) {
    return {
      'Diversos': S.of(context).various,
      'Cliente': S.of(context).client,
      'Fornecedor': S.of(context).supplier,
      'Funcionario': S.of(context).employee,
      'Parceiro': S.of(context).partner,
    };
  }
}