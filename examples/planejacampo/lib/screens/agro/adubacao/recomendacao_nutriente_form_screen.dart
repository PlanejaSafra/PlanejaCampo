import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';

class RecomendacaoNutrienteFormScreen extends StatefulWidget {
  final String recomendacaoId;
  final RecomendacaoNutriente? nutriente;
  final ResultadoAnaliseSolo? analise;
  final TipoCultura? tipoCultura;

  const RecomendacaoNutrienteFormScreen({
    Key? key,
    required this.recomendacaoId,
    this.nutriente,
    this.analise,
    this.tipoCultura,
  }) : super(key: key);

  @override
  _RecomendacaoNutrienteFormScreenState createState() => _RecomendacaoNutrienteFormScreenState();
}

class _RecomendacaoNutrienteFormScreenState extends State<RecomendacaoNutrienteFormScreen> {
  // Controllers
  final TextEditingController _nutrienteController = TextEditingController();
  final TextEditingController _interpretacaoController = TextEditingController();
  final TextEditingController _teorController = TextEditingController();
  final TextEditingController _doseRecomendadaController = TextEditingController();
  final TextEditingController _fonteController = TextEditingController();
  final TextEditingController _eficienciaController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  // State
  final List<String> _restricoes = [];

  // Listas de opções
  final List<String> _opcoesNutrientes = [
    'N', 'P2O5', 'K2O', 'Ca', 'Mg', 'S', 'B', 'Cu', 'Fe', 'Mn', 'Zn', 'Mo'
  ];

  final List<String> _opcoesInterpretacao = [
    'Muito Baixo', 'Baixo', 'Médio', 'Alto', 'Muito Alto'
  ];

  final Map<String, List<String>> _opcoesFontes = {
    'N': ['Ureia', 'Sulfato de Amônio', 'Nitrato de Amônio', 'Nitrato de Cálcio'],
    'P': ['Superfosfato Simples', 'Superfosfato Triplo', 'MAP', 'DAP', 'Fosfato Natural'],
    'K': ['Cloreto de Potássio', 'Sulfato de Potássio', 'Nitrato de Potássio'],
    'Ca': ['Calcário Calcítico', 'Gesso Agrícola', 'Nitrato de Cálcio'],
    'Mg': ['Calcário Dolomítico', 'Óxido de Magnésio', 'Sulfato de Magnésio'],
    'S': ['Sulfato de Amônio', 'Superfosfato Simples', 'Gesso Agrícola', 'Sulfato de Potássio'],
    'B': ['Bórax', 'Ácido Bórico', 'Solubor'],
    'Cu': ['Sulfato de Cobre', 'Óxido de Cobre', 'Quelato de Cobre'],
    'Fe': ['Sulfato de Ferro', 'Quelato de Ferro', 'Óxido de Ferro'],
    'Mn': ['Sulfato de Manganês', 'Óxido de Manganês', 'Quelato de Manganês'],
    'Zn': ['Sulfato de Zinco', 'Óxido de Zinco', 'Quelato de Zinco'],
    'Mo': ['Molibdato de Sódio', 'Molibdato de Amônio'],
  };

  // Restrições possíveis
  final List<String> _todasRestricoes = [
    'Aplicar antes do plantio',
    'Aplicar após o plantio',
    'Parcelar em múltiplas aplicações',
    'Evitar aplicação em solo úmido',
    'Aplicar via foliar',
    'Não misturar com calcário',
    'Não misturar com outros fertilizantes',
    'Aplicar com solo seco',
    'Incorporar ao solo',
    'Aplicar em cobertura',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    // Se for edição, preencher com valores existentes
    if (widget.nutriente != null) {
      _nutrienteController.text = widget.nutriente!.nutriente;
      _teorController.text = widget.nutriente!.teor.toStringAsFixed(2);
      _interpretacaoController.text = widget.nutriente!.interpretacao;
      _doseRecomendadaController.text = widget.nutriente!.doseRecomendada.toStringAsFixed(2);

      if (widget.nutriente!.fonte != null) {
        _fonteController.text = widget.nutriente!.fonte!;
      }

      if (widget.nutriente!.eficiencia != null) {
        _eficienciaController.text = widget.nutriente!.eficiencia!.toStringAsFixed(2);
      }

      // Copiar restrições
      _restricoes.addAll(widget.nutriente!.restricoes);

      if (widget.nutriente!.observacoes.isNotEmpty) {
        _observacoesController.text = widget.nutriente!.observacoes.join('\n');
      }
    }
    // Se temos análise e nova recomendação, tentar preencher com valores da análise
    else if (widget.analise != null) {
      _preencherComValoresAnalise();
    }
  }

  void _preencherComValoresAnalise() {
    // Esta é uma função simplificada. Na implementação completa, você teria uma lógica
    // mais complexa para extrair valores específicos da análise de solo dependendo
    // do nutriente selecionado.

    // Exemplo: Se nutriente selecionado for P, buscar valor de P da análise
    if (_nutrienteController.text == 'P' && widget.analise != null) {
      _teorController.text = widget.analise!.fosforo.toStringAsFixed(2);
      _classificarInterpretacao();
    }
    // Para K
    else if (_nutrienteController.text == 'K' && widget.analise != null) {
      _teorController.text = widget.analise!.potassio.toStringAsFixed(2);
      _classificarInterpretacao();
    }
    // E assim por diante para outros nutrientes...

    // Calcular dose recomendada baseada na interpretação e tipo de cultura
    if (_interpretacaoController.text.isNotEmpty && widget.tipoCultura != null) {
      _calcularDoseRecomendada();
    }
  }

  void _classificarInterpretacao() {
    // Esta é uma função simplificada para classificar a interpretação
    // Na implementação real, você teria tabelas de referência por nutriente e cultura

    try {
      final double teor = double.parse(_teorController.text);

      // Exemplo para fósforo (P)
      if (_nutrienteController.text == 'P') {
        if (teor < 3.0) {
          _interpretacaoController.text = 'Muito Baixo';
        } else if (teor < 6.0) {
          _interpretacaoController.text = 'Baixo';
        } else if (teor < 12.0) {
          _interpretacaoController.text = 'Médio';
        } else if (teor < 25.0) {
          _interpretacaoController.text = 'Alto';
        } else {
          _interpretacaoController.text = 'Muito Alto';
        }
      }
      // Exemplo para potássio (K)
      else if (_nutrienteController.text == 'K') {
        if (teor < 0.8) {
          _interpretacaoController.text = 'Muito Baixo';
        } else if (teor < 1.5) {
          _interpretacaoController.text = 'Baixo';
        } else if (teor < 3.0) {
          _interpretacaoController.text = 'Médio';
        } else if (teor < 6.0) {
          _interpretacaoController.text = 'Alto';
        } else {
          _interpretacaoController.text = 'Muito Alto';
        }
      }
      // E assim por diante para outros nutrientes...

      // Após classificar, calcular dose recomendada
      _calcularDoseRecomendada();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).error_calculating_value(e.toString()))),
      );
    }
  }

  void _calcularDoseRecomendada() {
    // Esta é uma função simplificada para calcular a dose recomendada
    // Na implementação real, você teria tabelas de recomendação por nutriente, cultura e nível de interpretação

    try {
      // Simplificação: para cada nível de interpretação, reduzir a dose
      double doseBase = 0.0;

      // Para cada nutriente, definir uma dose base diferente
      if (_nutrienteController.text == 'N') {
        doseBase = 80.0; // kg/ha
      } else if (_nutrienteController.text == 'P') {
        doseBase = 100.0; // kg/ha de P2O5
      } else if (_nutrienteController.text == 'K') {
        doseBase = 90.0; // kg/ha de K2O
      } else if (_opcoesNutrientes.contains(_nutrienteController.text)) {
        // Para outros nutrientes
        doseBase = 50.0; // valor genérico
      }

      // Ajustar com base na interpretação
      double fatorAjuste = 1.0;

      if (_interpretacaoController.text == 'Muito Baixo') {
        fatorAjuste = 1.5; // Aumenta 50%
      } else if (_interpretacaoController.text == 'Baixo') {
        fatorAjuste = 1.2; // Aumenta 20%
      } else if (_interpretacaoController.text == 'Médio') {
        fatorAjuste = 1.0; // Mantém igual
      } else if (_interpretacaoController.text == 'Alto') {
        fatorAjuste = 0.7; // Reduz 30%
      } else if (_interpretacaoController.text == 'Muito Alto') {
        fatorAjuste = 0.5; // Reduz 50%
      }

      // Ajustar com base no tipo de cultura
      if (widget.tipoCultura != null) {
        // Exemplo: ajuste para diferentes culturas
        if (widget.tipoCultura == TipoCultura.SOJA) {
          if (_nutrienteController.text == 'N') {
            doseBase = 0.0; // Soja não precisa de N mineral
          }
        } else if (widget.tipoCultura == TipoCultura.MILHO_GRAO) {
          if (_nutrienteController.text == 'N') {
            doseBase = 120.0; // Milho precisa de mais N
          }
        }
        // Outros ajustes para culturas específicas...
      }

      // Calcular dose final
      double doseRecomendada = doseBase * fatorAjuste;

      // Atualizar campo
      setState(() {
        _doseRecomendadaController.text = doseRecomendada.toStringAsFixed(2);
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).error_calculating_value(e.toString()))),
      );
    }
  }

  // Valida se os campos obrigatórios estão preenchidos
  bool _validarCampos() {
    String? errorMessage;

    if (_nutrienteController.text.isEmpty) {
      errorMessage = S.of(context).select_nutrient;
    } else if (_teorController.text.isEmpty) {
      errorMessage = S.of(context).enter_content;
    } else if (_interpretacaoController.text.isEmpty) {
      errorMessage = S.of(context).enter_interpretation;
    } else if (_doseRecomendadaController.text.isEmpty) {
      errorMessage = S.of(context).enter_recommended_dose;
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    }

    return true;
  }

  // Exibe diálogo de seleção para restrições
  Future<void> _selecionarRestricoes() async {
    final List<String> restricoesTemp = List.from(_restricoes);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(S.of(context).select_restrictions),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _todasRestricoes.map((restricao) {
                  return CheckboxListTile(
                    title: Text(restricao),
                    value: restricoesTemp.contains(restricao),
                    onChanged: (checked) {
                      setState(() {
                        if (checked!) {
                          if (!restricoesTemp.contains(restricao)) {
                            restricoesTemp.add(restricao);
                          }
                        } else {
                          restricoesTemp.remove(restricao);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(S.of(context).cancel),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _restricoes.clear();
                    _restricoes.addAll(restricoesTemp);
                  });
                  Navigator.of(context).pop();
                },
                child: Text(S.of(context).confirm),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Verificar e adicionar nutrientes ou interpretações ausentes nas listas
    if (widget.nutriente != null) {
      if (!_opcoesNutrientes.contains(widget.nutriente!.nutriente)) {
        _opcoesNutrientes.add(widget.nutriente!.nutriente);
      }

      if (!_opcoesInterpretacao.contains(widget.nutriente!.interpretacao)) {
        _opcoesInterpretacao.add(widget.nutriente!.interpretacao);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nutriente == null
            ? S.of(context).add_nutrient_recommendation
            : S.of(context).edit_nutrient_recommendation),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              if (_validarCampos()) {
                final appStateManager = Provider.of<AppStateManager>(context, listen: false);

                final RecomendacaoNutriente nutriente = RecomendacaoNutriente(
                  id: widget.nutriente?.id ?? DateTime.now().toString(),
                  recomendacaoId: widget.recomendacaoId,
                  produtorId: appStateManager.activeProdutorId ?? '',
                  propriedadeId: appStateManager.activePropriedadeId ?? '',
                  nutriente: _nutrienteController.text,
                  teor: double.parse(_teorController.text),
                  interpretacao: _interpretacaoController.text,
                  doseRecomendada: double.parse(_doseRecomendadaController.text),
                  fonte: _fonteController.text.isNotEmpty ? _fonteController.text : null,
                  eficiencia: _eficienciaController.text.isNotEmpty
                      ? double.parse(_eficienciaController.text)
                      : null,
                  restricoes: _restricoes,
                  observacoes: _observacoesController.text.isNotEmpty
                      ? _observacoesController.text.split('\n').where((line) => line.trim().isNotEmpty).toList()
                      : [],
                );

                Navigator.of(context).pop(nutriente);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Identificação do Nutriente
            _buildSectionHeader(context, S.of(context).nutrient_identification, Icons.science),

            // Seleção de Nutriente
            _buildDropdownField(
              context: context,
              value: _nutrienteController.text.isEmpty ? null : _nutrienteController.text,
              items: _opcoesNutrientes,
              labelText: S.of(context).nutrient,
              onChanged: (String? value) {
                if (value != null && value != _nutrienteController.text) {
                  setState(() {
                    _nutrienteController.text = value;
                    // Limpar fonte ao mudar de nutriente
                    _fonteController.text = '';
                    // Tentar preencher com valores da análise
                    if (widget.analise != null) {
                      _preencherComValoresAnalise();
                    }
                  });
                }
              },
            ),

            SizedBox(height: 16),

            // Dados da Análise
            _buildSectionHeader(context, S.of(context).analysis_data, Icons.analytics),

            // Teor do Nutriente
            _buildNumberField(
              context: context,
              controller: _teorController,
              labelText: S.of(context).content,
              helperText: S.of(context).nutrient_content_in_soil,
              onChanged: (_) => _classificarInterpretacao(),
            ),

            // Interpretação
            _buildDropdownField(
              context: context,
              value: _interpretacaoController.text.isEmpty ? null : _interpretacaoController.text,
              items: _opcoesInterpretacao,
              labelText: S.of(context).interpretation,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _interpretacaoController.text = value;
                    _calcularDoseRecomendada();
                  });
                }
              },
            ),

            SizedBox(height: 24),

            // Recomendação
            _buildSectionHeader(context, S.of(context).recommendation, Icons.recommend),

            // Dose Recomendada
            _buildNumberField(
              context: context,
              controller: _doseRecomendadaController,
              labelText: S.of(context).recommended_dose,
              helperText: S.of(context).nutrient_kilograms_per_hectare,
              suffix: 'kg/ha',
            ),

            // Fonte do Nutriente
            _buildDropdownField(
              context: context,
              value: _fonteController.text.isEmpty ? null : _fonteController.text,
              items: _nutrienteController.text.isNotEmpty && _opcoesFontes.containsKey(_nutrienteController.text)
                  ? _opcoesFontes[_nutrienteController.text]!
                  : [],
              labelText: S.of(context).nutrient_source,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _fonteController.text = value;
                  });
                }
              },
            ),

            // Eficiência
            _buildNumberField(
              context: context,
              controller: _eficienciaController,
              labelText: S.of(context).application_efficiency,
              helperText: S.of(context).nutrient_utilization_percentage,
              suffix: '%',
            ),

            SizedBox(height: 16),

            // Restrições
            _buildSectionHeader(context, S.of(context).restrictions, Icons.warning),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            S.of(context).application_restrictions,
                            style: Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8), // Espaçamento entre o texto e o botão
                        ElevatedButton.icon(
                          onPressed: _selecionarRestricoes,
                          icon: Icon(Icons.edit),
                          label: Text(S.of(context).select),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    if (_restricoes.isEmpty)
                      Text(
                        S.of(context).no_restrictions_selected,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _restricoes.map((restricao) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.secondary),
                                SizedBox(width: 8),
                                Expanded(child: Text(restricao)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Observações
            _buildSectionHeader(context, S.of(context).observations, Icons.note),

            TextFormField(
              controller: _observacoesController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).observations,
              ),
              maxLines: 3,
            ),

            SizedBox(height: 24),

            // Botão de Cálculo
            ElevatedButton.icon(
              onPressed: _calcularDoseRecomendada,
              icon: Icon(Icons.calculate),
              label: Text(S.of(context).calculate_recommended_dose),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    String? helperText,
    String? suffix,
    void Function(String)? onChanged,
    bool isInt = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: ObjectTemplate.getInputDecoration(
          context,
          labelText,
        ).copyWith(
          helperText: helperText,
          suffixText: suffix,
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String? value,
    required List<String> items,
    required String labelText,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: ObjectTemplate.getInputDecoration(
          context,
          labelText,
        ),
      ),
    );
  }
}