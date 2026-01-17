import 'package:flutter/material.dart';
import 'package:planejacampo/models/agro/adubacao/aplicacao_nutriente.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_calagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_gessagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/models/agro/cultura.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/screens/agro/adubacao/recomendacao_screen.dart';
import 'package:planejacampo/screens/agro/adubacao/resultados_analises_solos_list_screen.dart';
import 'package:planejacampo/services/agro/adubacao/aplicacao_nutriente_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_calagem_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_gessagem_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_nutriente_service.dart';
import 'package:planejacampo/services/agro/adubacao/cultura_parametros_service.dart';
import 'package:planejacampo/services/agro/adubacao/nutriente_calculator.dart';
import 'package:planejacampo/services/agro/adubacao/correcao_solo_calculator.dart';
import 'package:planejacampo/services/agro/adubacao/ajustes_doses_calculator.dart';
import 'package:planejacampo/services/agro/adubacao/validador_recomendacao.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_processor.dart';
import 'package:planejacampo/services/agro/adubacao/faixa_interpretacao_solo_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class RecomendacaoGeneratorScreen extends StatefulWidget {
  final ResultadoAnaliseSolo? analise;

  const RecomendacaoGeneratorScreen({
    Key? key,
    this.analise,
  }) : super(key: key);

  @override
  _RecomendacaoGeneratorScreenState createState() => _RecomendacaoGeneratorScreenState();
}

class _RecomendacaoGeneratorScreenState extends State<RecomendacaoGeneratorScreen> {
  // Services
  final RecomendacaoService _recomendacaoService = RecomendacaoService();
  final RecomendacaoNutrienteService _nutrienteService = RecomendacaoNutrienteService();
  final RecomendacaoCalagemService _calagemService = RecomendacaoCalagemService();
  final RecomendacaoGessagemService _gessagemService = RecomendacaoGessagemService();
  final PessoaService _pessoaService = PessoaService(); // Novo serviço
  late final RecomendacaoProcessor _processor;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _analiseController = TextEditingController();
  final TextEditingController _produtividadeController = TextEditingController();
  final TextEditingController _dataPlantioController = TextEditingController();

  // State
  String _nomeDoLaboratorio = ''; // Nova variável para armazenar o nome
  ResultadoAnaliseSolo? _selectedAnalise;
  TipoCultura? _selectedCultura;
  SistemaCultivo? _selectedSistemaCultivo;
  TexturaSolo? _selectedTexturaSolo;
  DateTime _dataPlantio = DateTime.now();
  bool _isIrrigado = false;
  bool _hasChanges = false;
  bool _isLoading = false;
  Object _returnObject = '';
  bool _isExpanded = false;
  bool _showTutorial = false;

  // Tutorial keys
  final GlobalKey _analiseKey = GlobalKey();
  final GlobalKey<FormFieldState> _culturaKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _classeRespostaKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _sistemaKey = GlobalKey<FormFieldState>();
  final GlobalKey _gerarRecomendacaoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('recomendacaoAdubacaoFormScreen');
    appStateManager.setShowTutorial('recomendacaoAdubacaoFormScreen', false);
    _selectedAnalise = widget.analise;
    _processor = RecomendacaoProcessor(
      parametrosService: CulturaParametrosService(),
      faixaService: FaixaInterpretacaoSoloService(),
      recomendacaoService: _recomendacaoService,
      nutrienteCalculator: NutrienteCalculator(),
      correcaoCalculator: CorrecaoSoloCalculator(),
      ajustesCalculator: AjustesDosesCalculator(),
      validador: ValidadorRecomendacao(),
    );

    if (_selectedAnalise != null) {
      _analiseController.text = 'Análise de ${FormatacaoUtil.formatDate(_selectedAnalise!.dataAnalise)}';
      _selectedTexturaSolo = _selectedAnalise!.texturaSolo;
    }

    _dataPlantioController.text = FormatacaoUtil.formatDate(_dataPlantio);
  }

  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    return _isExpanded;
  }

  // Adicionar método para carregar o nome do laboratório
  Future<void> _carregarNomeLaboratorio(String laboratorioId) async {
    try {
      final pessoa = await _pessoaService.getById(laboratorioId);
      if (pessoa != null && mounted) {
        setState(() {
          _nomeDoLaboratorio = pessoa.nome;
        });
      } else {
        setState(() {
          _nomeDoLaboratorio = ''; // Limpar se não encontrar
        });
      }
    } catch (e) {
      print('Erro ao carregar nome do laboratório: $e');
      setState(() {
        _nomeDoLaboratorio = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).generate_recommendation,
      moduleName: 'recomendacoesAdubacao',
      returnObject: _returnObject,
      onWillPop: () async => true,
      showTutorial: _showTutorial,
      customTutorialSteps: _buildCustomTutorialSteps(),
      summarySection: _buildFormSection(),
      serviceName: _recomendacaoService,
      itemIdValue: '',
      itemName: S.of(context).recommendation,
      fieldReference: 'recomendacaoId',
      cardSections: [],
      isExpanded: _isExpanded,
      // Remover a lógica de edição e exclusão já que isso não se aplica a uma tela de geração
      canEdit: false,
      canDelete: false,
      // Botão de ajuda personalizado
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      additionalFloatingActionButtons: (BuildContext context) => [
        if (!_isLoading)
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () {
              _toggleFloatingActionButton();
              _gerarRecomendacao();
            },
            icon: Icons.science,
            text: S.of(context).generate_recommendation,
            key: _gerarRecomendacaoKey,
            heroTag: 'gerarRecomendacao',
          ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnaliseSection(),
            const SizedBox(height: 16),
            _buildCulturaSection(),
            const SizedBox(height: 16),
            _buildSistemaSection(),
            const SizedBox(height: 16),
            _buildParametrosSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnaliseSection() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: theme.colorScheme.primary, size: 28),
                SizedBox(width: 10),
                Text(
                  S.of(context).soil_analysis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            TextFormField(
              key: _analiseKey,
              controller: _analiseController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).soil_analysis,
                suffixIcon: const Icon(Icons.search),
              ),
              readOnly: true,
              onTap: _selectAnalise,
              validator: (value) {
                if (_selectedAnalise == null) {
                  return S.of(context).select_soil_analysis;
                }
                return null;
              },
            ),
            if (_selectedAnalise != null) ...[
              const SizedBox(height: 16),
              _buildAnaliseInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnaliseInfo() {
    if (_selectedAnalise == null) return SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).details,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
              Icons.calendar_today,
              S.of(context).analysis_date,
              FormatacaoUtil.formatDate(_selectedAnalise!.dataAnalise)
          ),
          _buildInfoRow(
              Icons.landscape,
              S.of(context).soil_texture,
              _selectedAnalise!.texturaSolo?.getLocalizedName(context) ?? S.of(context).not_found
          ),
          if (_selectedAnalise!.laboratorioId != null)
            _buildInfoRow(
                Icons.science,
                S.of(context).laboratory,
                _nomeDoLaboratorio.isNotEmpty ? _nomeDoLaboratorio : S.of(context).not_found
            ),
          if (_selectedAnalise!.profundidadeAmostra.descricao != null)
            _buildInfoRow(
                Icons.location_on,
                S.of(context).sample_depth ?? "Profundidade",
                '${_selectedAnalise!.profundidadeAmostra.descricao} cm'
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.secondary),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCulturaSection() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grass, color: theme.colorScheme.secondary, size: 28),
                SizedBox(width: 10),
                Text(
                  S.of(context).crop,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ObjectTemplate.getDropdownButtonFormField(
              context: context,
              key: _culturaKey,
              labelText: S.of(context).crop_type,
              value: _selectedCultura != null ? _selectedCultura.toString().split('.').last : null,
              items: TipoCultura.values.map((e) => e.toString().split('.').last).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCultura = TipoCultura.values.firstWhere(
                          (e) => e.toString().split('.').last == value,
                      orElse: () => TipoCultura.SOJA,
                    );
                    _hasChanges = true;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).select_crop_type;
                }
                return null;
              },
              dropdownItems: TipoCultura.values.map((cultura) {
                return DropdownMenuItem<String>(
                  value: cultura.toString().split('.').last,
                  child: Text(cultura.getLocalizedName(context)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ObjectTemplate.getDropdownButtonFormField(
              context: context,
              labelText: S.of(context).soil_texture,
              value: _selectedTexturaSolo != null ? _selectedTexturaSolo.toString().split('.').last : null,
              items: TexturaSolo.values.map((e) => e.toString().split('.').last).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTexturaSolo = TexturaSolo.values.firstWhere(
                          (e) => e.toString().split('.').last == value,
                      orElse: () => TexturaSolo.MEDIO,
                    );
                    _hasChanges = true;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).select_soil_texture;
                }
                return null;
              },
              dropdownItems: TexturaSolo.values.map((textura) {
                return DropdownMenuItem<String>(
                  value: textura.toString().split('.').last,
                  child: Text(textura.getLocalizedName(context)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSistemaSection() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.tertiary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.tertiary, size: 28),
                SizedBox(width: 10),
                Text(
                  S.of(context).cultivation_system,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ObjectTemplate.getDropdownButtonFormField(
              context: context,
              key: _sistemaKey,
              labelText: S.of(context).cultivation_system,
              value: _selectedSistemaCultivo != null ? _selectedSistemaCultivo.toString().split('.').last : null,
              items: SistemaCultivo.values.map((e) => e.toString().split('.').last).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSistemaCultivo = SistemaCultivo.values.firstWhere(
                          (e) => e.toString().split('.').last == value,
                      orElse: () => SistemaCultivo.CONVENCIONAL,
                    );
                    _hasChanges = true;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).select_cultivation_system;
                }
                return null;
              },
              dropdownItems: SistemaCultivo.values.map((sistema) {
                return DropdownMenuItem<String>(
                  value: sistema.toString().split('.').last,
                  child: Text(sistema.getLocalizedName(context)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametrosSection() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: theme.colorScheme.primary, size: 28),
                SizedBox(width: 10),
                Text(
                  S.of(context).parameters,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            TextFormField(
              controller: _produtividadeController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).expected_yield_tons_per_hectare,
                suffixIcon: const Icon(Icons.bar_chart),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).enter_expected_yield;
                }
                final produtividade = double.tryParse(value);
                if (produtividade == null || produtividade <= 0) {
                  return S.of(context).enter_valid_yield;
                }
                return null;
              },
              onChanged: (value) => _hasChanges = true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dataPlantioController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).planting_date,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dataPlantio,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _dataPlantio = date;
                    _dataPlantioController.text = FormatacaoUtil.formatDate(date);
                    _hasChanges = true;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(S.of(context).irrigated,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                S.of(context).description, // Usando "description" em vez de "indicate_if_crop_is_irrigated"
                style: theme.textTheme.bodySmall,
              ),
              value: _isIrrigado,
              activeColor: theme.colorScheme.primary,
              contentPadding: EdgeInsets.symmetric(horizontal: 4),
              onChanged: (bool value) {
                setState(() {
                  _isIrrigado = value;
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 24),
            // Botão "Gerar Recomendação" no final da tela
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _gerarRecomendacao,
                icon: Icon(Icons.science),
                label: Text(S.of(context).generate_recommendation),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'analise': {
        'key': _analiseKey,
        'message': S.of(context).select_analysis_tutorial,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'cultura': {
        'key': _culturaKey,
        'message': S.of(context).select_crop_tutorial,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'classeResposta': {
        'key': _classeRespostaKey,
        'message': S.of(context).select_crop_type, // Usando outro campo existente
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'sistema': {
        'key': _sistemaKey,
        'message': S.of(context).select_system_tutorial,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'gerarRecomendacao': {
        'key': _gerarRecomendacaoKey,
        'message': S.of(context).generate_recommendation_tutorial,
        'shape': 'Circle',
        'align': 'ContentAlign.top',
      },
    };
  }

  void _startTutorial() {
    if (mounted) {
      final appStateManager = Provider.of<AppStateManager>(context, listen: false);
      appStateManager.setShowTutorial('recomendacaoAdubacaoFormScreen', true);
      setState(() {
        _showTutorial = true;
      });
    }
  }

  Future<void> _selectAnalise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultadosAnalisesSolosListScreen(
          isSelectMode: true,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedAnalise = result;
        _analiseController.text = 'Análise de ${FormatacaoUtil.formatDate(_selectedAnalise!.dataAnalise)}';
        // Reset fields that depend on análise
        _selectedTexturaSolo = _selectedAnalise!.texturaSolo;
        _hasChanges = true;
      });

      // Carregar o nome do laboratório após selecionar a análise
      if (_selectedAnalise?.laboratorioId != null) {
        await _carregarNomeLaboratorio(_selectedAnalise!.laboratorioId);
      }
    }
  }

  Future<void> _gerarRecomendacao() async {
    // Validação inicial do formulário
    if (!_formKey.currentState!.validate()) return;

    // Validação dos campos obrigatórios
    if (!_validarCamposObrigatorios()) return;

    setState(() => _isLoading = true);

    try {
      // Prepara os dados da cultura
      final cultura = _prepararDadosCultura();

      // Processa a recomendação
      final resultado = await _processor.processarRecomendacao(
        analise: _selectedAnalise!,
        cultura: cultura,
        produtividadeEsperada: double.tryParse(_produtividadeController.text) ?? 0.0,
        estado: 'SP', // Considere tornar isso dinâmico
        produtorId: _selectedAnalise!.produtorId,
        propriedadeId: _selectedAnalise!.propriedadeId,
        talhaoId: _selectedAnalise!.talhoes!.first,
      );

      if (!mounted) return;

      // Trata o resultado da validação
      await _tratarResultadoValidacao(resultado);

    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validarCamposObrigatorios() {
    String? errorMessage;

    if (_selectedAnalise == null) {
      errorMessage = S.of(context).select_soil_analysis;
    } else if (_selectedCultura == null) {
      errorMessage = S.of(context).select_crop_type;
    } else if (_selectedSistemaCultivo == null) {
      errorMessage = S.of(context).select_cultivation_system;
    } else if (_selectedTexturaSolo == null) {
      errorMessage = S.of(context).select_soil_texture;
    } else if (_selectedAnalise?.talhoes?.isEmpty ?? true) {
      errorMessage = S.of(context).no_plots_linked;
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    }

    return true;
  }

  Cultura _prepararDadosCultura() {
    if (_selectedAnalise == null) {
      throw Exception('Análise não selecionada');
    }

    final produtividade = double.tryParse(_produtividadeController.text);
    if (produtividade == null || produtividade <= 0) {
      throw Exception('Produtividade inválida');
    }

    if (_selectedAnalise!.talhoes == null || _selectedAnalise!.talhoes!.isEmpty) {
      throw Exception('Talhão não selecionado');
    }

    // Determinar época de plantio baseado na data
    final epocaPlantio = _determinarEpocaPlantio(_dataPlantio);

    return Cultura(
      id: DateTime.now().toString(),
      produtorId: _selectedAnalise!.produtorId,
      propriedadeId: _selectedAnalise!.propriedadeId,
      talhaoId: _selectedAnalise!.talhoes!.first,
      tipo: _selectedCultura!,
      epocaPlantio: epocaPlantio,
      sistemaCultivo: _selectedSistemaCultivo!,
      produtividadeEsperada: produtividade,
      permiteIrrigacao: _isIrrigado,
      dataPlantio: _dataPlantio,
      observacoes: [],
    );
  }

  EpocaPlantio _determinarEpocaPlantio(DateTime data) {
    final mes = data.month;
    if (mes >= 10 || mes <= 3) {
      return EpocaPlantio.SAFRA_VERAO;
    } else {
      return EpocaPlantio.SAFRINHA;
    }
  }

  Future<void> _tratarResultadoValidacao(Map<String, dynamic> resultado) async {
    final validacao = resultado['validacao'] as Map<String, dynamic>;
    final recomendacao = resultado['recomendacao'] as Recomendacao;
    final nutrientes = Map<String, RecomendacaoNutriente>.from(resultado['nutrientes']);
    final correcoes = resultado['correcoes'] as Map<String, dynamic>;

    if (!validacao['valido']) {
      final temErros = (validacao['erros'] as List).isNotEmpty;
      final temAvisos = (validacao['avisos'] as List).isNotEmpty;

      if (temErros || temAvisos) {
        // Mostra diálogo de validação
        final continuarMesmoComErros = await _mostrarDialogoValidacao(
          validacao,
          temErros,
        );

        // Se tem erros e usuário não confirmou, retorna
        if (temErros && !continuarMesmoComErros) {
          return;
        }
      }
    }

    try {
      // Mostrar diálogo de loading durante o salvamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text(S.of(context).processing),
                ],
              ),
            ),
          );
        },
      );

      // 1. Salvar a recomendação principal no banco de dados
      final recomendacaoId = await _recomendacaoService.add(recomendacao, returnId: true) as String;

      // Atualizar o ID da recomendação salva no objeto
      final Recomendacao updatedRecomendacao = Recomendacao.fromMap(
          {...recomendacao.toMap(), 'id': recomendacaoId},
          recomendacaoId
      );

      // 2. Salvar as recomendações de nutrientes e suas aplicações
      final aplicacaoNutrienteService = AplicacaoNutrienteService(); // NOVO: inicializar o serviço

      for (var nutriente in nutrientes.values) {
        // Atualizar o ID da recomendação
        var nutrienteAtualizado = nutriente.copyWith(
          recomendacaoId: recomendacaoId,
        );

        // Salvar no banco de dados
        final nutrienteId = await _nutrienteService.add(nutrienteAtualizado, returnId: true) as String;

        // NOVO: Salvar aplicações deste nutriente
        if (resultado['aplicacoes'].containsKey(nutriente.nutriente)) {
          final aplicacoesNutriente = resultado['aplicacoes'][nutriente.nutriente] as List<AplicacaoNutriente>;

          await aplicacaoNutrienteService.salvarAplicacoesNutriente(
              nutrienteId,
              aplicacoesNutriente,
              recomendacao.produtorId,
              recomendacao.propriedadeId
          );
        }
      }

      // 3. Salvar recomendação de calagem, se existir
      if (correcoes.containsKey('calagem')) {
        var calagem = correcoes['calagem'] as RecomendacaoCalagem;
        // Atualizar o ID da recomendação
        calagem = calagem.copyWith(
          recomendacaoId: recomendacaoId,
        );

        // Salvar no banco de dados
        await _calagemService.add(calagem);
      }

      // 4. Salvar recomendação de gessagem, se existir
      if (correcoes.containsKey('gessagem')) {
        var gessagem = correcoes['gessagem'] as RecomendacaoGessagem;
        // Atualizar o ID da recomendação
        gessagem = gessagem.copyWith(
          recomendacaoId: recomendacaoId,
        );

        // Salvar no banco de dados
        await _gessagemService.add(gessagem);
      }

      // Extrai as aplicações do resultado do processador
      final aplicacoes = resultado['aplicacoes'] as Map<String, List<AplicacaoNutriente>>? ?? {};

      // Fechar o diálogo de loading
      Navigator.of(context).pop();

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).recomendation_created_successfully),
          backgroundColor: Colors.green,
        ),
      );

      // Se chegou aqui, navega para a tela de detalhes
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecomendacaoScreen(
            recomendacao: updatedRecomendacao,
            nutrientes: nutrientes,
            correcoes: correcoes,
            aplicacoes: aplicacoes,
          ),
        ),
      );

      // Retorna ao fluxo anterior com valor true para indicar que uma recomendação foi criada
      Navigator.of(context).pop(true);

    } catch (e) {
      // Fechar o diálogo de loading em caso de erro
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Mostrar mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).error_saving_soil_analysis(e.toString())),
          backgroundColor: Colors.red,
        ),
      );

      print('Erro ao salvar recomendação: $e');
    }
  }

  Future<bool> _mostrarDialogoValidacao(Map<String, dynamic> validacao, bool temErros) async {
    final erros = validacao['erros'] as List<String>;
    final avisos = validacao['avisos'] as List<String>;
    final theme = Theme.of(context);

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          temErros
              ? S.of(context).validation_errors
              : S.of(context).validation_warnings,
          style: TextStyle(
            color: temErros ? Colors.red : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (erros.isNotEmpty) ...[
                Text(
                  S.of(context).errors,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...erros.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text(e)),
                    ],
                  ),
                )),
              ],
              if (avisos.isNotEmpty) ...[
                if (erros.isNotEmpty) const SizedBox(height: 16),
                Text(
                  S.of(context).warnings,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ...avisos.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text(e)),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  temErros
                      ? S.of(context).continue_with_errors_question
                      : S.of(context).continue_with_warnings_question,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context).continue_anyway),
            style: ElevatedButton.styleFrom(
              backgroundColor: temErros ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _handleError(Object e, StackTrace stackTrace) {
    print('Error stack trace:');
    print(stackTrace);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).recommendation_generation_error + ': ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: S.of(context).details,
          onPressed: () => _mostrarDetalhesErro(e, stackTrace),
        ),
      ),
    );
  }

  void _mostrarDetalhesErro(Object erro, StackTrace stackTrace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).error_details),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).error_message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(erro.toString()),
              const SizedBox(height: 16),
              Text(
                S.of(context).stack_trace,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(stackTrace.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).close),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _analiseController.dispose();
    _produtividadeController.dispose();
    _dataPlantioController.dispose();
    super.dispose();
  }
}