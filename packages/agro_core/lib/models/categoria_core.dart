import 'package:flutter/material.dart';

/// Identificadores imutáveis para categorias core.
/// Usados por outros apps para encontrar categorias independente do nome (via coreKey).
/// NUNCA alterar os nomes dos enums - são contratos cross-app.
enum CategoriaCore {
  // Despesas Agrícolas
  maoDeObra,        // Mão de obra, colheita, diaristas
  adubo,            // Fertilizantes, NPK, calcário
  defensivos,       // Pesticidas, herbicidas, fungicidas
  combustivel,      // Diesel, gasolina (cross-app: RuraFuel)
  manutencao,       // Reparos, peças, mecânico
  energia,          // Luz, água, energia elétrica
  outrosAgro,       // Despesas agrícolas diversas

  // Despesas Pessoais
  alimentacao,      // Supermercado, feira, restaurante
  transporte,       // Combustível pessoal, uber, ônibus
  saude,            // Farmácia, médico, plano de saúde
  educacao,         // Escola, cursos, material
  lazer,            // Viagens, entretenimento, streaming
  moradia,          // Aluguel, condomínio, IPTU
  outrosPessoal,    // Despesas pessoais diversas
}

extension CategoriaCoreExtension on CategoriaCore {
  /// Chave única para busca cross-app (ex: 'combustivel', 'maoDeObra')
  String get key => name;

  /// Nome padrão (fallback em inglês/português genérico se l10n falhar)
  String get defaultNome {
    switch (this) {
      case CategoriaCore.maoDeObra: return 'Mão de Obra';
      case CategoriaCore.adubo: return 'Adubos';
      case CategoriaCore.defensivos: return 'Defensivos';
      case CategoriaCore.combustivel: return 'Combustível';
      case CategoriaCore.manutencao: return 'Manutenção';
      case CategoriaCore.energia: return 'Energia';
      case CategoriaCore.outrosAgro: return 'Outros (Agro)';
      case CategoriaCore.alimentacao: return 'Alimentação';
      case CategoriaCore.transporte: return 'Transporte';
      case CategoriaCore.saude: return 'Saúde';
      case CategoriaCore.educacao: return 'Educação';
      case CategoriaCore.lazer: return 'Lazer';
      case CategoriaCore.moradia: return 'Moradia';
      case CategoriaCore.outrosPessoal: return 'Outros (Pessoal)';
    }
  }

  /// Nome do ícone Material (ex: 'local_gas_station')
  String get defaultIcone {
    switch (this) {
      case CategoriaCore.maoDeObra: return 'people';
      case CategoriaCore.adubo: return 'spa'; // ou grass
      case CategoriaCore.defensivos: return 'pest_control'; // ou bug_report
      case CategoriaCore.combustivel: return 'local_gas_station';
      case CategoriaCore.manutencao: return 'build';
      case CategoriaCore.energia: return 'bolt';
      case CategoriaCore.outrosAgro: return 'agriculture';
      case CategoriaCore.alimentacao: return 'restaurant';
      case CategoriaCore.transporte: return 'directions_car';
      case CategoriaCore.saude: return 'medical_services'; // ou local_hospital
      case CategoriaCore.educacao: return 'school';
      case CategoriaCore.lazer: return 'pool'; // ou beach_access
      case CategoriaCore.moradia: return 'home';
      case CategoriaCore.outrosPessoal: return 'more_horiz';
    }
  }

  /// Valor da cor padrão (int)
  int get defaultCorValue {
    switch (this) {
      // Cores Agrícolas (Tons terrosos/verdes/industriais)
      case CategoriaCore.maoDeObra: return 0xFF795548; // Brown
      case CategoriaCore.adubo: return 0xFF4CAF50; // Green
      case CategoriaCore.defensivos: return 0xFFFBC02D; // Yellow 700 (warning)
      case CategoriaCore.combustivel: return 0xFFF44336; // Red (danger/cost)
      case CategoriaCore.manutencao: return 0xFF607D8B; // Blue Grey (metal)
      case CategoriaCore.energia: return 0xFFFF9800; // Orange
      case CategoriaCore.outrosAgro: return 0xFF9E9E9E; // Grey

      // Cores Pessoais (Mais vibrantes/variadas)
      case CategoriaCore.alimentacao: return 0xFFE91E63; // Pink (food apps usually red/orange/pink)
      case CategoriaCore.transporte: return 0xFF2196F3; // Blue
      case CategoriaCore.saude: return 0xFF00BCD4; // Cyan (cleanliness)
      case CategoriaCore.educacao: return 0xFF3F51B5; // Indigo
      case CategoriaCore.lazer: return 0xFF9C27B0; // Purple
      case CategoriaCore.moradia: return 0xFF009688; // Teal
      case CategoriaCore.outrosPessoal: return 0xFF607D8B; // Blue Grey
    }
  }

  bool get isReceita => false; // Por enquanto apenas despesas no core

  bool get isAgro => const [
    CategoriaCore.maoDeObra,
    CategoriaCore.adubo,
    CategoriaCore.defensivos,
    CategoriaCore.combustivel,
    CategoriaCore.manutencao,
    CategoriaCore.energia,
    CategoriaCore.outrosAgro,
  ].contains(this);

  bool get isPersonal => const [
    CategoriaCore.alimentacao,
    CategoriaCore.transporte,
    CategoriaCore.saude,
    CategoriaCore.educacao,
    CategoriaCore.lazer,
    CategoriaCore.moradia,
    CategoriaCore.outrosPessoal,
  ].contains(this);
}
