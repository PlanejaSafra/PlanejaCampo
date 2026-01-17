import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_gessagem.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';

class RecomendacaoGessagemFormScreen extends StatefulWidget {
  final String recomendacaoId;
  final RecomendacaoGessagem? gessagem;
  final ResultadoAnaliseSolo? analise;

  const RecomendacaoGessagemFormScreen({
    Key? key,
    required this.recomendacaoId,
    this.gessagem,
    this.analise,
  }) : super(key: key);

  @override
  _RecomendacaoGessagemFormScreenState createState() => _RecomendacaoGessagemFormScreenState();
}

class _RecomendacaoGessagemFormScreenState extends State<RecomendacaoGessagemFormScreen> {
  // Controllers
  final TextEditingController _teorSulfatoController = TextEditingController();
  final TextEditingController _saturacaoAluminioController = TextEditingController();
  final TextEditingController _calcioSubsoloController = TextEditingController();
  final TextEditingController _doseRecomendadaController = TextEditingController();
  final TextEditingController _modoAplicacaoController = TextEditingController();
  final TextEditingController _profundidadeAvaliadaController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  // State
  bool _parcelamento = false;
  bool _usarSaturacaoAluminio = true; // Escolha do critério para cálculo

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    // Se analise estiver disponível e for uma nova gessagem, preencher com valores do solo
    if (widget.analise != null && widget.gessagem == null) {
      _saturacaoAluminioController.text = widget.analise!.saturacaoAl.toStringAsFixed(1);
      _calcioSubsoloController.text = '0.0'; // Geralmente não disponível na análise de solo

      // Valores recomendados padrão
      _teorSulfatoController.text = '10.0';  // 10 mg/dm³ é um valor comum
      _profundidadeAvaliadaController.text = '40';  // 40cm é uma profundidade padrão para gessagem
    }
    // Se é edição, preencher com valores existentes
    else if (widget.gessagem != null) {
      _teorSulfatoController.text = widget.gessagem!.teorSulfato.toStringAsFixed(1);
      _saturacaoAluminioController.text = widget.gessagem!.saturacaoAluminio.toStringAsFixed(1);
      _calcioSubsoloController.text = widget.gessagem!.calcioSubsolo.toStringAsFixed(1);
      _doseRecomendadaController.text = widget.gessagem!.doseRecomendada.toStringAsFixed(2);
      _modoAplicacaoController.text = widget.gessagem!.modoAplicacao;
      _profundidadeAvaliadaController.text = widget.gessagem!.profundidadeAvaliada.toString();
      _parcelamento = widget.gessagem!.parcelamento;

      // Definir o critério escolhido anteriormente
      _usarSaturacaoAluminio = widget.gessagem!.saturacaoAluminio > 0;

      if (widget.gessagem!.observacoes.isNotEmpty) {
        _observacoesController.text = widget.gessagem!.observacoes.join('\n');
      }
    } else {
      // Valores padrão para nova gessagem sem análise
      _profundidadeAvaliadaController.text = '40';
    }
  }

  // Calcula dose de gesso recomendada
  void _calcularDoseGesso() {
    try {
      if (_usarSaturacaoAluminio) {
        // Cálculo baseado na saturação de alumínio
        final double saturacaoAluminio = double.parse(_saturacaoAluminioController.text);

        // Fórmula: NG (t/ha) = Saturação Al (%) x 0.5
        // Este é um cálculo simplificado, pode ser ajustado conforme necessário
        final double necessidadeGesso = saturacaoAluminio * 0.5;

        // Garantir valor positivo e arredondar para 2 casas decimais
        final double doseRecomendada = necessidadeGesso > 0 ? necessidadeGesso : 0.0;

        setState(() {
          _doseRecomendadaController.text = doseRecomendada.toStringAsFixed(2);
        });
      } else {
        // Cálculo baseado no teor de cálcio do subsolo
        final double calcioSubsolo = double.parse(_calcioSubsoloController.text);

        // Fórmula adaptada: NG (t/ha) = (3.0 - Cálcio subsolo) x 6
        // Se o teor de cálcio for menor que 3.0 mmolc/dm³, recomendar gesso
        if (calcioSubsolo < 3.0) {
          final double necessidadeGesso = (3.0 - calcioSubsolo) * 6;
          setState(() {
            _doseRecomendadaController.text = necessidadeGesso.toStringAsFixed(2);
          });
        } else {
          setState(() {
            _doseRecomendadaController.text = '0.00';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).no_gypsum_needed_due_to_calcium_content)),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).error_calculating_value(e.toString()))),
      );
    }
  }

  // Valida se os campos obrigatórios estão preenchidos
  bool _validarCampos() {
    String? errorMessage;

    if (_doseRecomendadaController.text.isEmpty) {
      errorMessage = S.of(context).enter_recommended_dose;
    } else if (_modoAplicacaoController.text.isEmpty) {
      errorMessage = S.of(context).enter_application_mode;
    } else if (_profundidadeAvaliadaController.text.isEmpty) {
      errorMessage = S.of(context).enter_evaluated_depth;
    }

    // Validar campos específicos do critério escolhido
    if (_usarSaturacaoAluminio && _saturacaoAluminioController.text.isEmpty) {
      errorMessage = S.of(context).enter_aluminum_saturation;
    } else if (!_usarSaturacaoAluminio && _calcioSubsoloController.text.isEmpty) {
      errorMessage = S.of(context).enter_subsoil_calcium;
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gessagem == null
            ? S.of(context).add_gypsum_recommendation
            : S.of(context).edit_gypsum_recommendation),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              if (_validarCampos()) {
                final appStateManager = Provider.of<AppStateManager>(context, listen: false);

                final RecomendacaoGessagem gessagem = RecomendacaoGessagem(
                  id: widget.gessagem?.id ?? DateTime.now().toString(),
                  recomendacaoId: widget.recomendacaoId,
                  produtorId: appStateManager.activeProdutorId ?? '',
                  propriedadeId: appStateManager.activePropriedadeId ?? '',
                  teorSulfato: double.parse(_teorSulfatoController.text.isEmpty ? '0.0' : _teorSulfatoController.text),
                  saturacaoAluminio: double.parse(_saturacaoAluminioController.text.isEmpty ? '0.0' : _saturacaoAluminioController.text),
                  calcioSubsolo: double.parse(_calcioSubsoloController.text.isEmpty ? '0.0' : _calcioSubsoloController.text),
                  doseRecomendada: double.parse(_doseRecomendadaController.text),
                  modoAplicacao: _modoAplicacaoController.text,
                  profundidadeAvaliada: int.parse(_profundidadeAvaliadaController.text),
                  parcelamento: _parcelamento,
                  observacoes: _observacoesController.text.isNotEmpty
                      ? _observacoesController.text.split('\n').where((line) => line.trim().isNotEmpty).toList()
                      : [],
                );

                Navigator.of(context).pop(gessagem);
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
            // Critério de Recomendação
            _buildSectionHeader(context, S.of(context).recommendation_criteria, Icons.rule),

            // Escolha do critério
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).select_calculation_criteria,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),

                    SizedBox(height: 16),

                    // Opção Saturação de Alumínio
                    RadioListTile<bool>(
                      title: Text(S.of(context).aluminum_saturation),
                      subtitle: Text(S.of(context).recommendation_based_on_aluminum),
                      value: true,
                      groupValue: _usarSaturacaoAluminio,
                      onChanged: (value) {
                        setState(() {
                          _usarSaturacaoAluminio = value!;
                        });
                      },
                    ),

                    // Opção Teor de Cálcio no Subsolo
                    RadioListTile<bool>(
                      title: Text(S.of(context).subsoil_calcium_content),
                      subtitle: Text(S.of(context).recommendation_based_on_calcium),
                      value: false,
                      groupValue: _usarSaturacaoAluminio,
                      onChanged: (value) {
                        setState(() {
                          _usarSaturacaoAluminio = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Parâmetros de Solo
            _buildSectionHeader(context, S.of(context).soil_parameters, Icons.landscape),

            // Teor de Sulfato
            _buildNumberField(
              context: context,
              controller: _teorSulfatoController,
              labelText: S.of(context).sulfate_content,
              helperText: S.of(context).sulfate_soil_content,
              suffix: 'mg/dm³',
            ),

            // Parâmetros específicos do critério escolhido
            if (_usarSaturacaoAluminio) ...[
              // Saturação de Alumínio
              _buildNumberField(
                context: context,
                controller: _saturacaoAluminioController,
                labelText: S.of(context).aluminum_saturation,
                helperText: S.of(context).value_from_soil_analysis,
                suffix: '%',
                onChanged: (_) => _calcularDoseGesso(),
              ),
            ] else ...[
              // Teor de Cálcio no Subsolo
              _buildNumberField(
                context: context,
                controller: _calcioSubsoloController,
                labelText: S.of(context).subsoil_calcium_content,
                helperText: S.of(context).calcium_subsoil_content,
                suffix: 'mmolc/dm³',
                onChanged: (_) => _calcularDoseGesso(),
              ),
            ],

            // Profundidade Avaliada
            _buildNumberField(
              context: context,
              controller: _profundidadeAvaliadaController,
              labelText: S.of(context).evaluated_depth,
              helperText: S.of(context).depth_of_soil_sampling,
              suffix: 'cm',
              isInt: true,
            ),

            SizedBox(height: 24),

            // Recomendação
            _buildSectionHeader(context, S.of(context).recommendation, Icons.recommend),

            // Dose Recomendada
            _buildNumberField(
              context: context,
              controller: _doseRecomendadaController,
              labelText: S.of(context).recommended_dose,
              helperText: S.of(context).gypsum_tons_per_hectare,
              suffix: 't/ha',
            ),

            // Modo de Aplicação
            TextFormField(
              controller: _modoAplicacaoController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).application_mode,
              ),
            ),

            SizedBox(height: 16),

            // Parcelamento
            SwitchListTile(
              title: Text(S.of(context).installment_application),
              subtitle: Text(S.of(context).apply_in_multiple_operations),
              value: _parcelamento,
              onChanged: (value) {
                setState(() {
                  _parcelamento = value;
                });
              },
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
              onPressed: _calcularDoseGesso,
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
}