// estados_options.dart
import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class EstadosOptions {
  // Lista de países com nome e sigla
  static const List<Map<String, String>> paises = [
    {'nome': 'Brasil', 'sigla': 'BR'},
    {'nome': 'Estados Unidos', 'sigla': 'US'},
  ];

  // Lista de estados com sigla do país, sigla do estado e nome do estado
  static const List<Map<String, String>> estados = [
    // Estados do Brasil
    {'paisSigla': 'BR', 'estadoSigla': 'AC', 'nome': 'Acre'},
    {'paisSigla': 'BR', 'estadoSigla': 'AL', 'nome': 'Alagoas'},
    {'paisSigla': 'BR', 'estadoSigla': 'AP', 'nome': 'Amapá'},
    {'paisSigla': 'BR', 'estadoSigla': 'AM', 'nome': 'Amazonas'},
    {'paisSigla': 'BR', 'estadoSigla': 'BA', 'nome': 'Bahia'},
    {'paisSigla': 'BR', 'estadoSigla': 'CE', 'nome': 'Ceará'},
    {'paisSigla': 'BR', 'estadoSigla': 'DF', 'nome': 'Distrito Federal'},
    {'paisSigla': 'BR', 'estadoSigla': 'ES', 'nome': 'Espírito Santo'},
    {'paisSigla': 'BR', 'estadoSigla': 'GO', 'nome': 'Goiás'},
    {'paisSigla': 'BR', 'estadoSigla': 'MA', 'nome': 'Maranhão'},
    {'paisSigla': 'BR', 'estadoSigla': 'MT', 'nome': 'Mato Grosso'},
    {'paisSigla': 'BR', 'estadoSigla': 'MS', 'nome': 'Mato Grosso do Sul'},
    {'paisSigla': 'BR', 'estadoSigla': 'MG', 'nome': 'Minas Gerais'},
    {'paisSigla': 'BR', 'estadoSigla': 'PA', 'nome': 'Pará'},
    {'paisSigla': 'BR', 'estadoSigla': 'PB', 'nome': 'Paraíba'},
    {'paisSigla': 'BR', 'estadoSigla': 'PR', 'nome': 'Paraná'},
    {'paisSigla': 'BR', 'estadoSigla': 'PE', 'nome': 'Pernambuco'},
    {'paisSigla': 'BR', 'estadoSigla': 'PI', 'nome': 'Piauí'},
    {'paisSigla': 'BR', 'estadoSigla': 'RJ', 'nome': 'Rio de Janeiro'},
    {'paisSigla': 'BR', 'estadoSigla': 'RN', 'nome': 'Rio Grande do Norte'},
    {'paisSigla': 'BR', 'estadoSigla': 'RS', 'nome': 'Rio Grande do Sul'},
    {'paisSigla': 'BR', 'estadoSigla': 'RO', 'nome': 'Rondônia'},
    {'paisSigla': 'BR', 'estadoSigla': 'RR', 'nome': 'Roraima'},
    {'paisSigla': 'BR', 'estadoSigla': 'SC', 'nome': 'Santa Catarina'},
    {'paisSigla': 'BR', 'estadoSigla': 'SP', 'nome': 'São Paulo'},
    {'paisSigla': 'BR', 'estadoSigla': 'SE', 'nome': 'Sergipe'},
    {'paisSigla': 'BR', 'estadoSigla': 'TO', 'nome': 'Tocantins'},

    // Estados dos Estados Unidos
    {'paisSigla': 'US', 'estadoSigla': 'AL', 'nome': 'Alabama'},
    {'paisSigla': 'US', 'estadoSigla': 'AK', 'nome': 'Alaska'},
    {'paisSigla': 'US', 'estadoSigla': 'AZ', 'nome': 'Arizona'},
    {'paisSigla': 'US', 'estadoSigla': 'AR', 'nome': 'Arkansas'},
    {'paisSigla': 'US', 'estadoSigla': 'CA', 'nome': 'California'},
    {'paisSigla': 'US', 'estadoSigla': 'CO', 'nome': 'Colorado'},
    {'paisSigla': 'US', 'estadoSigla': 'CT', 'nome': 'Connecticut'},
    {'paisSigla': 'US', 'estadoSigla': 'DE', 'nome': 'Delaware'},
    {'paisSigla': 'US', 'estadoSigla': 'FL', 'nome': 'Florida'},
    {'paisSigla': 'US', 'estadoSigla': 'GA', 'nome': 'Georgia'},
    {'paisSigla': 'US', 'estadoSigla': 'HI', 'nome': 'Hawaii'},
    {'paisSigla': 'US', 'estadoSigla': 'ID', 'nome': 'Idaho'},
    {'paisSigla': 'US', 'estadoSigla': 'IL', 'nome': 'Illinois'},
    {'paisSigla': 'US', 'estadoSigla': 'IN', 'nome': 'Indiana'},
    {'paisSigla': 'US', 'estadoSigla': 'IA', 'nome': 'Iowa'},
    {'paisSigla': 'US', 'estadoSigla': 'KS', 'nome': 'Kansas'},
    {'paisSigla': 'US', 'estadoSigla': 'KY', 'nome': 'Kentucky'},
    {'paisSigla': 'US', 'estadoSigla': 'LA', 'nome': 'Louisiana'},
    {'paisSigla': 'US', 'estadoSigla': 'ME', 'nome': 'Maine'},
    {'paisSigla': 'US', 'estadoSigla': 'MD', 'nome': 'Maryland'},
    {'paisSigla': 'US', 'estadoSigla': 'MA', 'nome': 'Massachusetts'},
    {'paisSigla': 'US', 'estadoSigla': 'MI', 'nome': 'Michigan'},
    {'paisSigla': 'US', 'estadoSigla': 'MN', 'nome': 'Minnesota'},
    {'paisSigla': 'US', 'estadoSigla': 'MS', 'nome': 'Mississippi'},
    {'paisSigla': 'US', 'estadoSigla': 'MO', 'nome': 'Missouri'},
    {'paisSigla': 'US', 'estadoSigla': 'MT', 'nome': 'Montana'},
    {'paisSigla': 'US', 'estadoSigla': 'NE', 'nome': 'Nebraska'},
    {'paisSigla': 'US', 'estadoSigla': 'NV', 'nome': 'Nevada'},
    {'paisSigla': 'US', 'estadoSigla': 'NH', 'nome': 'New Hampshire'},
    {'paisSigla': 'US', 'estadoSigla': 'NJ', 'nome': 'New Jersey'},
    {'paisSigla': 'US', 'estadoSigla': 'NM', 'nome': 'New Mexico'},
    {'paisSigla': 'US', 'estadoSigla': 'NY', 'nome': 'New York'},
    {'paisSigla': 'US', 'estadoSigla': 'NC', 'nome': 'North Carolina'},
    {'paisSigla': 'US', 'estadoSigla': 'ND', 'nome': 'North Dakota'},
    {'paisSigla': 'US', 'estadoSigla': 'OH', 'nome': 'Ohio'},
    {'paisSigla': 'US', 'estadoSigla': 'OK', 'nome': 'Oklahoma'},
    {'paisSigla': 'US', 'estadoSigla': 'OR', 'nome': 'Oregon'},
    {'paisSigla': 'US', 'estadoSigla': 'PA', 'nome': 'Pennsylvania'},
    {'paisSigla': 'US', 'estadoSigla': 'RI', 'nome': 'Rhode Island'},
    {'paisSigla': 'US', 'estadoSigla': 'SC', 'nome': 'South Carolina'},
    {'paisSigla': 'US', 'estadoSigla': 'SD', 'nome': 'South Dakota'},
    {'paisSigla': 'US', 'estadoSigla': 'TN', 'nome': 'Tennessee'},
    {'paisSigla': 'US', 'estadoSigla': 'TX', 'nome': 'Texas'},
    {'paisSigla': 'US', 'estadoSigla': 'UT', 'nome': 'Utah'},
    {'paisSigla': 'US', 'estadoSigla': 'VT', 'nome': 'Vermont'},
    {'paisSigla': 'US', 'estadoSigla': 'VA', 'nome': 'Virginia'},
    {'paisSigla': 'US', 'estadoSigla': 'WA', 'nome': 'Washington'},
    {'paisSigla': 'US', 'estadoSigla': 'WV', 'nome': 'West Virginia'},
    {'paisSigla': 'US', 'estadoSigla': 'WI', 'nome': 'Wisconsin'},
    {'paisSigla': 'US', 'estadoSigla': 'WY', 'nome': 'Wyoming'},
  ];

  // Mapeamento dos nomes dos países para suas siglas localizadas
  static Map<String, String> getLocalizedPaises(BuildContext context) {
    return {
      'Brasil': S.of(context).brazil,
      'Estados Unidos': S.of(context).united_states,
    };
  }

  // Mapeamento das siglas dos estados para seus nomes localizados
  static Map<String, String> getLocalizedEstados(BuildContext context) {
    Map<String, String> estadosMap = {};

    // Estados do Brasil
    estadosMap['AC'] = S.of(context).acre;
    estadosMap['AL'] = S.of(context).alagoas;
    estadosMap['AP'] = S.of(context).amapa;
    estadosMap['AM'] = S.of(context).amazonas;
    estadosMap['BA'] = S.of(context).bahia;
    estadosMap['CE'] = S.of(context).ceara;
    estadosMap['DF'] = S.of(context).distrito_federal;
    estadosMap['ES'] = S.of(context).espirito_santo;
    estadosMap['GO'] = S.of(context).goias;
    estadosMap['MA'] = S.of(context).maranhao;
    estadosMap['MT'] = S.of(context).mato_grosso;
    estadosMap['MS'] = S.of(context).mato_grosso_do_sul;
    estadosMap['MG'] = S.of(context).minas_gerais;
    estadosMap['PA'] = S.of(context).para;
    estadosMap['PB'] = S.of(context).paraiba;
    estadosMap['PR'] = S.of(context).parana;
    estadosMap['PE'] = S.of(context).pernambuco;
    estadosMap['PI'] = S.of(context).piaui;
    estadosMap['RJ'] = S.of(context).rio_de_janeiro;
    estadosMap['RN'] = S.of(context).rio_grande_do_norte;
    estadosMap['RS'] = S.of(context).rio_grande_do_sul;
    estadosMap['RO'] = S.of(context).rondonia;
    estadosMap['RR'] = S.of(context).roraima;
    estadosMap['SC'] = S.of(context).santa_catarina;
    estadosMap['SP'] = S.of(context).sao_paulo;
    estadosMap['SE'] = S.of(context).sergipe;
    estadosMap['TO'] = S.of(context).tocantins;

    // Estados dos Estados Unidos
    estadosMap['AL'] = S.of(context).alabama;
    estadosMap['AK'] = S.of(context).alaska;
    estadosMap['AZ'] = S.of(context).arizona;
    estadosMap['AR'] = S.of(context).arkansas;
    estadosMap['CA'] = S.of(context).california;
    estadosMap['CO'] = S.of(context).colorado;
    estadosMap['CT'] = S.of(context).connecticut;
    estadosMap['DE'] = S.of(context).delaware;
    estadosMap['FL'] = S.of(context).florida;
    estadosMap['GA'] = S.of(context).georgia;
    estadosMap['HI'] = S.of(context).hawaii;
    estadosMap['ID'] = S.of(context).idaho;
    estadosMap['IL'] = S.of(context).illinois;
    estadosMap['IN'] = S.of(context).indiana;
    estadosMap['IA'] = S.of(context).iowa;
    estadosMap['KS'] = S.of(context).kansas;
    estadosMap['KY'] = S.of(context).kentucky;
    estadosMap['LA'] = S.of(context).louisiana;
    estadosMap['ME'] = S.of(context).maine;
    estadosMap['MD'] = S.of(context).maryland;
    estadosMap['MA'] = S.of(context).massachusetts;
    estadosMap['MI'] = S.of(context).michigan;
    estadosMap['MN'] = S.of(context).minnesota;
    estadosMap['MS'] = S.of(context).mississippi;
    estadosMap['MO'] = S.of(context).missouri;
    estadosMap['MT'] = S.of(context).montana;
    estadosMap['NE'] = S.of(context).nebraska;
    estadosMap['NV'] = S.of(context).nevada;
    estadosMap['NH'] = S.of(context).new_hampshire;
    estadosMap['NJ'] = S.of(context).new_jersey;
    estadosMap['NM'] = S.of(context).new_mexico;
    estadosMap['NY'] = S.of(context).new_york;
    estadosMap['NC'] = S.of(context).north_carolina;
    estadosMap['ND'] = S.of(context).north_dakota;
    estadosMap['OH'] = S.of(context).ohio;
    estadosMap['OK'] = S.of(context).oklahoma;
    estadosMap['OR'] = S.of(context).oregon;
    estadosMap['PA'] = S.of(context).pennsylvania;
    estadosMap['RI'] = S.of(context).rhode_island;
    estadosMap['SC'] = S.of(context).south_carolina;
    estadosMap['SD'] = S.of(context).south_dakota;
    estadosMap['TN'] = S.of(context).tennessee;
    estadosMap['TX'] = S.of(context).texas;
    estadosMap['UT'] = S.of(context).utah;
    estadosMap['VT'] = S.of(context).vermont;
    estadosMap['VA'] = S.of(context).virginia;
    estadosMap['WA'] = S.of(context).washington;
    estadosMap['WV'] = S.of(context).west_virginia;
    estadosMap['WI'] = S.of(context).wisconsin;
    estadosMap['WY'] = S.of(context).wyoming;

    return estadosMap;
  }

  // Retorna uma lista de países localizados como Strings
  static List<String> getLocalizedPaisesString(BuildContext context) {
    return getLocalizedPaises(context).values.toList();
  }

  // Retorna uma lista de estados localizados como Strings
  static List<String> getLocalizedEstadosString(BuildContext context) {
    return getLocalizedEstados(context).values.toList();
  }

  // Retorna uma lista de estados filtrados por sigla do país
  static List<Map<String, String>> getEstadosByPais(String paisSigla) {
    return estados.where((estado) => estado['paisSigla'] == paisSigla).toList();
  }

  // Retorna uma lista de siglas dos estados filtrados por sigla do país
  static List<String> getSiglasEstadosByPais(String paisSigla) {
    return estados
        .where((estado) => estado['paisSigla'] == paisSigla)
        .map((estado) => estado['estadoSigla']!)
        .toList();
  }

  // Retorna o nome do estado localizado a partir da sigla
  static String getNomeEstado(BuildContext context, String estadoSigla) {
    return getLocalizedEstados(context)[estadoSigla] ?? estadoSigla;
  }
}
