// lib/models/agro/adubacao/cultura_parametros_factories.dart

import 'package:planejacampo/models/agro/adubacao/cultura_parametros.dart';
import 'package:planejacampo/models/agro/adubacao/epoca_aplicacao.dart';
import 'package:planejacampo/models/enums.dart';

extension CulturaParametrosFactories on CulturaParametros {
  // Constante para o manual padrão
  static const String MANUAL_PADRAO = 'IAC-B100-2022-SP';

  /// Factory para cultura de Cana de Açúcar
  static CulturaParametros canaDeAcucar({
    required String id,
    required String manualAdubacao,
  }) {
    // Mapear os parâmetros por manual
    final Map<String, Map<String, dynamic>> parametrosPorManual = {
      // Parâmetros para IAC-B100-2022-SP (Manual de SP)
      'IAC-B100-2022-SP': {
        'produtividadeMinima': 80.0, // t/ha
        'produtividadeMaxima': 170.0, // t/ha - conforme tabela 3
        'saturacaoBasesIdeal': 70.0, // V% ideal - conforme manual pg 180
        'teorMinimoMagnesio': 8.0, // mmolc/dm³ - conforme manual pg 180

        // Parâmetros calagem
        'parametrosCalagem': {
          'prnt_padrao': 80.0,
          'profundidade_minima': 20.0,
          'profundidade_maxima': 40.0,
          'profundidade_incorporacao': 20.0, // cm
          'dose_maxima_aplicacao': 6.0, // t/ha por aplicação
          'prazo_minimo_aplicacao': 90, // dias antes do plantio
          'saturacao_bases_minima': 40.0, // % mínima
          'saturacao_bases_ideal': 70.0, // % ideal
          'relacao_ca_mg_minima': 3.0, // mínima
          'relacao_ca_mg_maxima': 5.0, // máxima
        },

        // Parâmetros gessagem
        'parametrosGessagem': {
          // --- Chaves Existentes ---
          'necessidade_gesso': 6.0,       // Fator Argila*6. Usado SOMENTE se análise profunda indicar V%<40 ou m%>30.
          'profundidade_avaliacao': 50.0, // Representa camada 25-50 cm.
          'teor_calcio_min': 4.0,       // Limite genérico, não é gatilho primário de DOSE para gesso em cana no B100.
          'teor_sulfato_min': 15.0,      // Limite S [mg/dm³]. Interpretado como subsurface (gatilho) ou superficial (gatilho provisório).
          'saturacao_al_max': 30.0,      // Limite m% [% CTCe]. Gatilho subsurface.
          'dose_maxima': 10.0,           // Limite geral [t/ha].

          // --- Chaves NOVAS Essenciais ---
          // Valor de V% que dispara a necessidade (Manual B100 Cana: V% < 40)
          'saturacao_bases_min': 40.0,
          // Taxa de S por produtividade (Não aplicável para cálculo de dose de gesso em cana)
          'taxaS_porProdutividade_kgHa_por_Ton': 0.0, // Ou null
          // Dose fixa se SOMENTE S for baixo na análise profunda (Manual B100 Cana: 1 t/ha)
          'doseFixa_por_S_baixo_tHa': 1.0,
          // Teor de S assumido no gesso (para cálculos/observações)
          'teorS_Gesso_assumido_decimal': 0.17,
        },

        // Parâmetros manejo
        'espacamentoEntrelinhasMin': 100, // cm
        'espacamentoEntrelinhasMax': 180, // cm
        'populacaoMinima': 10000, // plantas/ha
        'populacaoMaxima': 12000, // plantas/ha
        'permiteParcelamentoN': true,
        'permiteIrrigacao': true,

        // Teores críticos macronutrientes
        'teoresCriticosMacro': {
          'N': {
            'muito_baixo': 15.0,
            'baixo': 25.0,
            'medio': 40.0,
            'adequado': 60.0,
          },
          'P2O5': {
            'muito_baixo': 7.0, // mg/dm³
            'baixo': 16.0,
            'medio': 40.0,
            'alto': 80.0,
          },
          'K2O': {
            'muito_baixo': 0.8, // mmolc/dm³
            'baixo': 1.6,
            'medio': 3.0,
            'alto': 6.0,
          },
          'Ca': {
            'baixo': 4.0, // mmolc/dm³
            'medio': 7.0,
            'alto': 14.0,
          },
          'Mg': {
            'baixo': 5.0, // mmolc/dm³
            'medio': 8.0,
            'alto': 12.0,
          },
          'S': {
            'baixo': 5.0, // mg/dm³
            'medio': 10.0,
            'alto': 15.0,
          },
        },

        // Teores críticos micronutrientes - conforme tabela 4
        'teoresCriticosMicro': {
          'B': {
            'baixo': 0.2, // mg/dm³
            'medio': 0.6,
          },
          'Cu': {
            'baixo': 0.3, // mg/dm³
            'medio': 0.8,
          },
          'Fe': {
            'baixo': 4.0, // mg/dm³
            'medio': 12.0,
          },
          'Mn': {
            'baixo': 1.2, // mg/dm³
            'medio': 5.0,
          },
          'Zn': {
            'baixo': 0.6, // mg/dm³
            'medio': 1.2,
          },
        },

        // Recomendação NPK conforme tabela 3 do manual (pg 183)
        'recomendacaoNPK': {
          'N': {
            100.0: {'geral': 30.0},  // <100 t/ha
            130.0: {'geral': 30.0},  // 100-130 t/ha
            150.0: {'geral': 30.0},  // 130-150 t/ha
            170.0: {'geral': 30.0},  // 150-170 t/ha
            999.0: {'geral': 30.0},  // >170 t/ha
          },
          'P2O5': {
            100.0: {
              'muito_baixo': 180.0,  // <7 mg/dm³
              'baixo': 140.0,        // 7-15 mg/dm³
              'medio': 80.0,         // 16-40 mg/dm³
              'alto': 40.0,          // >40 mg/dm³
            },
            130.0: {
              'muito_baixo': 180.0,
              'baixo': 160.0,
              'medio': 100.0,
              'alto': 60.0,
            },
            150.0: {
              'muito_baixo': 200.0,
              'baixo': 180.0,
              'medio': 120.0,
              'alto': 80.0,
            },
            170.0: {
              'muito_baixo': 200.0,
              'baixo': 180.0,
              'medio': 140.0,
              'alto': 100.0,
            },
            999.0: {
              'muito_baixo': 200.0,
              'baixo': 200.0,
              'medio': 140.0,
              'alto': 100.0,
            },
          },
          'K2O': {
            100.0: {
              'muito_baixo': 140.0,  // <0.8 mmolc/dm³
              'baixo': 120.0,        // 0.8-1.5 mmolc/dm³
              'medio': 100.0,        // 1.6-3.0 mmolc/dm³
              'alto': 60.0,          // >3.0 mmolc/dm³
            },
            130.0: {
              'muito_baixo': 160.0,
              'baixo': 140.0,
              'medio': 120.0,
              'alto': 80.0,
            },
            150.0: {
              'muito_baixo': 180.0,
              'baixo': 160.0,
              'medio': 140.0,
              'alto': 100.0,
            },
            170.0: {
              'muito_baixo': 200.0,
              'baixo': 180.0,
              'medio': 160.0,
              'alto': 120.0,
            },
            999.0: {
              'muito_baixo': 220.0,
              'baixo': 200.0,
              'medio': 180.0,
              'alto': 120.0,
            },
          },
        },

        // Recomendação micronutrientes - conforme tabela 4
        'recomendacaoMicro': {
          'B': {
            '<0.2': 2.0,
            '0.2-0.6': 1.0,
            '>0.6': 0.0
          },
          'Cu': {
            '<0.3': 5.0,
            '0.3-0.8': 0.0,
            '>0.8': 0.0
          },
          'Mn': {
            '<1.2': 5.0,
            '1.2-5.0': 0.0,
            '>5.0': 0.0
          },
          'Zn': {
            '<0.6': 10.0,
            '0.6-1.2': 5.0,
            '>1.2': 2.0
          },
        },

        // Faixas de interpretação textura
        'faixasTextura': {
          'arenoso': 150.0, // g/kg argila
          'medio': 350.0,
          'argiloso': 600.0,
        },

        // Limites máximos por nutriente
        'limitesMaximosNutrientes': {
          'N': 90.0,  // 30 plantio + 60 cobertura
          'P2O5': 200.0, // Maior valor da tabela 3
          'K2O': 220.0,  // Maior valor da tabela 3
          'Zn': 10.0,    // Conforme tabela 4
          'B': 2.0,
          'Cu': 5.0,
          'Mn': 5.0,
        },

        // Limites máximos no sulco - conforme recomendações da tabela 3
        'limitesMaximosSulco': {
          'N+K2O': 80.0, // kg/ha
          'K2O': 80.0,   // Conforme nota 3 da tabela 3
          'B': 1.0,
          'Zn': 5.0,
        },

        // Fontes recomendadas por nutriente
        'fontesNutrientes': {
          'N': ['Ureia', 'Nitrato de Amônio', 'Sulfato de Amônio'],
          'P2O5': ['Superfosfato Simples', 'Superfosfato Triplo', 'MAP'],
          'K2O': ['Cloreto de Potássio', 'Sulfato de Potássio'],
          'Zn': ['Sulfato de Zinco', 'Óxido de Zinco'],
          'B': ['Ácido Bórico', 'Bórax', 'Ulexita'],
          'Cu': ['Sulfato de Cobre', 'Óxisulfato de Cobre'],
          'Mn': ['Sulfato de Manganês', 'Óxisulfato de Manganês'],
          'Mo': ['Molibdato de Sódio', 'Molibdato de Amônio'],
        },

        // Fatores de ajuste por condição
        'fatorAjusteDoses': {
          'textura': {
            'arenoso': 0.8, // Reduz 20% em solos arenosos
            'medio': 1.0,   // Dose padrão
            'argiloso': 1.2, // Aumenta 20% em solos argilosos
          },
          'materia_organica': {
            'baixo': 1.2,   // Aumenta 20%
            'medio': 1.0,   // Mantém
            'alto': 0.8,    // Reduz 20%
          },
          'irrigacao': {
            'N': 1.2,      // Aumenta 20% se irrigado
            'K2O': 1.2,
            'padrao': 1.0,
          },
        },

        // Épocas de aplicação - conforme manual
        'epocasAplicacao': {
          'N_PLANT': {
            'dias': 0,
            'descricao': 'Plantio (30 kg/ha)',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': 30.0, // 30 kg/ha fixo no plantio conforme tabela 3
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar 30 kg/ha de N no plantio, conforme recomendação técnica.'
                ],
                'irrigado': [
                  'Em áreas irrigadas, o parcelamento do restante do N é mais eficiente.'
                ]
              }
            }
          },
          'N_COB1': {
            'dias': 60,
            'descricao': 'Cobertura (junto à operação de quebra-lombo)',
            'modoAplicacao': 'LANCO_COBERTURA',
            'limiteMaximo': null,
            'prioridade': 2,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar o restante da dose de N na operação de quebra-lombo, antes da formação de colmos.',
                  'Em cana-planta, complementar a adubação de plantio com 30 a 60 kg/ha de N.'
                ],
                'irrigado': [
                  'Em áreas irrigadas, aplicar após irrigação para melhor aproveitamento.'
                ]
              }
            }
          },
          'P_PLANT': {
            'dias': 0,
            'descricao': 'Plantio (total)',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': null, // Todo P vai no plantio
            'prioridade': 1,
            'percentualDose': 100.0, // 100% no plantio
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar todo o fósforo no plantio para melhor aproveitamento pela cultura.'
                ],
                'argiloso': [
                  'Em solos argilosos, preferir aplicação localizada de P para reduzir fixação.',
                  'Para solos muito ácidos, considerar maior dose devido à menor disponibilidade do nutriente.'
                ],
                'arenoso': [
                  'Em solos arenosos, aplicar no sulco de plantio para reduzir perdas por lixiviação.'
                ]
              }
            }
          },
          'K_PLANT': {
            'dias': 0,
            'descricao': 'Plantio (máx 80 kg/ha)',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': 80.0, // Limite de 80 kg/ha no sulco conforme p.184
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Não aplicar mais de 80 kg/ha de K₂O no sulco para evitar efeito salino.',
                  'O cloreto de potássio é a fonte mais comum de K, mas traz riscos de excesso de salinidade se aplicado em doses altas no sulco.'
                ],
                'arenoso': [
                  'Em solos arenosos, limitar a dose no sulco e aplicar o restante em cobertura para reduzir lixiviação.'
                ]
              }
            }
          },
          'K_COB': {
            'dias': 60,
            'descricao': 'Cobertura (junto quebra-lombo)',
            'modoAplicacao': 'LANCO_COBERTURA',
            'limiteMaximo': null,
            'prioridade': 2,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar o restante do K junto com a operação de quebra-lombo.'
                ],
                'arenoso': [
                  'Em solos arenosos, a aplicação parcelada de K₂O reduz perdas por lixiviação.'
                ]
              }
            }
          },
          'S_PLANT': {
            'dias': 0,
            'descricao': 'Plantio (quando S < 15 mg/dm³)',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Quando não for feita a gessagem, aplicar 50 kg/ha de S se o solo apresentar teor de S inferior a 15 mg/dm³ na camada 25-50 cm.',
                  'O gesso é excelente fonte de enxofre para a cultura da cana.'
                ]
              }
            }
          },
          'MICRO_PLANT': {
            'dias': 0,
            'descricao': 'Plantio',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar micronutrientes conforme recomendação da tabela 4 do manual.',
                  'As quantidades de micronutrientes exportadas correspondem em média a 120 g B, 260 g Cu, 1.400 g Fe, 970 g Mn, 160 g Mo e 350 g Zn por 100 t de colmo.'
                ],
                'Zn': [
                  'Aplicar 10 kg/ha de Zn em solos com teores inferiores a 0,6 mg/dm³ e 5 kg/ha em solos com teores entre 0,6 e 1,2 mg/dm³.',
                  'Para as doses mais altas de Zn, considerar parcelamento da aplicação.'
                ],
                'B': [
                  'Aplicar 2 kg/ha de B em solos com teores inferiores a 0,2 mg/dm³ e 1 kg/ha em solos com teores entre 0,2 e 0,6 mg/dm³.',
                  'Preferir aplicação na operação de quebra-lombo para evitar fitotoxicidade.'
                ],
                'Cu': [
                  'Aplicar 5 kg/ha de Cu em solos com teores inferiores a 0,3 mg/dm³.'
                ],
                'Mn': [
                  'Aplicar 5 kg/ha de Mn em solos com teores inferiores a 1,2 mg/dm³.'
                ]
              }
            }
          },
          'S_GESSO': {
            'dias': 0,
            'descricao': 'Via gesso (complementar)',
            'modoAplicacao': 'LANCO_PRE_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 0,
            'aplicacaoPrincipal': false,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'O gesso é produto estratégico para a cultura da cana-de-açúcar, pois além de melhorar o ambiente radicular, é excelente fonte de enxofre.',
                  'O efeito do gesso no solo dá-se abaixo da camada arável e perdura por vários anos.'
                ],
                'arenoso': [
                  'Em solos arenosos, o gesso ajuda a reduzir perdas de nutrientes por lixiviação ao melhorar a CTC em camadas mais profundas.'
                ]
              }
            }
          },
          // Adicionar ao epocasAplicacao para soqueiras
          'N_SOCA': {
            'dias': 0, // Dias após o corte
            'descricao': 'Adubação da soqueira (N)',
            'modoAplicacao': 'LANCO_COBERTURA',
            'limiteMaximo': null,
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar N conforme tabela 5, ao lado ou sobre as linhas de cana.',
                  'Em áreas que recebem vinhaça, descontar 70% do N contido na vinhaça in natura ou 50% do N de vinhaças concentradas.'
                ],
                'irrigado': [
                  'Em áreas irrigadas, considerar parcelamento em mais aplicações para maior eficiência.'
                ]
              }
            }
          },
          'PK_SOCA': {
            'dias': 0, // Dias após o corte
            'descricao': 'Adubação da soqueira (P e K)',
            'modoAplicacao': 'LANCO_COBERTURA',
            'limiteMaximo': null,
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar P e K conforme tabela 5, ao lado ou sobre as linhas de cana.',
                  'Em áreas que recebem vinhaça, descontar todo o K contido na vinhaça pois 100% estará disponível para a cultura.'
                ],
                'arenoso': [
                  'Em solos arenosos, atenção à lixiviação do K. Considerar parcelamento se possível.'
                ]
              }
            }
          },
          'MICRO_SOCA': {
            'dias': 30, // Após brotação
            'descricao': 'Micronutrientes nas soqueiras',
            'modoAplicacao': 'FOLIAR',
            'limiteMaximo': null,
            'prioridade': 2,
            'aplicacaoPrincipal': false,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Para soqueiras, aplicações foliares têm se mostrado mais eficientes que via solo.',
                  'Recomenda-se aplicar 2-3 kg/ha de Zn e 1-2 kg/ha de Mn via foliar.',
                  'São necessárias pelo menos duas aplicações junto ao tratamento fitossanitário.'
                ],
                'B': [
                  'A dose recomendada para soqueiras varia de 1 a 1,5 kg/ha de B, podendo ser aplicada via solo ou foliar.'
                ],
                'Mo': [
                  'Aplicar 0,3 kg/ha de Mo via foliar aos 4 meses após a rebrota ou quando as plantas estiverem na fase de máximo perfilhamento.'
                ]
              }
            }
          },
        },

        // Restrições de aplicação
        'restricoesAplicacao': [
          'Não aplicar mais de 80 kg/ha de K2O no sulco de plantio em solo arenoso',
          'Não aplicar adubo potássico em solos com teores acima de 6,0 mmolc/dm³',
          'Parcelar doses de N acima de 80 kg/ha',
        ],

        // Observações de manejo
        'observacoesManejo': [
          'Aplicar calcário 90 dias antes do plantio',
          'Aplicar gesso após a calagem quando necessário',
          'Em áreas irrigadas, parcelar N em 3-4 aplicações',
          'Amostrar solo a cada dois anos para correção das soqueiras',
          'O gesso deve ser aplicado no plantio ou em soqueiras conforme análise de solo na camada 25-50 cm'
        ],

        // Observações gerais
        'observacoesGerais': [
          'Para cana colhida sem queima, considerar a liberação de nutrientes da palha',
          'Quando não for feita a gessagem, aplicar 50 kg/ha de S se o solo apresentar teor de S inferior a 15 mg/dm³',
          'A indústria canavieira cultiva áreas extensas e renova cerca de 20% da área anualmente',
          'O gesso é produto estratégico para a cultura, pois além de melhorar o ambiente radicular, é excelente fonte de enxofre',
        ],
      },
    };

    // Obter parâmetros para o manual solicitado ou usar o padrão
    final parametros = parametrosPorManual[manualAdubacao] ?? parametrosPorManual[MANUAL_PADRAO]!;

    // Log informativo
    print('Usando manual: ${parametrosPorManual.containsKey(manualAdubacao) ? manualAdubacao : MANUAL_PADRAO} para cultura Cana de Açúcar');

    return CulturaParametros(
      id: id,
      manualAdubacao: manualAdubacao,
      cultura: TipoCultura.CANA_DE_ACUCAR,
      produtividadeMinima: parametros['produtividadeMinima'],
      produtividadeMaxima: parametros['produtividadeMaxima'],
      saturacaoBasesIdeal: parametros['saturacaoBasesIdeal'],
      teorMinimoMagnesio: parametros['teorMinimoMagnesio'],
      parametrosCalagem: Map<String, dynamic>.from(parametros['parametrosCalagem']),
      parametrosGessagem: Map<String, dynamic>.from(parametros['parametrosGessagem']),
      espacamentoEntrelinhasMin: parametros['espacamentoEntrelinhasMin'],
      espacamentoEntrelinhasMax: parametros['espacamentoEntrelinhasMax'],
      populacaoMinima: parametros['populacaoMinima'],
      populacaoMaxima: parametros['populacaoMaxima'],
      permiteParcelamentoN: parametros['permiteParcelamentoN'],
      permiteIrrigacao: parametros['permiteIrrigacao'],
      teoresCriticosMacro: _converterMapaNestedDouble(parametros['teoresCriticosMacro']),
      teoresCriticosMicro: _converterMapaNestedDouble(parametros['teoresCriticosMicro']),
      recomendacaoNPK: _converterRecomendacaoNPK(parametros['recomendacaoNPK']),
      recomendacaoMicro: _converterMapaNestedDouble(parametros['recomendacaoMicro']),
      faixasTextura: Map<String, double>.from(parametros['faixasTextura']),
      limitesMaximosNutrientes: Map<String, double>.from(parametros['limitesMaximosNutrientes']),
      limitesMaximosSulco: Map<String, double>.from(parametros['limitesMaximosSulco']),
      fontesNutrientes: _converterFontesNutrientes(parametros['fontesNutrientes']),
      fatorAjusteDoses: _converterFatorAjuste(parametros['fatorAjusteDoses']),
      epocasAplicacao: _converterEpocasAplicacao(parametros['epocasAplicacao']),
      restricoesAplicacao: List<String>.from(parametros['restricoesAplicacao']),
      observacoesManejo: List<String>.from(parametros['observacoesManejo']),
      observacoesGerais: List<String>.from(parametros['observacoesGerais']),
    );
  }

  /// Factory para cultura de Soja
  /// Factory para cultura de Soja
  static CulturaParametros soja({
    required String id,
    required String manualAdubacao,
  }) {
    // Mapear os parâmetros por manual
    final Map<String, Map<String, dynamic>> parametrosPorManual = {
      // Parâmetros para IAC-B100-2022-SP (Manual de SP)
      'IAC-B100-2022-SP': {
        'produtividadeMinima': 2.0, // t/ha
        'produtividadeMaxima': 5.0, // t/ha
        'saturacaoBasesIdeal': 70.0, // V% ideal - conforme manual
        'teorMinimoMagnesio': 8.0, // mmolc/dm³ - conforme manual

        // Parâmetros calagem
        'parametrosCalagem': {
          'prnt_padrao': 80.0,
          'profundidade_minima': 20.0,
          'profundidade_maxima': 40.0,
          'dose_maxima_aplicacao': 6.0, // t/ha por aplicação
          'prazo_minimo_aplicacao': 60, // dias antes do plantio - conforme manual
          'saturacao_bases_minima': 50.0, // % mínima
          'saturacao_bases_ideal': 70.0, // % ideal
          'relacao_ca_mg_minima': 3.0, // mínima
          'relacao_ca_mg_maxima': 5.0, // máxima
        },

        // Parâmetros gessagem - ajustado conforme manual
        'parametrosGessagem': {
          // --- Chaves Existentes ---
          'necessidade_gesso': 0.0,        // Fator Argila * X NÃO se aplica para Soja no B100. Zero indica não usar.
          'profundidade_avaliacao': 40.0,  // Representa camada 20-40 cm.
          'teor_calcio_min': 4.0,        // Limite genérico, pode indicar problema subsuperficial.
          'teor_sulfato_min': 15.0,       // Limite S [mg/dm³]. Gatilho principal para dose em Soja. Interpretado como subsurface ou superficial (provisório).
          'saturacao_al_max': 20.0,       // Limite m% [% CTCe]. Pode indicar problema subsuperficial.
          'dose_maxima': 10.0,            // Limite geral [t/ha].

          // --- Chaves NOVAS Essenciais ---
          // Valor de V% que dispara necessidade (Não é gatilho primário para DOSE de gesso em soja no B100)
          'saturacao_bases_min': 40.0, // Pode ser usado como indicador geral de acidez subsuperficial
          // Taxa de S por produtividade (Manual B100 Soja: 15 kg S / t grão)
          'taxaS_porProdutividade_kgHa_por_Ton': 15.0,
          // Dose fixa por S baixo (Não aplicável para Soja, que usa cálculo por produtividade)
          'doseFixa_por_S_baixo_tHa': 0.0, // Ou null
          // Teor de S assumido no gesso
          'teorS_Gesso_assumido_decimal': 0.17,
        },

        // Parâmetros manejo
        'espacamentoEntrelinhasMin': 45, // cm - conforme manual
        'espacamentoEntrelinhasMax': 50, // cm - conforme manual
        'populacaoMinima': 220000, // plantas/ha
        'populacaoMaxima': 280000, // plantas/ha
        'permiteParcelamentoN': false, // N via fixação biológica
        'permiteIrrigacao': true,

        // Teores críticos macronutrientes - ajustados conforme Boletim 100
        'teoresCriticosMacro': {
          'P2O5': {
            'muito_baixo': 16.0, // mg/dm³ - conforme Boletim 100
            'baixo': 40.0,
            'adequado': 80.0,
          },
          'K2O': {
            'muito_baixo': 1.6, // mmolc/dm³ - conforme Boletim 100
            'baixo': 3.0,
            'medio': 5.0,
            'adequado': 6.0,
          },
          'Ca': {
            'baixo': 4.0, // mmolc/dm³
            'medio': 7.0,
            'alto': 14.0,
          },
          'Mg': {
            'baixo': 4.0, // mmolc/dm³
            'medio': 8.0, // conforme manual
            'alto': 12.0,
          },
          'S': {
            'baixo': 5.0, // mg/dm³
            'medio': 10.0,
            'alto': 15.0, // conforme manual para camada 20-40cm
          },
        },

        // Teores críticos micronutrientes
        'teoresCriticosMicro': {
          'B': {
            'baixo': 0.2, // mg/dm³
            'medio': 0.6,
          },
          'Cu': {
            'baixo': 0.3, // mg/dm³
            'medio': 0.8,
          },
          'Fe': {
            'baixo': 4.0, // mg/dm³
            'medio': 12.0,
          },
          'Mn': {
            'baixo': 1.3, // mg/dm³ - ajustado conforme manual
            'medio': 5.0,
          },
          'Zn': {
            'baixo': 0.5, // mg/dm³
            'medio': 1.2,
          },
        },

        // Recomendação NPK simplificada - ajustado conforme tabela do Boletim 100
        'recomendacaoNPK': {
          'N': {
            3.0: {'geral': 0.0},  // FBN
            4.0: {'geral': 0.0},  // FBN
            5.0: {'geral': 0.0},  // FBN
            6.0: {'geral': 0.0},  // Adicionado para alta produtividade
          },
          'P2O5': {
            3.0: {
              'muito_baixo': 120.0, // <16 mg/dm³
              'baixo': 80.0,       // 16-40 mg/dm³
              'adequado': 30.0     // >40 mg/dm³
            },
            4.0: {
              'muito_baixo': 140.0,
              'baixo': 100.0,
              'adequado': 40.0
            },
            5.0: {
              'muito_baixo': 160.0,
              'baixo': 120.0,
              'adequado': 60.0
            },
            6.0: {
              'muito_baixo': 180.0, // Nota: "Dificilmente são obtidas essas produtividades"
              'baixo': 140.0,      // 16-40 mg/dm³
              'adequado': 80.0     // >40 mg/dm³
            }
          },
          'K2O': {
            3.0: {
              'muito_baixo': 100.0, // <1,6 mmolc/dm³
              'baixo': 60.0,       // 1,6-3,0 mmolc/dm³
              'medio': 50.0,       // Categoria incluída para completude
              'adequado': 40.0     // >3,0 mmolc/dm³
            },
            4.0: {
              'muito_baixo': 120.0,
              'baixo': 80.0,
              'medio': 70.0,
              'adequado': 60.0
            },
            5.0: {
              'muito_baixo': 140.0,
              'baixo': 100.0,
              'medio': 90.0,       // Categoria incluída conforme manual
              'adequado': 80.0
            },
            6.0: {
              'muito_baixo': 160.0, // Adicionado para produtividade >5 t/ha
              'baixo': 120.0,
              'medio': 110.0,
              'adequado': 100.0
            }
          }
        },

        // Recomendação micronutrientes - ajustada conforme manual
        'recomendacaoMicro': {
          'Zn': {'<0.6': 5.0, '0.6-1.2': 2.0, '>1.2': 0.0}, // kg/ha - conforme manual
          'B': {'<0.2': 1.0, '0.2-0.6': 0.5, '>0.6': 0.0},
          'Cu': {'<0.3': 2.0, '0.3-0.8': 1.0, '>0.8': 0.0}, // kg/ha - conforme manual
          'Mn': {'<1.3': 5.0, '1.3-5.0': 2.5, '>5.0': 0.0}, // kg/ha - ajustado conforme manual
          'Mo': {'<0.1': 0.05, '>0.1': 0.0}, // Mo 50 g/ha (0,05 kg/ha) via semente
          'Co': {'todos': 0.005}, // Co 5 g/ha (0,005 kg/ha) via semente
        },

        // Faixas de interpretação textura
        'faixasTextura': {
          'arenoso': 150.0, // g/kg argila
          'medio': 350.0,
          'argiloso': 600.0,
        },

        // Limites máximos por nutriente
        'limitesMaximosNutrientes': {
          'P2O5': 180.0, // kg/ha - ajustado conforme maior valor na tabela
          'K2O': 160.0,  // kg/ha - ajustado conforme maior valor na tabela
          'Zn': 5.0,     // kg/ha - conforme manual
          'B': 1.0,      // kg/ha - conforme manual
          'Cu': 2.0,     // kg/ha - conforme manual
          'Mn': 5.0,     // kg/ha - conforme manual
        },

        // Limites máximos no sulco
        'limitesMaximosSulco': {
          'K2O': 50.0, // kg/ha - conforme manual: "Não aplicar mais de 50 kg ha⁻¹ de K₂O no sulco"
          'B': 0.5,    // kg/ha
          'Zn': 2.0,   // kg/ha
        },

        // Fontes recomendadas por nutriente
        'fontesNutrientes': {
          'P2O5': ['Superfosfato Simples', 'Superfosfato Triplo', 'MAP'],
          'K2O': ['Cloreto de Potássio'],
          'Zn': ['Sulfato de Zinco', 'Óxido de Zinco'],
          'B': ['Ácido Bórico', 'Bórax'],
          'Cu': ['Sulfato de Cobre', 'Óxido de Cobre'],
          'Mn': ['Sulfato de Manganês', 'Óxido de Manganês'],
          'Mo': ['Molibdato de Sódio', 'Molibdato de Amônio'],
          'Co': ['Sulfato de Cobalto', 'Cloreto de Cobalto'],
        },

        // Fatores de ajuste por condição
        'fatorAjusteDoses': {
          'textura': {
            'arenoso': 0.8, // Reduz 20% em solos arenosos
            'medio': 1.0,   // Dose padrão
            'argiloso': 1.2, // Aumenta 20% em solos argilosos
          },
          'materia_organica': {
            'baixo': 1.0, // Não ajusta
            'medio': 1.0,
            'alto': 1.0,
          },
          'irrigacao': {
            'K2O': 1.2, // Aumenta 20% se irrigado
            'padrao': 1.0,
          },
        },

        // Novo campo parametrosAdicionais
        'parametrosAdicionais': {
          'modosAplicacaoPadrao': {
            'pre_plantio': 'Lanço em pré-plantio',
            'plantio': 'Sulco de plantio',
            'cobertura': 'Lanço em cobertura'
          },
          'estagiosCultura': {
            'Plantio': 0,
            'V2-V3': 20,
            'V4-V5': 35,
            'R1-R2': 50,
            'R3+': 65
          },
          'nomesNormalizadosFases': {
            'plantio': 'Plantio',
            'pre_plantio': 'Pré-plantio (15 dias antes)',
            'cobertura1': 'Cobertura (20-25 dias após germinação)',
            'K_PLANT': 'Plantio (máx 50 kg/ha)',
            'K_COB1': 'Cobertura (20-25 dias)',
            'K_PRE': 'Pré-plantio (solos argilosos, K baixo)'
          },
          'condicoesParcelamento': {
            'K2O': {
              'limite_sulco': 50.0, // Específico do manual IAC-B100 para soja
              'parcelar_solo_arenoso': true,
              'parcelar_dose_alta': 80.0
            }
          },
          'regrasParcelamento': {
            'P2O5': {
              'aplicar_tudo_plantio': true,
              'permitir_pre_plantio': false
            },
            'K2O': {
              'limite_sulco': 50.0,
              'teor_baixo_limite': 1.6,
              'dose_minima_pre_plantio': 80.0,
              'texturas_permitidas_pre_plantio': ['ARGILOSO'],
              'texturas_proibidas_pre_plantio': ['ARENOSO'],
              'percentual_padrao_plantio': 50.0,
              'percentual_padrao_cobertura': 50.0
            }
          },

          'observacoesPadrao': {
            'K2O': {
              'arenoso': [
                'Em solos arenosos, limitar a dose no sulco e aplicar o restante em cobertura para reduzir lixiviação.'
              ],
              'pre_plantio': [
                'Em solos argilosos com teor de K baixo (<1,6 mmolc/dm³) e doses altas, a aplicação em pré-plantio a lanço é recomendada.'
              ],
              'limite_excedido': [
                'Não aplicar mais de 50 kg/ha de K₂O no sulco para evitar efeito salino.'
              ]
            },
            'P2O5': {
              'geral': [
                'Aplicar todo o fósforo no plantio para melhor aproveitamento pela cultura.'
              ]
            }
          }
        },

        // Épocas de aplicação - ajustado conforme manual
        'epocasAplicacao': {
          'P_TOTAL': {
            'dias': 0,
            'descricao': 'Todo P no plantio',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 1,
            'percentualDose': 100.0,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar todo o fósforo no plantio para melhor aproveitamento pela cultura.'
                ],
                'argiloso': [
                  'Em solos argilosos, preferir aplicação localizada de P para reduzir fixação.'
                ],
                'arenoso': [
                  'Em solos arenosos, aplicar no sulco de plantio para reduzir perdas por lixiviação.'
                ]
              }
            }
          },
          'K_PLANT': {
            'dias': 0,
            'descricao': '50% K no plantio',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': 50.0, // Limite de 50 kg/ha no sulco conforme Boletim p.211
            'prioridade': 1,
            'percentualDose': 50.0, // 50% no plantio quando parcelado
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Não aplicar mais de 50 kg/ha de K₂O no sulco de semeadura.',
                  'Evitar contato direto com as sementes para prevenir redução do estande devido ao efeito salino.'
                ],
                'arenoso': [
                  'Em solos arenosos, limitar a dose no sulco e aplicar o restante em cobertura para reduzir lixiviação.'
                ]
              }
            }
          },
          'K_COB1': {
            'dias': 25,
            'descricao': '50% K em cobertura (20-25 dias)',
            'modoAplicacao': 'LANCO_COBERTURA',
            'limiteMaximo': null,
            'prioridade': 2,
            'percentualDose': 50.0, // Restante em cobertura
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar o restante da dose de potássio até 20-25 dias após a germinação.',
                  'Aplicações tardias desse elemento são pouco eficientes.'
                ],
                'arenoso': [
                  'Em solos arenosos, a aplicação parcelada de K₂O reduz perdas por lixiviação.'
                ]
              }
            }
          },
          'K_PRE': {
            'dias': -15,
            'descricao': 'K em pré-plantio (15 dias antes, baixo teor e dose alta)',
            'modoAplicacao': 'LANCO_PRE_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 0,
            'aplicacaoPrincipal': false,
            'parametrosAdicionais': {
              'condicoesAplicacao': {
                'teor_minimo': null,         // Não há teor mínimo
                'teor_maximo': 1.6,          // Teor abaixo de 1,6 mmolc/dm³
                'dose_minima': 80.0,         // Dose mínima de 80 kg/ha
                'texturas_permitidas': ['ARGILOSO'], // Apenas solos argilosos
                'texturas_proibidas': ['ARENOSO'],   // Nunca em solos arenosos
              },
              'observacoes': {
                'geral': [
                  'Quando os teores de K forem baixos (<1,6 mmolc/dm³) e as doses recomendadas iguais ou superiores a 80 kg/ha, é aconselhável transferir parte ou toda adubação potássica para a fase de pré-plantio.'
                ],
                'argiloso': [
                  'Em solos argilosos com teor de K baixo e doses altas, a aplicação em pré-plantio a lanço é recomendada.'
                ],
                'arenoso': [
                  'Em solos arenosos, NÃO é recomendado transferir a adubação potássica para pré-plantio devido ao alto risco de lixiviação.'
                ]
              }
            }
          },
          'MICRO_PLANT': {
            'dias': 0,
            'descricao': 'Micros no plantio ou TS',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Deficiências de micronutrientes na soja são pouco comuns no estado de São Paulo.',
                  'Na suspeita de deficiência, realizar análise de solo e foliar para confirmação.'
                ],
                'Zn': [
                  'Aplicar 5 kg/ha de Zn em caso de deficiência confirmada.'
                ],
                'Cu': [
                  'Aplicar 2 kg/ha de Cu em caso de deficiência confirmada.'
                ],
                'B': [
                  'Aplicar 1 kg/ha de B em caso de deficiência confirmada.',
                  'Em plantio direto, o B pode ser aplicado juntamente com herbicidas na dessecação antes do plantio.'
                ],
                'Mn': [
                  'Aplicar 5 kg/ha de Mn em solos com teor até 1,3 mg/dm³.',
                  'Cultivares com tecnologia RR têm maior demanda por Mn do que aquelas sem essa tecnologia.',
                  'Mesmo em solos com teores médios (>1,3 mg/dm³), pode ser necessário aplicar 2,5 kg/ha de Mn para cultivares RR.'
                ]
              }
            }
          },
          'MO_TS': {
            'dias': 0,
            'descricao': 'Mo (50g/ha) via tratamento de sementes',
            'modoAplicacao': 'NAO_ESPECIFICADO', // Tratamento de sementes não é campo
            'limiteMaximo': 0.05, // 50g/ha
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar 50 g/ha de Mo nas formas de molibdato de amônio ou de sódio em mistura com as sementes.',
                  'A deficiência de Mo acarreta baixa fixação biológica de nitrogênio (FBN).',
                  'Complementar com aplicação foliar de 30 g/ha de Mo junto ao tratamento fitossanitário até o pleno florescimento.'
                ]
              }
            }
          },
          'CO_TS': {
            'dias': 0,
            'descricao': 'Co (5g/ha) via tratamento de sementes',
            'modoAplicacao': 'NAO_ESPECIFICADO', // Tratamento de sementes não é campo
            'limiteMaximo': 0.005, // 5g/ha
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar 3 a 5 g/ha de Co em mistura com as sementes.',
                  'O cobalto é parte fundamental do processo de fixação biológica de nitrogênio (FBN).'
                ]
              }
            }
          },
          'S_PRE': {
            'dias': -15,
            'descricao': 'Enxofre via gesso em pré-plantio',
            'modoAplicacao': 'LANCO_PRE_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 0,
            'aplicacaoPrincipal': false, // Apenas quando S < 15 mg/dm³
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Em solos com S-SO₄²⁻ abaixo de 15 mg/dm³ na camada 20-40 cm, aplicar 15 kg/ha de S por tonelada de produtividade esperada.',
                  'Uma forma eficiente e econômica de aplicação de S é o uso de gesso agrícola a lanço em pré-plantio.'
                ]
              }
            }
          }
        },

        // Restrições de aplicação
        'restricoesAplicacao': [
          'Não utilizar N mineral, priorizar FBN',
          'Não aplicar mais de 50 kg/ha de K2O no sulco',
          'Co e Mo preferencialmente via tratamento de sementes',
          'Em solos arenosos, parcelar K em 2-3 aplicações',
          'Em teores baixos de K (<1,6 mmolc/dm³) com doses ≥80 kg/ha, transferir parte ou toda adubação para pré-plantio',
        ],

        // Observações de manejo
        'observacoesManejo': [
          'Inocular as sementes com Bradyrhizobium',
          'Tratar sementes com Co e Mo',
          'Em áreas novas, usar 2x a dose de inoculante',
          'Aplicar calcário 60-90 dias antes do plantio',
          'Em solos com S-SO₄²⁻ abaixo de 15 mg/dm³ na camada 20-40 cm, aplicar 15 kg/ha de S por tonelada de produtividade',
        ],

        // Observações gerais
        'observacoesGerais': [
          'Não recomendada adubação nitrogenada para produtividades >6 t/ha em solos com P muito baixo',
          'Considerar histórico da área para ajuste de doses',
          'Monitorar nodulação para eficiência da FBN',
          'Em áreas com alto teor de P, usar doses de manutenção',
          'Evitar aplicação de calcário próximo ao plantio',
          'Produtividades acima de 5 t/ha dificilmente são obtidas com aplicação localizada de P em solos com teores baixos',
          'Considerar o uso de gesso agrícola a lanço em pré-plantio como fonte eficiente de S',
        ],
      },

      // Outros manuais podem ser adicionados aqui
    };

    // Obter parâmetros para o manual solicitado ou usar o padrão
    final parametros = parametrosPorManual[manualAdubacao] ?? parametrosPorManual[MANUAL_PADRAO]!;

    // Log informativo
    print('Usando manual: ${parametrosPorManual.containsKey(manualAdubacao) ? manualAdubacao : MANUAL_PADRAO} para cultura Soja');

    return CulturaParametros(
      id: id,
      manualAdubacao: manualAdubacao,
      cultura: TipoCultura.SOJA,
      produtividadeMinima: parametros['produtividadeMinima'],
      produtividadeMaxima: parametros['produtividadeMaxima'],
      saturacaoBasesIdeal: parametros['saturacaoBasesIdeal'],
      teorMinimoMagnesio: parametros['teorMinimoMagnesio'],
      parametrosCalagem: Map<String, dynamic>.from(parametros['parametrosCalagem']),
      parametrosGessagem: Map<String, dynamic>.from(parametros['parametrosGessagem']),
      espacamentoEntrelinhasMin: parametros['espacamentoEntrelinhasMin'],
      espacamentoEntrelinhasMax: parametros['espacamentoEntrelinhasMax'],
      populacaoMinima: parametros['populacaoMinima'],
      populacaoMaxima: parametros['populacaoMaxima'],
      permiteParcelamentoN: parametros['permiteParcelamentoN'],
      permiteIrrigacao: parametros['permiteIrrigacao'],
      teoresCriticosMacro: _converterMapaNestedDouble(parametros['teoresCriticosMacro']),
      teoresCriticosMicro: _converterMapaNestedDouble(parametros['teoresCriticosMicro']),
      recomendacaoNPK: _converterRecomendacaoNPK(parametros['recomendacaoNPK']),
      recomendacaoMicro: _converterMapaNestedDouble(parametros['recomendacaoMicro']),
      faixasTextura: Map<String, double>.from(parametros['faixasTextura']),
      limitesMaximosNutrientes: Map<String, double>.from(parametros['limitesMaximosNutrientes']),
      limitesMaximosSulco: Map<String, double>.from(parametros['limitesMaximosSulco']),
      fontesNutrientes: _converterFontesNutrientes(parametros['fontesNutrientes']),
      fatorAjusteDoses: _converterFatorAjuste(parametros['fatorAjusteDoses']),
      epocasAplicacao: _converterEpocasAplicacao(parametros['epocasAplicacao']),
      restricoesAplicacao: List<String>.from(parametros['restricoesAplicacao']),
      observacoesManejo: List<String>.from(parametros['observacoesManejo']),
      observacoesGerais: List<String>.from(parametros['observacoesGerais']),
      parametrosAdicionais: parametros['parametrosAdicionais'],
    );
  }

  static CulturaParametros milhoGrao({
    required String id,
    required String manualAdubacao,
  }) {
    // Mapear os parâmetros por manual
    final Map<String, Map<String, dynamic>> parametrosPorManual = {
      // Parâmetros para IAC-B100-2022-SP (Manual de SP)
      'IAC-B100-2022-SP': {
        'produtividadeMinima': 4.0, // t/ha
        'produtividadeMaxima': 15.0, // t/ha
        'saturacaoBasesIdeal': 70.0, // V% ideal
        'teorMinimoMagnesio': 8.0, // mmolc/dm³

        // Parâmetros calagem
        'parametrosCalagem': {
          'prnt_padrao': 80.0,
          'profundidade_minima': 20.0,
          'profundidade_maxima': 40.0,
          'profundidade_incorporacao': 20.0,
          'dose_maxima_aplicacao': 6.0, // t/ha por aplicação
          'prazo_minimo_aplicacao': 60, // dias antes do plantio
          'saturacao_bases_minima': 50.0, // % mínima
          'saturacao_bases_ideal': 70.0, // % ideal
          'relacao_ca_mg_minima': 2.0,
          'relacao_ca_mg_maxima': 4.0,
        },

        // Parâmetros gessagem
        'parametrosGessagem': {
          'necessidade_gesso': 0.0,        // Não usa fator argila para milho
          'profundidade_avaliacao': 40.0,  // Camada 20-40 cm
          'teor_calcio_min': 4.0,          // Limite para Ca subsuperficial
          'teor_sulfato_min': 10.0,        // Limite S [mg/dm³] - ajustado
          'saturacao_al_max': 20.0,        // Limite m% [% CTCe]
          'dose_maxima': 10.0,             // Limite geral [t/ha]
          'saturacao_bases_min': 50.0,     // V% minima recomendada
          'taxaS_porProdutividade_kgHa_por_Ton': 3.3, // 3.3 kg S/ton produtividade
          'doseFixa_por_S_baixo_tHa': 0.0, // Não usa dose fixa
          'teorS_Gesso_assumido_decimal': 0.17, // 17% S no gesso agrícola
        },

        // Parâmetros manejo
        'espacamentoEntrelinhasMin': 45, // cm
        'espacamentoEntrelinhasMax': 75, // cm
        'populacaoMinima': 50000, // plantas/ha
        'populacaoMaxima': 70000, // plantas/ha
        'permiteParcelamentoN': true,
        'permiteIrrigacao': true,

        // SOLUÇÃO - Adicionar teores críticos para N (simplificados para funcionar com estrutura atual)
        'teoresCriticosMacro': {
          // Criar faixas para N baseadas nas classes de resposta (V%)
          'N': {
            'baixo': 0, // placeholder para classe 'alta'
            'medio': 50.0, // V% que separa classe 'alta' de 'media_baixa'
            'alto': 100.0 // valor máximo teórico
          },
          'P2O5': {
            'muito_baixo': 16.0, // mg/dm³
            'baixo': 40.0,
            'adequado': 80.0,
          },
          'K2O': {
            'muito_baixo': 1.6, // mmolc/dm³
            'baixo': 3.0,
            'medio': 5.0,
            'adequado': 6.0,
          },
          'Ca': {
            'baixo': 4.0,
            'medio': 8.0,
            'alto': 15.0,
          },
          'Mg': {
            'baixo': 5.0,
            'medio': 8.0,
            'alto': 12.0,
          },
          'S': {
            'baixo': 10.0,
            'medio': 15.0, 
            'alto': 20.0,
          },
        },

        // Teores críticos micronutrientes
        'teoresCriticosMicro': {
          'B': {
            'baixo': 0.2,
            'medio': 0.6,
          },
          'Cu': {
            'baixo': 0.3,
            'medio': 0.8,
          },
          'Fe': {
            'baixo': 4.0,
            'medio': 12.0,
          },
          'Mn': {
            'baixo': 1.2,
            'medio': 5.0,
          },
          'Zn': {
            'baixo': 0.6,
            'medio': 1.2,
          },
        },

        // SOLUÇÃO - Estrutura adaptada para N compatível com o NutrienteCalculator atual
        'recomendacaoNPK': {
          // Estrutura adaptada para N
          'N': {
            6.0: {
              'baixo': 90.0, // baixo = classe alta (V% < 50)
              'medio': 60.0, // medio = classe media_baixa (V% >= 50)
              'alto': 60.0,  // redundante, para completude
            },
            8.0: {
              'baixo': 120.0,
              'medio': 90.0,
              'alto': 90.0,
            },
            10.0: {
              'baixo': 160.0,
              'medio': 120.0,
              'alto': 120.0,
            },
            12.0: {
              'baixo': 200.0,
              'medio': 140.0,
              'alto': 140.0,
            },
            999.0: {
              'baixo': 220.0,
              'medio': 160.0,
              'alto': 160.0,
            },
          },
          'P2O5': {
            6.0: {
              'muito_baixo': 90.0,
              'baixo': 60.0,
              'adequado': 30.0
            },
            8.0: {
              'muito_baixo': 100.0,
              'baixo': 70.0,
              'adequado': 40.0
            },
            10.0: {
              'muito_baixo': 120.0,
              'baixo': 90.0,
              'adequado': 60.0
            },
            12.0: {
              'muito_baixo': 140.0,
              'baixo': 110.0,
              'adequado': 70.0
            },
            999.0: {
              'muito_baixo': 160.0,
              'baixo': 120.0,
              'adequado': 80.0
            },
          },
          'K2O': {
            6.0: {
              'muito_baixo': 70.0,
              'baixo': 40.0,
              'adequado': 30.0
            },
            8.0: {
              'muito_baixo': 90.0,
              'baixo': 50.0,
              'adequado': 30.0
            },
            10.0: {
              'muito_baixo': 100.0,
              'baixo': 70.0,
              'adequado': 40.0
            },
            12.0: {
              'muito_baixo': 110.0,
              'baixo': 90.0,
              'adequado': 50.0
            },
            999.0: {
              'muito_baixo': 120.0,
              'baixo': 100.0,
              'adequado': 60.0
            },
          },
        },

        // Recomendação micronutrientes
        'recomendacaoMicro': {
          'B': {'<0.2': 2.0, '0.2-0.6': 1.0, '>0.6': 0.0},
          'Cu': {'<0.3': 1.0, '0.3-0.8': 0.5, '>0.8': 0.0},
          'Mn': {'<1.2': 2.0, '1.2-5.0': 1.0, '>5.0': 0.0},
          'Zn': {'<0.6': 4.0, '0.6-1.2': 2.0, '>1.2': 0.0},
        },

        // Faixas de interpretação textura
        'faixasTextura': {
          'arenoso': 150.0, // g/kg argila
          'medio': 350.0,
          'argiloso': 600.0,
        },

        // Demais parâmetros permanecem inalterados...
        'limitesMaximosNutrientes': {
          'N': 220.0,
          'P2O5': 160.0,
          'K2O': 120.0,
          'Zn': 4.0,
          'B': 2.0,
          'Cu': 1.0,
          'Mn': 2.0,
        },

        'limitesMaximosSulco': {
          'N+K2O': 80.0,
          'K2O': 60.0,
          'B': 1.0,
          'Zn': 2.0,
        },

        'fontesNutrientes': {
          'N': ['Ureia', 'Nitrato de Amônio', 'Sulfato de Amônio', 'SAM'],
          'P2O5': ['Superfosfato Simples', 'Superfosfato Triplo', 'MAP', 'DAP'],
          'K2O': ['Cloreto de Potássio', 'Sulfato de Potássio'],
          'S': ['Sulfato de Amônio', 'Superfosfato Simples', 'Gesso Agrícola'],
          'Zn': ['Sulfato de Zinco', 'Óxido de Zinco', 'Quelatos'],
          'B': ['Ácido Bórico', 'Bórax', 'Ulexita'],
          'Cu': ['Sulfato de Cobre', 'Óxido de Cobre', 'Quelatos'],
          'Mn': ['Sulfato de Manganês', 'Óxido de Manganês', 'Quelatos'],
        },

        'fatorAjusteDoses': {
          'textura': {
            'arenoso': 0.8,
            'medio': 1.0,
            'argiloso': 1.2,
          },
          'materia_organica': {
            'baixo': 1.1,
            'medio': 1.0,
            'alto': 0.9,
          },
          'irrigacao': {
            'N': 1.2,
            'K2O': 1.1,
            'padrao': 1.0,
          },
        },

        'epocasAplicacao': {
          'N_PLANT': {
            'dias': 0,
            'descricao': 'Plantio (30-60 kg/ha)',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': 60.0,
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar de 30 a 60 kg/ha de N no plantio.'
                ],
                'arenoso': [
                  'Em solos arenosos, atenção à lixiviação do N. Considerar uso de inibidor de nitrificação.'
                ],
                'argiloso': [
                  'Em solos argilosos com espaçamento reduzido, pode-se chegar até 60 kg/ha de N no plantio.'
                ]
              }
            }
          },
          'N_COB1': {
            'dias': 25,
            'descricao': 'Cobertura 1 (estádio V4-V5)',
            'modoAplicacao': 'LANCO_COBERTURA',
            'limiteMaximo': 80.0,
            'prioridade': 2,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar no estádio V4-V5 (4-5 folhas completamente desenvolvidas).',
                  'O restante da dose pode ser complementado com a primeira cobertura de N.'
                ],
                'irrigado': [
                  'Em áreas irrigadas, aplicar após irrigação para melhor aproveitamento.'
                ],
                'sequeiro': [
                  'Aplicar preferencialmente com solo úmido ou com previsão de chuva.'
                ]
              }
            }
          },
          'N_COB2': {
            'dias': 40,
            'descricao': 'Cobertura 2 (estádio V6-V7)',
            'modoAplicacao': 'LANCO_COBERTURA',
            'limiteMaximo': null,
            'prioridade': 3,
            'aplicacaoPrincipal': false,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar no estádio V6-V7 (6-7 folhas completamente desenvolvidas).',
                  'Recomendado apenas para doses totais de N superiores a 120 kg/ha.'
                ],
                'irrigado': [
                  'Em áreas irrigadas, o parcelamento em três aplicações é mais eficiente.',
                  'Pode ser aplicado via água de irrigação (fertirrigação) para melhor eficiência.'
                ]
              }
            }
          },
          'P_PLANT': {
            'dias': 0,
            'descricao': 'Plantio (Total)',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 1,
            'percentualDose': 100.0,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar todo o fósforo no plantio para melhor aproveitamento pela cultura.'
                ],
                'argiloso': [
                  'Em solos argilosos, preferir aplicação localizada para reduzir fixação de P.',
                  'Em solos argilosos com alto teor de argila, considerar aumento de 20% na dose.'
                ],
                'arenoso': [
                  'Em solos arenosos, aplicar no sulco de plantio para reduzir perdas.'
                ]
              }
            }
          },
          'K_PLANT': {
            'dias': 0,
            'descricao': 'Plantio (Parte)',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': 60.0,
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Não aplicar mais de 60 kg/ha de K₂O no sulco para evitar efeito salino.'
                ],
                'arenoso': [
                  'Em solos arenosos, limitar dose no sulco e aplicar o restante em cobertura para reduzir lixiviação.'
                ]
              }
            }
          },
          'K_COB1': {
            'dias': 25,
            'descricao': 'Cobertura 1 (Restante)',
            'modoAplicacao': 'LANCO_COBERTURA',
            'limiteMaximo': null,
            'prioridade': 2,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar junto com a primeira cobertura de N, pois aplicações tardias desse elemento são pouco eficientes.'
                ],
                'arenoso': [
                  'Em solos arenosos, a aplicação parcelada de K₂O reduz perdas por lixiviação.'
                ]
              }
            }
          },
          'K_PRE': {
            'dias': -15,
            'descricao': 'Pré-Plantio',
            'modoAplicacao': 'LANCO_PRE_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 0,
            'aplicacaoPrincipal': false,
            'parametrosAdicionais': {
              'observacoes': {
                'argiloso': [
                  'Em solos argilosos com teor de K baixo (<1,6 mmolc/dm³) e doses ≥80 kg/ha, recomenda-se transferir parte ou toda adubação potássica para pré-plantio.'
                ],
                'arenoso': [
                  'Em solos arenosos, NÃO é recomendado aplicar todo o K em pré-plantio devido ao alto risco de lixiviação.'
                ]
              }
            }
          },
          'S_PLANT': {
            'dias': 0,
            'descricao': 'Plantio (via NPK ou fonte)',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar 20 kg/ha de S para metas de produtividade até 8 t/ha e 40 kg/ha para produtividades superiores.',
                  'Pode ser aplicado via formulações NPK com S ou fontes específicas.'
                ]
              }
            }
          },
          'S_PRE': {
            'dias': -15,
            'descricao': 'Pré-Plantio (15 dias antes)',
            'modoAplicacao': 'LANCO_PRE_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 0,
            'aplicacaoPrincipal': false,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Quando não for feita a gessagem, aplicar 20-40 kg/ha de S se o solo apresentar teor de S inferior a 10 mg/dm³.',
                  'Pode ser aplicado via gesso agrícola que também é excelente fonte de S.'
                ]
              }
            }
          },
          'MICRO_PLANT': {
            'dias': 0,
            'descricao': 'Plantio (via NPK ou fonte)',
            'modoAplicacao': 'SULCO_PLANTIO',
            'limiteMaximo': null,
            'prioridade': 1,
            'aplicacaoPrincipal': true,
            'parametrosAdicionais': {
              'observacoes': {
                'geral': [
                  'Aplicar micronutrientes junto com o fertilizante NPK no plantio.'
                ],
                'Zn': [
                  'Utilizar 4 kg/ha de Zn em solos com teores inferiores a 0,6 mg/dm³ e 2 kg/ha em solos com teores entre 0,6 e 1,2 mg/dm³.',
                  'O Zinco é essencial para o desenvolvimento inicial da cultura do milho.'
                ],
                'B': [
                  'Aplicar 2 kg/ha de B em áreas com histórico de deficiência e/ou altas produtividades.',
                  'O Boro é pouco móvel na planta e aplicações foliares são recomendadas apenas no estádio de pré-florescimento.'
                ],
                'Cu': [
                  'Aplicar 1 kg/ha de Cu em solos com teores inferiores a 0,3 mg/dm³.'
                ],
                'Mn': [
                  'Aplicar 2 kg/ha de Mn em solos com teores inferiores a 1,2 mg/dm³.'
                ]
              }
            }
          }
        },

        'restricoesAplicacao': [
          'N+K2O no sulco não exceder 80 kg/ha (até 100 kg/ha em argiloso/espaç. reduzido).',
          'Não aplicar K2O se teor no solo > 6.0 mmolc/dm³.',
          'Parcelar N em cobertura se dose total for alta (ver texto p. 204).',
          'Aplicar restante do K2O junto com a primeira cobertura de N.',
          'Evitar aplicar Sulfato de Amônio se N+K2O no sulco > 80 kg/ha.',
          'Cuidados com aplicação foliar de Zn (concentração, horário).',
          'Aplicação foliar de B recomendada apenas pré-florescimento em alta produtividade.',
        ],

        'observacoesManejo': [
          'Aplicar calcário 60-90 dias antes do plantio.',
          'Aplicar 20-40 kg/ha de Enxofre (S) via NPK ou fontes específicas.',
          'Realizar adubação com Zinco (2-4 kg/ha) se necessário conforme análise.',
          'Considerar adubação com Boro (1-2 kg/ha) em áreas de alta produtividade ou histórico de deficiência.',
          'Ajustar adubação potássica para milho silagem na cultura subsequente.',
          'Manejo de N em cobertura varia com dose total e sistema (irrigado/sequeiro/safrinha).',
          'Para milho safrinha após soja (plantio direto), classe de resposta a N é Média/Baixa.',
        ],

        'observacoesGerais': [
          'Planejar adubação considerando o sistema de produção (rotação/sucessão).',
          'Altas produtividades são improváveis com P muito baixo no solo.',
          'Considerar classe de resposta a N (Alta vs Média/Baixa) para definir dose total de N.',
          'Adubação de sistemas é preferível para K em solos férteis em rotação com soja.',
        ],
      },
    };

    // Resto do método permanece igual
    final parametros = parametrosPorManual[manualAdubacao] ?? parametrosPorManual[MANUAL_PADRAO]!;
    
    print('Usando manual: ${parametrosPorManual.containsKey(manualAdubacao) ? manualAdubacao : MANUAL_PADRAO} para cultura Milho Grão');
    
    return CulturaParametros(
      id: id,
      manualAdubacao: manualAdubacao,
      cultura: TipoCultura.MILHO_GRAO,
      produtividadeMinima: parametros['produtividadeMinima'],
      produtividadeMaxima: parametros['produtividadeMaxima'],
      saturacaoBasesIdeal: parametros['saturacaoBasesIdeal'],
      teorMinimoMagnesio: parametros['teorMinimoMagnesio'],
      parametrosCalagem: Map<String, dynamic>.from(parametros['parametrosCalagem']),
      parametrosGessagem: Map<String, dynamic>.from(parametros['parametrosGessagem']),
      espacamentoEntrelinhasMin: parametros['espacamentoEntrelinhasMin'],
      espacamentoEntrelinhasMax: parametros['espacamentoEntrelinhasMax'],
      populacaoMinima: parametros['populacaoMinima'],
      populacaoMaxima: parametros['populacaoMaxima'],
      permiteParcelamentoN: parametros['permiteParcelamentoN'],
      permiteIrrigacao: parametros['permiteIrrigacao'],
      teoresCriticosMacro: _converterMapaNestedDouble(parametros['teoresCriticosMacro']),
      teoresCriticosMicro: _converterMapaNestedDouble(parametros['teoresCriticosMicro']),
      recomendacaoNPK: _converterRecomendacaoNPK(parametros['recomendacaoNPK']),
      recomendacaoMicro: _converterMapaNestedDouble(parametros['recomendacaoMicro']),
      faixasTextura: Map<String, double>.from(parametros['faixasTextura']),
      limitesMaximosNutrientes: Map<String, double>.from(parametros['limitesMaximosNutrientes']),
      limitesMaximosSulco: Map<String, double>.from(parametros['limitesMaximosSulco']),
      fontesNutrientes: _converterFontesNutrientes(parametros['fontesNutrientes']),
      fatorAjusteDoses: _converterFatorAjuste(parametros['fatorAjusteDoses']),
      epocasAplicacao: _converterEpocasAplicacao(parametros['epocasAplicacao']),
      restricoesAplicacao: List<String>.from(parametros['restricoesAplicacao']),
      observacoesManejo: List<String>.from(parametros['observacoesManejo']),
      observacoesGerais: List<String>.from(parametros['observacoesGerais']),
    );
  }

  /// Método auxiliar para converter recomendações NPK
  static Map<String, Map<double, Map<String, double>>> _converterRecomendacaoNPK(
      Map<String, dynamic> recomendacaoNPK) {
    final Map<String, Map<double, Map<String, double>>> result = {};

    recomendacaoNPK.forEach((nutriente, prodMap) {
      final Map<double, Map<String, double>> prodMapConverted = {};

      (prodMap as Map<dynamic, dynamic>).forEach((prod, interpMap) {
        final double prodDouble = prod is double ? prod : double.parse(prod.toString());
        final Map<String, double> interpMapConverted = {};

        (interpMap as Map<dynamic, dynamic>).forEach((interp, value) {
          final double valueDouble = value is double ? value : double.parse(value.toString());
          interpMapConverted[interp.toString()] = valueDouble;
        });

        prodMapConverted[prodDouble] = interpMapConverted;
      });

      result[nutriente.toString()] = prodMapConverted;
    });

    return result;
  }

  /// Método auxiliar para converter mapas aninhados de doubles
  static Map<String, Map<String, double>> _converterMapaNestedDouble(
      Map<String, dynamic> mapaAninhado) {
    final Map<String, Map<String, double>> result = {};

    mapaAninhado.forEach((chave, valorMap) {
      final Map<String, double> valorMapConverted = {};

      (valorMap as Map<dynamic, dynamic>).forEach((subChave, valor) {
        final double valorDouble = valor is double ? valor : double.parse(valor.toString());
        valorMapConverted[subChave.toString()] = valorDouble;
      });

      result[chave.toString()] = valorMapConverted;
    });

    return result;
  }

  /// Método auxiliar para converter fontes de nutrientes
  static Map<String, List<String>> _converterFontesNutrientes(
      Map<String, dynamic> fontesNutrientes) {
    final Map<String, List<String>> result = {};

    fontesNutrientes.forEach((nutriente, fontes) {
      result[nutriente.toString()] = List<String>.from(fontes);
    });

    return result;
  }

  /// Método auxiliar para converter fatores de ajuste
  static Map<String, Map<String, double>> _converterFatorAjuste(
      Map<String, dynamic> fatorAjuste) {
    final Map<String, Map<String, double>> result = {};

    fatorAjuste.forEach((categoria, fatores) {
      final Map<String, double> fatoresConverted = {};

      (fatores as Map<dynamic, dynamic>).forEach((condicao, fator) {
        final double fatorDouble = fator is double ? fator : double.parse(fator.toString());
        fatoresConverted[condicao.toString()] = fatorDouble;
      });

      result[categoria.toString()] = fatoresConverted;
    });

    return result;
  }

  /// Método auxiliar para converter épocas de aplicação
  static Map<String, EpocaAplicacao> _converterEpocasAplicacao(
      Map<String, dynamic> epocasAplicacao) {
    final Map<String, EpocaAplicacao> result = {};

    epocasAplicacao.forEach((codigo, dados) {
      Map<String, dynamic> dadosMap;

      // Verificar se dados já é um Map<String, dynamic>
      if (dados is Map<String, dynamic>) {
        dadosMap = dados;
      } else if (dados is Map) {
        // Converter para Map<String, dynamic> se for outro tipo de Map
        dadosMap = Map<String, dynamic>.from(dados);
      } else {
        print("Erro: dados para código $codigo não é um mapa");
        return; // Skip this item
      }

      // Obter modoAplicacao do mapa ou inferir baseado no código
      String modoStr = dadosMap['modoAplicacao']?.toString() ?? '';

      // Se não há modoAplicacao explícito, inferir do código
      if (modoStr.isEmpty) {
        if (codigo.contains('PLANT')) {
          modoStr = 'SULCO_PLANTIO';
        } else if (codigo.contains('COB')) {
          modoStr = 'LANCO_COBERTURA';
        } else if (codigo.contains('PRE')) {
          modoStr = 'LANCO_PRE_PLANTIO';
        } else {
          modoStr = 'NAO_ESPECIFICADO';
        }
      }

      // Converter string para enum ModoAplicacao
      ModoAplicacao modoAplicacao = ModoAplicacao.fromString(modoStr);

      // Extrair parâmetros adicionais se existirem
      Map<String, dynamic>? paramsAdicionais;
      if (dadosMap.containsKey('parametrosAdicionais') && dadosMap['parametrosAdicionais'] is Map) {
        paramsAdicionais = Map<String, dynamic>.from(dadosMap['parametrosAdicionais']);
      }

      // Criar objeto EpocaAplicacao com todos os campos
      result[codigo] = EpocaAplicacao(
        dias: dadosMap['dias'] is int ? dadosMap['dias'] : (dadosMap['dias'] as num?)?.toInt() ?? 0,
        descricao: dadosMap['descricao']?.toString() ?? '',
        modoAplicacao: modoAplicacao,
        limiteMaximo: dadosMap['limiteMaximo'] is double ? dadosMap['limiteMaximo'] :
        (dadosMap['limiteMaximo'] as num?)?.toDouble(),
        prioridade: dadosMap['prioridade'] is int ? dadosMap['prioridade'] :
        (dadosMap['prioridade'] as num?)?.toInt() ?? 0,
        percentualDose: dadosMap['percentualDose'] is double ? dadosMap['percentualDose'] :
        (dadosMap['percentualDose'] as num?)?.toDouble(),
        aplicacaoPrincipal: dadosMap['aplicacaoPrincipal'] as bool? ?? true,
        parametrosAdicionais: paramsAdicionais,
      );
    });

    return result;
  }
}