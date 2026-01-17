import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_calagem.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';

class RecomendacaoCalagemFormScreen extends StatefulWidget {
  final String recomendacaoId;
  final RecomendacaoCalagem? calagem;
  final ResultadoAnaliseSolo? analise;

  const RecomendacaoCalagemFormScreen({
    Key? key,
    required this.recomendacaoId,
    this.calagem,
    this.analise,
  }) : super(key: key);

  @override
  _RecomendacaoCalagemFormScreenState createState() => _RecomendacaoCalagemFormScreenState();
}

class _RecomendacaoCalagemFormScreenState extends State<RecomendacaoCalagemFormScreen> {
  // Controllers
  final TextEditingController _saturacaoAtualController = TextEditingController();
  final TextEditingController _saturacaoDesejadaController = TextEditingController();
  final TextEditingController _ctcController = TextEditingController();
  final TextEditingController _prntController = TextEditingController();
  final TextEditingController _tipoCalcarioController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _profundidadeController = TextEditingController();
  final TextEditingController _modoAplicacaoController = TextEditingController();
  final TextEditingController _prazoAplicacaoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  // State
  bool _parcelamento = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    // Se analise estiver disponível e for uma nova calagem, preencher com valores do solo
    if (widget.analise != null && widget.calagem == null) {
      _saturacaoAtualController.text = widget.analise!.saturacaoBase.toStringAsFixed(1);
      _ctcController.text = widget.analise!.ctc.toStringAsFixed(1);

      // Valores recomendados padrão
      _saturacaoDesejadaController.text = '70.0';  // 70% é um valor comum desejado
      _prntController.text = '80.0';  // 80% é um PRNT comum
      _profundidadeController.text = '20.0';  // 20cm é uma profundidade padrão
      _prazoAplicacaoController.text = '3';  // 3 meses é um prazo comum
    }
    // Se é edição, preencher com valores existentes
    else if (widget.calagem != null) {
      _saturacaoAtualController.text = widget.calagem!.saturacaoBasesAtual.toStringAsFixed(1);
      _saturacaoDesejadaController.text = widget.calagem!.saturacaoBasesDesejada.toStringAsFixed(1);
      _ctcController.text = widget.calagem!.ctc.toStringAsFixed(1);
      _prntController.text = widget.calagem!.prnt.toStringAsFixed(1);
      _tipoCalcarioController.text = widget.calagem!.tipoCalcario;
      _quantidadeController.text = widget.calagem!.quantidadeRecomendada.toStringAsFixed(2);
      _profundidadeController.text = widget.calagem!.profundidadeIncorporacao.toStringAsFixed(1);
      _modoAplicacaoController.text = widget.calagem!.modoAplicacao;
      _prazoAplicacaoController.text = widget.calagem!.prazoAplicacao.toString();
      _parcelamento = widget.calagem!.parcelamento;

      if (widget.calagem!.observacoes.isNotEmpty) {
        _observacoesController.text = widget.calagem!.observacoes.join('\n');
      }
    }
  }

  // Calcula quantidade de calcário recomendada
  void _calcularQuantidadeCalcario() {
    try {
      final double saturacaoAtual = double.parse(_saturacaoAtualController.text);
      final double saturacaoDesejada = double.parse(_saturacaoDesejadaController.text);
      final double ctc = double.parse(_ctcController.text);
      final double prnt = double.parse(_prntController.text);
      final double profundidade = double.parse(_profundidadeController.text);

      // Fórmula: NC (t/ha) = (V2 - V1) x CTC x f / PRNT
      // onde f = fator de profundidade (20cm = 1.0, para outras profundidades ajustar proporcionalmente)
      final double fatorProfundidade = profundidade / 20.0;
      final double necessidadeCalcario = ((saturacaoDesejada - saturacaoAtual) * ctc * fatorProfundidade) / prnt;

      // Garantir valor positivo e arredondar para 2 casas decimais
      final double quantidadeRecomendada = necessidadeCalcario > 0 ? necessidadeCalcario : 0.0;

      setState(() {
        _quantidadeController.text = quantidadeRecomendada.toStringAsFixed(2);
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

    if (_saturacaoAtualController.text.isEmpty) {
      errorMessage = S.of(context).enter_current_base_saturation;
    } else if (_saturacaoDesejadaController.text.isEmpty) {
      errorMessage = S.of(context).enter_desired_base_saturation;
    } else if (_ctcController.text.isEmpty) {
      errorMessage = S.of(context).enter_ctc;
    } else if (_prntController.text.isEmpty) {
      errorMessage = S.of(context).enter_prnt;
    } else if (_tipoCalcarioController.text.isEmpty) {
      errorMessage = S.of(context).enter_limestone_type;
    } else if (_quantidadeController.text.isEmpty) {
      errorMessage = S.of(context).enter_quantity;
    } else if (_profundidadeController.text.isEmpty) {
      errorMessage = S.of(context).enter_incorporation_depth;
    } else if (_modoAplicacaoController.text.isEmpty) {
      errorMessage = S.of(context).enter_application_mode;
    } else if (_prazoAplicacaoController.text.isEmpty) {
      errorMessage = S.of(context).enter_application_deadline;
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
        title: Text(widget.calagem == null
            ? S.of(context).add_liming_recommendation
            : S.of(context).edit_liming_recommendation),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              if (_validarCampos()) {
                final appStateManager = Provider.of<AppStateManager>(context, listen: false);

                final RecomendacaoCalagem calagem = RecomendacaoCalagem(
                  id: widget.calagem?.id ?? DateTime.now().toString(),
                  recomendacaoId: widget.recomendacaoId,
                  produtorId: appStateManager.activeProdutorId ?? '',
                  propriedadeId: appStateManager.activePropriedadeId ?? '',
                  saturacaoBasesAtual: double.parse(_saturacaoAtualController.text),
                  saturacaoBasesDesejada: double.parse(_saturacaoDesejadaController.text),
                  ctc: double.parse(_ctcController.text),
                  prnt: double.parse(_prntController.text),
                  tipoCalcario: _tipoCalcarioController.text,
                  quantidadeRecomendada: double.parse(_quantidadeController.text),
                  profundidadeIncorporacao: double.parse(_profundidadeController.text),
                  modoAplicacao: _modoAplicacaoController.text,
                  prazoAplicacao: int.parse(_prazoAplicacaoController.text),
                  parcelamento: _parcelamento,
                  observacoes: _observacoesController.text.isNotEmpty
                      ? _observacoesController.text.split('\n').where((line) => line.trim().isNotEmpty).toList()
                      : [],
                );

                Navigator.of(context).pop(calagem);
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
            // Parâmetros de Solo
            _buildSectionHeader(context, S.of(context).soil_parameters, Icons.landscape),

            // Saturação de Bases Atual
            _buildNumberField(
              context: context,
              controller: _saturacaoAtualController,
              labelText: S.of(context).current_base_saturation_percentage,
              helperText: S.of(context).value_from_soil_analysis,
              suffix: '%',
              onChanged: (_) => _calcularQuantidadeCalcario(),
            ),

            // Saturação de Bases Desejada
            _buildNumberField(
              context: context,
              controller: _saturacaoDesejadaController,
              labelText: S.of(context).desired_base_saturation_percentage,
              helperText: S.of(context).desired_saturation_for_crop,
              suffix: '%',
              onChanged: (_) => _calcularQuantidadeCalcario(),
            ),

            // CTC
            _buildNumberField(
              context: context,
              controller: _ctcController,
              labelText: S.of(context).cation_exchange_capacity,
              helperText: S.of(context).ctc_from_soil_analysis,
              suffix: 'mmolc/dm³',
              onChanged: (_) => _calcularQuantidadeCalcario(),
            ),

            SizedBox(height: 24),

            // Parâmetros do Calcário
            _buildSectionHeader(context, S.of(context).limestone_parameters, Icons.grain),

            // PRNT
            _buildNumberField(
              context: context,
              controller: _prntController,
              labelText: S.of(context).prnt_percentage,
              helperText: S.of(context).relative_neutralizing_power,
              suffix: '%',
              onChanged: (_) => _calcularQuantidadeCalcario(),
            ),

            // Tipo de Calcário
            TextFormField(
              controller: _tipoCalcarioController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).limestone_type,
              ),
            ),

            SizedBox(height: 24),

            // Recomendação
            _buildSectionHeader(context, S.of(context).recommendation, Icons.recommend),

            // Quantidade Recomendada
            _buildNumberField(
              context: context,
              controller: _quantidadeController,
              labelText: S.of(context).recommended_quantity,
              helperText: S.of(context).limestone_tons_per_hectare,
              suffix: 't/ha',
            ),

            // Profundidade de Incorporação
            _buildNumberField(
              context: context,
              controller: _profundidadeController,
              labelText: S.of(context).incorporation_depth,
              helperText: S.of(context).depth_in_centimeters,
              suffix: 'cm',
              onChanged: (_) => _calcularQuantidadeCalcario(),
            ),

            // Modo de Aplicação
            TextFormField(
              controller: _modoAplicacaoController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).application_mode,
              ),
            ),

            // Prazo de Aplicação
            _buildNumberField(
              context: context,
              controller: _prazoAplicacaoController,
              labelText: S.of(context).application_deadline,
              helperText: S.of(context).months_before_planting,
              suffix: S.of(context).months,
              isInt: true,
            ),

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
              onPressed: _calcularQuantidadeCalcario,
              icon: Icon(Icons.calculate),
              label: Text(S.of(context).calculate_recommended_quantity),
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