import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class ProdutorOptions {
  // Tipos de produtores
  static const List<String> tipo = <String>['Pessoa Física', 'Pessoa Jurídica'];

  // Permissões de usuário
  static const List<String> permissoes = <String>['Admin', 'Produtor', 'Gerente', 'Operador', 'Curioso'];

  // Tipos de licenças
  static const List<String> licencas = <String>['Acesso Basico', 'Acesso Completo', 'Licenca Permanente'];

  // Mapeamento dos valores internos para as strings internacionalizadas
  static Map<String, String> getLocalizedTipo(BuildContext context) {
    return {
      'Pessoa Física': S.of(context).individual,
      'Pessoa Jurídica': S.of(context).legal_entity,
    };
  }

  static Map<String, String> getLocalizedStatus(BuildContext context) {
    return {
      'Ativo': S.of(context).active,
      'Inativo': S.of(context).inactive,
    };
  }

  static Map<String, String> getLocalizedPermissoes(BuildContext context) {
    return {
      'Admin': S.of(context).admin,
      'Produtor': S.of(context).producer,
      'Gerente': S.of(context).manager,
      'Operador': S.of(context).operator,
      'Curioso': S.of(context).curious,
    };
  }

  static Map<String, String> getLocalizedLicenca(BuildContext context) {
    return {
      'AcessoBasico': S.of(context).acesso_basico, //AcessoBasico
      'AcessoCompletoPequenoProdutor': S.of(context).acesso_completo_pequeno_produtor,  // AcessoCompletoPequenoProdutor
      'AcessoCompletoMedioProdutor': S.of(context).acesso_completo_medio_produtor,  // AcessoCompletoMedioProdutor
      'AcessoCompletoGrandeProdutor': S.of(context).acesso_completo_grande_produtor,  // AcessoCompletoGrandeProdutor
      'AcessoPermanente': S.of(context).licenca_permanente,  // AcessoPermanente
    };
  }

  // Função auxiliar para retornar lista de permissões internacionalizadas
  static List<String> getLocalizedPermissoesString(BuildContext context) {
    return ProdutorOptions.getLocalizedPermissoes(context).values.toList();
  }

  // Função auxiliar para retornar lista de licenças internacionalizadas
  static List<String> getLocalizedLicencasString(BuildContext context) {
    return ProdutorOptions.getLocalizedLicenca(context).values.toList();
  }
}
