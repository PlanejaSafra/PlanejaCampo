// lib/models/agro/epoca_aplicacao.dart

import 'package:collection/collection.dart'; // For MapEquality
import 'package:planejacampo/models/enums.dart';

/// Representa uma época de aplicação de nutrientes com informações completas.
class EpocaAplicacao {
  /// Número de dias para a aplicação em relação ao plantio.
  /// Valores negativos representam dias antes do plantio.
  final int dias;

  /// Descrição textual da época de aplicação (ex: "Plantio", "V4").
  final String descricao;

  /// Modo de aplicação usando o Enum importado.
  final ModoAplicacao modoAplicacao;

  /// Limite máximo de aplicação em kg/ha ou L/ha para esta fase.
  /// Null indica que não há limite específico para a fase.
  final double? limiteMaximo;

  /// Prioridade no esquema de parcelamento (menor = maior prioridade).
  final int prioridade;

  /// Percentual recomendado da dose total para esta fase (0 a 100).
  /// Null indica que o percentual deve ser calculado pelo sistema.
  final double? percentualDose;

  /// Indicador se esta fase é uma das principais para o nutriente em questão.
  final bool aplicacaoPrincipal;

  /// Parâmetros adicionais para extensibilidade. Usar mapa imutável.
  final Map<String, dynamic> parametrosAdicionais;

  /// Construtor da classe [EpocaAplicacao].
  EpocaAplicacao({
    required this.dias,
    required this.descricao,
    required this.modoAplicacao, // Recebe o Enum ModoAplicacao
    this.limiteMaximo,
    this.prioridade = 0,
    this.percentualDose,
    this.aplicacaoPrincipal = true,
    Map<String, dynamic>? parametrosAdicionais,
  })  : parametrosAdicionais = parametrosAdicionais == null
      ? const {} // Usa const map vazio imutável por padrão
      : Map.unmodifiable(parametrosAdicionais), // Cria cópia imutável se fornecido
        assert(descricao.isNotEmpty, 'Descrição não pode ser vazia.'),
        assert(percentualDose == null || (percentualDose >= 0 && percentualDose <= 100),
        'Percentual da dose deve estar entre 0 e 100, ou ser nulo.');

  // --- Getters Baseados em Tempo ---
  bool get isPlantio => dias == 0;
  bool get isPrePlantio => dias < 0;
  bool get isCobertura => dias > 0;

  // --- Getters Baseados no Modo de Aplicação (Enum) ---
  bool get isSulco => modoAplicacao == ModoAplicacao.SULCO_PLANTIO;
  bool get isLanco =>
      modoAplicacao == ModoAplicacao.LANCO_COBERTURA ||
          modoAplicacao == ModoAplicacao.LANCO_PRE_PLANTIO;
  bool get isFoliar => modoAplicacao == ModoAplicacao.FOLIAR;
  bool get isIncorporado => modoAplicacao == ModoAplicacao.INCORPORADO;

  /// Cria uma instância de [EpocaAplicacao] a partir de um mapa (e.g., from Firestore).
  factory EpocaAplicacao.fromMap(Map<String, dynamic> map) {
    // Helper para garantir que parametrosAdicionais seja Map<String, dynamic>
    Map<String, dynamic> extractParams(dynamic params) {
      if (params is Map) {
        try {
          return Map<String, dynamic>.from(params);
        } catch (e) {
          print("Aviso: Falha ao converter parametrosAdicionais do mapa: $e. Usando mapa vazio.");
          return {};
        }
      }
      return {};
    }

    return EpocaAplicacao(
      dias: (map['dias'] as num?)?.toInt() ?? 0,
      descricao: map['descricao']?.toString() ?? '',
      // Usa o método static do Enum para parsear a string armazenada
      // Passa string vazia se nulo, para o fromString tratar
      modoAplicacao: ModoAplicacao.fromString(map['modoAplicacao']?.toString()),
      limiteMaximo: (map['limiteMaximo'] as num?)?.toDouble(),
      prioridade: (map['prioridade'] as num?)?.toInt() ?? 0,
      percentualDose: (map['percentualDose'] as num?)?.toDouble(),
      aplicacaoPrincipal: map['aplicacaoPrincipal'] as bool? ?? true,
      parametrosAdicionais: extractParams(map['parametrosAdicionais']),
    );
  }

  /// Converte a instância de [EpocaAplicacao] para um mapa (e.g., for Firestore).
  Map<String, dynamic> toMap() {
    return {
      'dias': dias,
      'descricao': descricao,
      // Armazena o nome do membro do Enum (e.g., "SULCO_PLANTIO")
      // Isso corresponde ao padrão visto na classe Cultura
      'modoAplicacao': modoAplicacao.name, // Usa .name
      'limiteMaximo': limiteMaximo,
      'prioridade': prioridade,
      'percentualDose': percentualDose,
      'aplicacaoPrincipal': aplicacaoPrincipal,
      'parametrosAdicionais': parametrosAdicionais, // Já é imutável
    };
  }

  /// Cria uma cópia da instância atual com possíveis alterações.
  EpocaAplicacao copyWith({
    int? dias,
    String? descricao,
    ModoAplicacao? modoAplicacao, // Aceita o Enum
    double? limiteMaximo,
    bool clearLimiteMaximo = false,
    int? prioridade,
    double? percentualDose,
    bool clearPercentualDose = false,
    bool? aplicacaoPrincipal,
    Map<String, dynamic>? parametrosAdicionais,
  }) {
    final double? finalLimiteMaximo = clearLimiteMaximo ? null : (limiteMaximo ?? this.limiteMaximo);
    final double? finalPercentualDose = clearPercentualDose ? null : (percentualDose ?? this.percentualDose);

    // Se novos parâmetros adicionais são fornecidos, usa-os, senão mantém os atuais.
    // O construtor garantirá a imutabilidade do novo mapa se fornecido.
    final Map<String, dynamic>? finalParams = parametrosAdicionais ?? this.parametrosAdicionais;


    return EpocaAplicacao(
      dias: dias ?? this.dias,
      descricao: descricao ?? this.descricao,
      modoAplicacao: modoAplicacao ?? this.modoAplicacao,
      limiteMaximo: finalLimiteMaximo,
      prioridade: prioridade ?? this.prioridade,
      percentualDose: finalPercentualDose,
      aplicacaoPrincipal: aplicacaoPrincipal ?? this.aplicacaoPrincipal,
      parametrosAdicionais: finalParams,
    );
  }

  /// Valida se esta época de aplicação possui dados consistentes.
  List<String> validar() {
    List<String> problemas = [];
    if (descricao.isEmpty) {
      problemas.add('Descrição não pode ser vazia');
    }
    if (modoAplicacao == ModoAplicacao.NAO_ESPECIFICADO) {
      problemas.add('Modo de aplicação inválido ou não especificado');
    }
    if (isSulco && limiteMaximo == null) {
      // Considerar se isso é um erro crítico ou um aviso
      // problemas.add('Aplicações no sulco geralmente devem ter um limite máximo definido');
    }
    if (percentualDose != null && (percentualDose! < 0 || percentualDose! > 100)) {
      // O assert no construtor já pega isso, mas pode ser útil ter aqui também
      problemas.add('Percentual da dose inválido: $percentualDose');
    }
    return problemas;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const MapEquality().equals;

    return other is EpocaAplicacao &&
        runtimeType == other.runtimeType &&
        dias == other.dias &&
        descricao == other.descricao &&
        modoAplicacao == other.modoAplicacao && // Compara Enums
        limiteMaximo == other.limiteMaximo &&
        prioridade == other.prioridade &&
        percentualDose == other.percentualDose &&
        aplicacaoPrincipal == other.aplicacaoPrincipal &&
        mapEquals(parametrosAdicionais, other.parametrosAdicionais); // Compara Mapas
  }

  @override
  int get hashCode {
    final mapHash = const MapEquality().hash;
    return dias.hashCode ^
    descricao.hashCode ^
    modoAplicacao.hashCode ^ // Hash do Enum
    limiteMaximo.hashCode ^
    prioridade.hashCode ^
    percentualDose.hashCode ^
    aplicacaoPrincipal.hashCode ^
    mapHash(parametrosAdicionais); // Hash do Mapa
  }

  @override
  String toString() {
    // Usa .name para consistência com toMap, ou .descricao para mais clareza
    return 'EpocaAplicacao{dias: $dias, desc: $descricao, modo: ${modoAplicacao.name}, limite: $limiteMaximo, prio: $prioridade, %: $percentualDose, princ: $aplicacaoPrincipal, params: $parametrosAdicionais}';
  }
}