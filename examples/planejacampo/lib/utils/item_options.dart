import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class ItemOptions {
  static const List<String> tipos = [
    'Animal',
    'Diversos',
    'Equipamento',
    'Imóvel',
    'Insumo',
    'Maquinário',
    'Produto',
    'Serviço',
    'Veículo',
  ];

  static const List<String> categorias = [
    'Animais',
    'Combustível',
    'Defensivos Agrícolas',
    'Diversos',
    'Embalagens',
    'Fertilizante',
    'Ferragens',
    'Ferramentas',
    'Fruto',
    'Grão',
    'Implementos Agrícolas',
    'Lubrificantes e Óleos',
    'Maquinário',
    'Material de Construção',
    'Medicamento Veterinário',
    'Mudas',
    'Peças de Reposição',
    'Produtos de Higiene e Limpeza',
    'Produtos Veterinários',
    'Ração',
    'Semente',
    'Serviços',
  ];

  static const List<String> unidadesMedida = [
    'Alqueire (alq)',
    'Arroba (@)',
    'Caixa (cx)',
    'Centímetro (cm)',
    'Centímetro cúbico (cm³)',
    'Dia (d)',
    'Dúzia (dz)',
    'Fardo (fd)',
    'Grama (g)',
    'Hectare (ha)',
    'Hora (h)',
    'Litro (L)',
    'Metro (m)',
    'Metro cúbico (m³)',
    'Metro quadrado (m²)',
    'Miligrama (mg)',
    'Mililitro (mL)',
    'Milímetro (mm)',
    'Minuto (min)',
    'Pacote (pct)',
    'Peça (pc)',
    'Quilograma (kg)',
    'Quilômetro (km)',
    'Saco 20kg (sc20kg)',
    'Saco 25kg (sc25kg)',
    'Saco 30kg (sc30kg)',
    'Saco 40kg (sc40kg)',
    'Saco 50kg (sc50kg)',
    'Saco 60kg (sc60kg)',
    'Tonelada (t)',
    'Unidade (un)',
  ];

  // Mapeamento dos valores internos para as strings internacionalizadas
  static Map<String, String> getLocalizedTipos(BuildContext context) {
    return {
      'Animal': S.of(context).animal,
      'Diversos': S.of(context).various,
      'Equipamento': S.of(context).equipment,
      'Imóvel': S.of(context).real_estate,
      'Insumo': S.of(context).input,
      'Maquinário': S.of(context).machinery,
      'Produto': S.of(context).product,
      'Serviço': S.of(context).service,
      'Veículo': S.of(context).vehicle,
    };
  }

  static Map<String, String> getLocalizedCategorias(BuildContext context) {
    return {
      'Animais': S.of(context).animals,
      'Combustível': S.of(context).fuel,
      'Defensivos Agrícolas': S.of(context).agricultural_chemicals,
      'Diversos': S.of(context).various,
      'Embalagens': S.of(context).packaging,
      'Fertilizante': S.of(context).fertilizer,
      'Ferragens': S.of(context).hardware,
      'Ferramentas': S.of(context).tools,
      'Fruto': S.of(context).fruit,
      'Grão': S.of(context).grain,
      'Implementos Agrícolas': S.of(context).agricultural_implements,
      'Lubrificantes e Óleos': S.of(context).lubricants_and_oils,
      'Maquinário': S.of(context).machinery,
      'Material de Construção': S.of(context).building_materials,
      'Medicamento Veterinário': S.of(context).veterinary_medicine,
      'Mudas': S.of(context).seedlings,
      'Peças de Reposição': S.of(context).replacement_parts,
      'Produtos de Higiene e Limpeza': S.of(context).hygiene_and_cleaning_products,
      'Produtos Veterinários': S.of(context).veterinary_products,
      'Ração': S.of(context).feed,
      'Semente': S.of(context).seed,
      'Serviços': S.of(context).services,
    };
  }

  static Map<String, String> getLocalizedUnidadesMedida(BuildContext context) {
    return {
      'Alqueire (alq)': S.of(context).alqueire,
      'Arroba (@)': S.of(context).arroba,
      'Caixa (cx)': S.of(context).box,
      'Centímetro (cm)': S.of(context).centimeter,
      'Centímetro cúbico (cm³)': S.of(context).cubic_centimeter,
      'Dia (d)': S.of(context).day,
      'Dúzia (dz)': S.of(context).dozen,
      'Fardo (fd)': S.of(context).bale,
      'Grama (g)': S.of(context).gram,
      'Hectare (ha)': S.of(context).hectare,
      'Hora (h)': S.of(context).hour,
      'Litro (L)': S.of(context).liter,
      'Metro (m)': S.of(context).meter,
      'Metro cúbico (m³)': S.of(context).cubic_meter,
      'Metro quadrado (m²)': S.of(context).square_meter,
      'Miligrama (mg)': S.of(context).milligram,
      'Mililitro (mL)': S.of(context).milliliter,
      'Milímetro (mm)': S.of(context).millimeter,
      'Minuto (min)': S.of(context).minute,
      'Pacote (pct)': S.of(context).package,
      'Peça (pc)': S.of(context).piece,
      'Quilograma (kg)': S.of(context).kilogram,
      'Quilômetro (km)': S.of(context).kilometer,
      'Saco 20kg (sc20kg)': S.of(context).bag_20kg,
      'Saco 25kg (sc25kg)': S.of(context).bag_25kg,
      'Saco 30kg (sc30kg)': S.of(context).bag_30kg,
      'Saco 40kg (sc40kg)': S.of(context).bag_40kg,
      'Saco 50kg (sc50kg)': S.of(context).bag_50kg,
      'Saco 60kg (sc60kg)': S.of(context).bag_60kg,
      'Tonelada (t)': S.of(context).ton,
      'Unidade (un)': S.of(context).unit,
    };
  }

  // Retorna uma lista de tipos localizados como Strings
  static List<String> getLocalizedTiposString(BuildContext context) {
    return getLocalizedTipos(context).values.toList();
  }

  // Retorna uma lista de categorias localizadas como Strings
  static List<String> getLocalizedCategoriasString(BuildContext context) {
    return getLocalizedCategorias(context).values.toList();
  }

  // Retorna uma lista de unidades de medida localizadas como Strings
  static List<String> getLocalizedUnidadesMedidaString(BuildContext context) {
    return getLocalizedUnidadesMedida(context).values.toList();
  }

  // Método para obter apenas a abreviação (o que está entre parênteses)
  static Map<String, String> getLocalizedUnidadesMedidaAbreviada(BuildContext context) {
    final Map<String, String> unidades = getLocalizedUnidadesMedida(context);
    return unidades.map((key, value) {
      final abreviacao = RegExp(r'\((.*?)\)').firstMatch(key)?.group(1) ?? '';
      return MapEntry(key, abreviacao);
    });
  }

  // Retorna uma lista de unidades de medida abreviadas como Strings
  static List<String> getLocalizedUnidadesMedidaAbreviadaString(BuildContext context) {
    return getLocalizedUnidadesMedidaAbreviada(context).values.toList();
  }
}
