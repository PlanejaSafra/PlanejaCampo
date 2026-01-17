import 'package:flutter/material.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_calagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_gessagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/screens/agro/adubacao/recomendacao_dialog_screen.dart';
import 'package:planejacampo/screens/agro/adubacao/resultados_analises_solos_list_screen.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_nutriente_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_calagem_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_gessagem_service.dart';
import 'package:planejacampo/services/agro/adubacao/resultado_analise_solo_service.dart';
import 'package:planejacampo/utils/manual_adubacao_options.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';

class RecomendacaoFormScreen extends StatefulWidget {
  final Recomendacao? recomendacao;

  const RecomendacaoFormScreen({
    Key? key,
    this.recomendacao,
  }) : super(key: key);

  @override
  _RecomendacaoFormScreenState createState() => _RecomendacaoFormScreenState();
}

class _RecomendacaoFormScreenState extends State<RecomendacaoFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RecomendacaoService _recomendacaoService = RecomendacaoService();
  final RecomendacaoNutrienteService _nutrienteService = RecomendacaoNutrienteService();
  final RecomendacaoCalagemService _calagemService = RecomendacaoCalagemService();
  final RecomendacaoGessagemService _gessagemService = RecomendacaoGessagemService();
  final ResultadoAnaliseSoloService _analiseService = ResultadoAnaliseSoloService();

  // Controllers
  final TextEditingController _analiseController = TextEditingController();
  final TextEditingController _produtividadeController = TextEditingController();
  final TextEditingController _dataPlantioController = TextEditingController();
  final TextEditingController _dataRecomendacaoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  // Form state
  late Recomendacao _recomendacao;
  ResultadoAnaliseSolo? _selectedAnalise;
  TipoCultura? _selectedCultura;
  ClasseResposta? _selectedClasseResposta;
  SistemaCultivo? _selectedSistemaCultivo;
  TexturaSolo? _selectedTexturaSolo;
  DateTime _dataPlantio = DateTime.now();
  DateTime _dataRecomendacao = DateTime.now();
  bool _isIrrigado = false;
  bool _hasChanges = false;
  bool _isLoading = false;

  // Listas de recomendações
  List<RecomendacaoCalagem> _recomendacoesCalagem = [];
  List<RecomendacaoGessagem> _recomendacoesGessagem = [];
  List<RecomendacaoNutriente> _recomendacoesNutrientes = [];

  // Futures para carregamento das recomendações
  late Future<List<RecomendacaoCalagem>> _futureCalagemList;
  late Future<List<RecomendacaoGessagem>> _futureGessagemList;
  late Future<List<RecomendacaoNutriente>> _futureNutrientesList;

  // Dialog Screen para gerenciar as recomendações
  late RecomendacaoDialogScreen _recomendacaoDialogScreen;

  // Tutorial keys
  final GlobalKey _identificacaoKey = GlobalKey();
  final GlobalKey _analiseKey = GlobalKey();
  final GlobalKey _culturaKey = GlobalKey();
  final GlobalKey _classeRespostaKey = GlobalKey();
  final GlobalKey _sistemaKey = GlobalKey();
  final GlobalKey _parametrosKey = GlobalKey();
  final GlobalKey _dataPlantioKey = GlobalKey();
  final GlobalKey _calagemKey = GlobalKey();
  final GlobalKey _gessagemKey = GlobalKey();
  final GlobalKey _nutrientesKey = GlobalKey();

  // Form field keys
  final GlobalKey<FormFieldState> _culturaFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _classeRespostaFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _sistemaFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _texturaFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey _firstCalagemMoreOptionsKey = GlobalKey();
  final GlobalKey _firstGessagemMoreOptionsKey = GlobalKey();
  final GlobalKey _firstNutrienteMoreOptionsKey = GlobalKey();


  // FloatingActionButton keys
  final GlobalKey _addCalagemKey = GlobalKey();
  final GlobalKey _addGessagemKey = GlobalKey();
  final GlobalKey _addNutrienteKey = GlobalKey();

  // Expanded state
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    if (widget.recomendacao != null) {
      setState(() => _isLoading = true);
      _recomendacao = widget.recomendacao!;

      // Preencher os campos do formulário
      _selectedCultura = _recomendacao.tipoCultura;
      _selectedClasseResposta = _recomendacao.classeResposta;
      _selectedSistemaCultivo = _recomendacao.sistemaCultivo;
      _selectedTexturaSolo = _recomendacao.texturaSolo;
      _isIrrigado = _recomendacao.irrigado;
      _dataPlantio = _recomendacao.dataPlantio;
      _dataRecomendacao = _recomendacao.dataRecomendacao;

      _produtividadeController.text = _recomendacao.produtividadeEsperada.toString();
      _dataPlantioController.text = FormatacaoUtil.formatDate(_dataPlantio);
      _dataRecomendacaoController.text = FormatacaoUtil.formatDate(_dataRecomendacao);

      if (_recomendacao.observacoes.isNotEmpty) {
        _observacoesController.text = _recomendacao.observacoes.join('\n');
      }

      // Carregar análise de solo
      await _loadAnaliseSolo();

      // Inicializar o DialogScreen depois que os dados básicos da recomendação forem carregados
      _initRecomendacaoDialogScreen();

      // Carregar recomendações relacionadas
      _loadRecomendacoes();

      setState(() => _isLoading = false);
    } else {
      // Recomendação nova
      _recomendacao = Recomendacao(
        id: '',
        manualAdubacao: 'manual_adubacao_sp_iac_100_2022',
        produtorId: '',
        propriedadeId: '',
        talhaoId: '',
        dataRecomendacao: DateTime.now(),
        dataPlantio: DateTime.now(),
        produtividadeEsperada: 0,
        resultadoAnaliseSoloId: '',
        tipoCultura: TipoCultura.SOJA,
        classeResposta: ClasseResposta.MEDIA_BAIXA,
        texturaSolo: TexturaSolo.MEDIO,
        sistemaCultivo: SistemaCultivo.CONVENCIONAL,
      );

      _dataRecomendacaoController.text = FormatacaoUtil.formatDate(_dataRecomendacao);
      _dataPlantioController.text = FormatacaoUtil.formatDate(_dataPlantio);

      // Inicializar listas vazias pois é uma nova recomendação
      _initEmptyRecomendacoesLists();

      // Inicializar o DialogScreen mesmo para novas recomendações
      _initRecomendacaoDialogScreen();
    }
  }

  void _initRecomendacaoDialogScreen() {
    _recomendacaoDialogScreen = RecomendacaoDialogScreen(
      recomendacaoId: _recomendacao.id.isEmpty ? null : _recomendacao.id,
      calagemService: _calagemService,
      gessagemService: _gessagemService,
      nutrienteService: _nutrienteService,
      canEdit: true, // Permissão será verificada dentro do dialog screen
      canDelete: true, // Permissão será verificada dentro do dialog screen
      onUpdate: () {
        setState(() => _hasChanges = true);
        _loadRecomendacoes();
      },
      analise: _selectedAnalise,
      tipoCultura: _selectedCultura,
    );
  }

  void _initEmptyRecomendacoesLists() {
    // Inicializar futures com listas vazias
    _futureCalagemList = Future.value([]);
    _futureGessagemList = Future.value([]);
    _futureNutrientesList = Future.value([]);
  }

  void _loadRecomendacoes() {
    if (_recomendacao.id.isEmpty) {
      _initEmptyRecomendacoesLists();
      return;
    }

    setState(() {
      // Carregar todos os tipos de recomendações
      _futureCalagemList = _calagemService.getByAttributes({
        'recomendacaoId': _recomendacao.id,
      });

      _futureGessagemList = _gessagemService.getByAttributes({
        'recomendacaoId': _recomendacao.id,
      });

      _futureNutrientesList = _nutrienteService.getByAttributes({
        'recomendacaoId': _recomendacao.id,
      });
    });
  }

  Future<void> _loadAnaliseSolo() async {
    if (_recomendacao.resultadoAnaliseSoloId.isEmpty) return;

    try {
      final analise = await _analiseService.getById(_recomendacao.resultadoAnaliseSoloId);
      if (analise != null) {
        setState(() {
          _selectedAnalise = analise;
          _analiseController.text = 'Análise de ${FormatacaoUtil.formatDate(analise.dataAnalise)}';
          _selectedTexturaSolo = analise.texturaSolo ?? _recomendacao.texturaSolo;
        });
      }
    } catch (e) {
      print('Erro ao carregar análise: $e');
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

        // Atualize o dialog screen com a nova análise
        _recomendacaoDialogScreen = RecomendacaoDialogScreen(
          recomendacaoId: _recomendacao.id.isEmpty ? null : _recomendacao.id,
          calagemService: _calagemService,
          gessagemService: _gessagemService,
          nutrienteService: _nutrienteService,
          canEdit: true,
          canDelete: true,
          onUpdate: () {
            setState(() => _hasChanges = true);
            _loadRecomendacoes();
          },
          analise: _selectedAnalise,
          tipoCultura: _selectedCultura,
        );
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).confirm_exit_whitout_save),
        content: Text(S.of(context).confirm_exit_message_without_save),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).no),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context).yes),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _saveRecomendacao() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (!_validarCamposObrigatorios()) return;

    setState(() => _isLoading = true);

    try {
      final appStateManager = Provider.of<AppStateManager>(context, listen: false);

      // Preparar dados da recomendação
      final recomendacao = _recomendacao.copyWith(
        produtorId: appStateManager.activeProdutorId,
        propriedadeId: appStateManager.activePropriedadeId,
        talhaoId: _selectedAnalise?.talhoes?.first ?? '',
        dataRecomendacao: _dataRecomendacao,
        dataPlantio: _dataPlantio,
        produtividadeEsperada: double.parse(_produtividadeController.text),
        resultadoAnaliseSoloId: _selectedAnalise?.id ?? '',
        tipoCultura: _selectedCultura!,
        classeResposta: _selectedClasseResposta!,
        texturaSolo: _selectedTexturaSolo!,
        sistemaCultivo: _selectedSistemaCultivo!,
        irrigado: _isIrrigado,
        observacoes: _observacoesController.text.isNotEmpty
            ? _observacoesController.text.split('\n').where((s) => s.trim().isNotEmpty).toList()
            : [],
      );

      // Salvar recomendação
      String recomendacaoId;
      if (_recomendacao.id.isEmpty) {
        // Nova recomendação
        recomendacaoId = await _recomendacaoService.add(recomendacao, returnId: true) as String;
      } else {
        // Atualização
        await _recomendacaoService.update(_recomendacao.id, recomendacao);
        recomendacaoId = _recomendacao.id;
      }

      // Criar uma cópia com o ID
      final updatedRecomendacao = recomendacao.copyWith(id: recomendacaoId);

      // Atualizar o estado local e o RecomendacaoDialogScreen com o novo ID
      setState(() {
        _recomendacao = updatedRecomendacao;
        _recomendacaoDialogScreen = RecomendacaoDialogScreen(
          recomendacaoId: recomendacaoId,
          calagemService: _calagemService,
          gessagemService: _gessagemService,
          nutrienteService: _nutrienteService,
          canEdit: true,
          canDelete: true,
          onUpdate: () {
            setState(() => _hasChanges = true);
            _loadRecomendacoes();
          },
          analise: _selectedAnalise,
          tipoCultura: _selectedCultura,
        );
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).recomendation_created_successfully),
          backgroundColor: Colors.green,
        ),
      );

      // Não fechar o formulário após salvar, para permitir adicionar recomendações específicas
      // Navigator.of(context).pop(updatedRecomendacao);

      // Em vez disso, atualize as listas depois de salvar
      _loadRecomendacoes();

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).error_saving_soil_analysis(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validarCamposObrigatorios() {
    String? errorMessage;

    if (_selectedAnalise == null) {
      errorMessage = S.of(context).select_soil_analysis;
    } else if (_selectedCultura == null) {
      errorMessage = S.of(context).select_crop_type;
    } else if (_selectedClasseResposta == null) {
      errorMessage = S.of(context).select_type;
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

  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    return _isExpanded;
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'customFrotaForm': {
        'key': _identificacaoKey,
        'message': S.of(context).identification,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
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
      'sistema': {
        'key': _sistemaKey,
        'message': S.of(context).select_system_tutorial,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'parametros': {
        'key': _parametrosKey,
        'message': S.of(context).parameters,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'calagem': {
        'key': _calagemKey,
        'message': S.of(context).liming_tutorial,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'gessagem': {
        'key': _gessagemKey,
        'message': S.of(context).gypsum_tutorial,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'nutrientes': {
        'key': _nutrientesKey,
        'message': S.of(context).nutrients_tutorial,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final appStateManager = Provider.of<AppStateManager>(context);
    final theme = Theme.of(context);

    final String title = widget.recomendacao == null
        ? S.of(context).generate_recommendation
        : S.of(context).edit_recommendation;

    return FormTemplate(
      title: title,
      moduleName: 'recomendacoesAdubacao',
      formKey: _formKey,
      returnObject: _recomendacao,
      canEdit: true,
      onWillPop: _onWillPop,
      body: _buildFormContent(),
      onSave: _saveRecomendacao,
      isExpanded: _isExpanded,
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      showTutorial: false,
      isNewItem: widget.recomendacao == null,
      cardSections: [
        _buildRecomendacaoCalagemCard(),
        _buildRecomendacaoGessagemCard(),
        _buildRecomendacaoNutrientesCard(),
      ],
      additionalFloatingActionButtons: (BuildContext context) => [
        if (!_recomendacao.id.isEmpty) ...[
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () {
              _toggleFloatingActionButton();
              _recomendacaoDialogScreen.addNutriente(context);
            },
            icon: Icons.biotech,
            text: S.of(context).add_nutrient,
            key: _addNutrienteKey,
            heroTag: 'addNutriente',
          ),
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () {
              _toggleFloatingActionButton();
              _recomendacaoDialogScreen.addGessagem(context);
            },
            icon: Icons.format_color_fill,
            text: S.of(context).add_gypsum,
            key: _addGessagemKey,
            heroTag: 'addGessagem',
          ),
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () {
              _toggleFloatingActionButton();
              _recomendacaoDialogScreen.addCalagem(context);
            },
            icon: Icons.grain,
            text: S.of(context).add_liming,
            key: _addCalagemKey,
            heroTag: 'addCalagem',
          ),
        ],
      ],
    );
  }

  Widget _buildFormContent() {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecomendacaoIdentificacaoCard(),
          const SizedBox(height: 16),
          _buildAnaliseCard(),
          const SizedBox(height: 16),
          _buildCulturaCard(),
          const SizedBox(height: 16),
          _buildSistemaCard(),
          const SizedBox(height: 16),
          _buildParametrosCard(),
          const SizedBox(height: 16),
          _buildObservacoesCard(),
        ],
      ),
    );
  }

  CardSection _buildRecomendacaoCalagemCard() {
    return CardSection(
      key: _calagemKey,
      title: S.of(context).liming_recommendations,
      icon: Icons.grain, // Usar o mesmo ícone da tela de visualização
      cards: [
        FutureBuilder<List<RecomendacaoCalagem>>(
          future: _futureCalagemList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                leading: const CircularProgressIndicator(),
                title: Text(S.of(context).loading),
              );
            } else if (snapshot.hasError) {
              return ListTile(
                leading: Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(S.of(context).error_loading),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListTile(
                leading: Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(S.of(context).no_liming_recommendations),
              );
            } else {
              return Column(
                children: snapshot.data!.map((calagem) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    color: Colors.amber.withOpacity(0.1), // Cor de fundo para calagem como na tela de visualização
                    child: ListTile(
                      leading: Icon(
                        Icons.grain,
                        color: Colors.amber, // Cor do ícone para calagem
                      ),
                      title: Text(
                        '${S.of(context).saturation_base}: ${calagem.saturacaoBasesDesejada.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${S.of(context).recommended_quantity}: ${calagem.quantidadeRecomendada.toStringAsFixed(2)} t/ha'),
                          Text('${S.of(context).limestone_type}: ${calagem.tipoCalcario}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        key: _firstCalagemMoreOptionsKey,
                        onSelected: (value) {
                          if (value == 'edit') {
                            _recomendacaoDialogScreen.editCalagem(context, calagem);
                          } else if (value == 'delete') {
                            _recomendacaoDialogScreen.deleteCalagem(context, calagem);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text(
                              S.of(context).edit,
                              style: Theme.of(context).popupMenuTheme.textStyle,
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(
                              S.of(context).delete,
                              style: Theme.of(context).popupMenuTheme.textStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  CardSection _buildRecomendacaoGessagemCard() {
    return CardSection(
      key: _gessagemKey,
      title: S.of(context).gypsum_recommendations,
      icon: Icons.format_color_fill, // Usar o mesmo ícone da tela de visualização
      cards: [
        FutureBuilder<List<RecomendacaoGessagem>>(
          future: _futureGessagemList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                leading: const CircularProgressIndicator(),
                title: Text(S.of(context).loading),
              );
            } else if (snapshot.hasError) {
              return ListTile(
                leading: Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(S.of(context).error_loading),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListTile(
                leading: Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(S.of(context).no_gypsum_recommendations),
              );
            } else {
              return Column(
                children: snapshot.data!.map((gessagem) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    color: Colors.blue.withOpacity(0.1), // Cor de fundo para gessagem como na tela de visualização
                    child: ListTile(
                      leading: Icon(
                        Icons.format_color_fill,
                        color: Colors.blue, // Cor do ícone para gessagem
                      ),
                      title: Text(
                        '${S.of(context).aluminum_saturation}: ${gessagem.saturacaoAluminio.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${S.of(context).recommended_dose}: ${gessagem.doseRecomendada.toStringAsFixed(2)} t/ha'),
                          Text('${S.of(context).application_mode}: ${gessagem.modoAplicacao}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        key: _firstGessagemMoreOptionsKey,
                        onSelected: (value) {
                          if (value == 'edit') {
                            _recomendacaoDialogScreen.editGessagem(context, gessagem);
                          } else if (value == 'delete') {
                            _recomendacaoDialogScreen.deleteGessagem(context, gessagem);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text(
                              S.of(context).edit,
                              style: Theme.of(context).popupMenuTheme.textStyle,
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(
                              S.of(context).delete,
                              style: Theme.of(context).popupMenuTheme.textStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  CardSection _buildRecomendacaoNutrientesCard() {
    return CardSection(
      key: _nutrientesKey,
      title: S.of(context).nutrient_recommendations,
      icon: Icons.biotech,
      cards: [
        FutureBuilder<List<RecomendacaoNutriente>>(
          future: _futureNutrientesList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                leading: const CircularProgressIndicator(),
                title: Text(S.of(context).loading),
              );
            } else if (snapshot.hasError) {
              return ListTile(
                leading: Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(S.of(context).error_loading),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListTile(
                leading: Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(S.of(context).no_nutrient_recommendations),
              );
            } else {
              return Column(
                children: snapshot.data!.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final nutriente = entry.value;
                  final Color cardColor = ManualAdubacaoOptions.getNutrienteColor(
                      nutriente.nutriente,
                      defaultColor: Theme.of(context).colorScheme.primary
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    color: cardColor.withOpacity(0.1),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          ManualAdubacaoOptions.getNutrienteSimbolo(nutriente.nutriente),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                        ),
                      ),
                      title: Text(
                        nutriente.nutriente,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${S.of(context).content}: ${nutriente.teor.toStringAsFixed(2)} mg/dm³'),
                          Text('${S.of(context).recommended_dose}: ${nutriente.doseRecomendada.toStringAsFixed(2)} kg/ha'),
                          if (nutriente.fonte != null && nutriente.fonte!.isNotEmpty)
                            Text('${S.of(context).source}: ${nutriente.fonte}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        key: index == 0 ? _firstNutrienteMoreOptionsKey : null,
                        onSelected: (value) {
                          if (value == 'edit') {
                            _recomendacaoDialogScreen.editNutriente(context, nutriente);
                          } else if (value == 'delete') {
                            _recomendacaoDialogScreen.deleteNutriente(context, nutriente);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text(
                              S.of(context).edit,
                              style: Theme.of(context).popupMenuTheme.textStyle,
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(
                              S.of(context).delete,
                              style: Theme.of(context).popupMenuTheme.textStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }





  Widget _buildFormBody() {
    final theme = Theme.of(context);
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecomendacaoIdentificacaoCard(),
          const SizedBox(height: 16),
          _buildAnaliseCard(),
          const SizedBox(height: 16),
          _buildCulturaCard(),
          const SizedBox(height: 16),
          _buildSistemaCard(),
          const SizedBox(height: 16),
          _buildParametrosCard(),
          const SizedBox(height: 16),
          _buildObservacoesCard(),
        ],
      ),
    );
  }

  Widget _buildRecomendacaoIdentificacaoCard() {
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
                Icon(Icons.description,
                    color: theme.colorScheme.primary,
                    size: 28
                ),
                SizedBox(width: 10),
                Text(
                  S.of(context).identification,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            TextFormField(
              controller: _dataRecomendacaoController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).recommendation_date,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dataRecomendacao,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _dataRecomendacao = date;
                    _dataRecomendacaoController.text = FormatacaoUtil.formatDate(date);
                    _hasChanges = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnaliseCard() {
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
                Icon(Icons.science,
                    color: theme.colorScheme.primary,
                    size: 28
                ),
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

  Widget _buildCulturaCard() {
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
                Icon(Icons.grass,
                    color: theme.colorScheme.primary,
                    size: 28
                ),
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
              key: _culturaFieldKey,
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

                    // Atualizar tipoCultura no dialogScreen
                    _recomendacaoDialogScreen = RecomendacaoDialogScreen(
                      recomendacaoId: _recomendacao.id.isEmpty ? null : _recomendacao.id,
                      calagemService: _calagemService,
                      gessagemService: _gessagemService,
                      nutrienteService: _nutrienteService,
                      canEdit: true,
                      canDelete: true,
                      onUpdate: () {
                        setState(() => _hasChanges = true);
                        _loadRecomendacoes();
                      },
                      analise: _selectedAnalise,
                      tipoCultura: _selectedCultura,
                    );
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
              key: _classeRespostaFieldKey,
              labelText: S.of(context).type,
              value: _selectedClasseResposta != null ? _selectedClasseResposta.toString().split('.').last : null,
              items: ClasseResposta.values.map((e) => e.toString().split('.').last).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedClasseResposta = ClasseResposta.values.firstWhere(
                          (e) => e.toString().split('.').last == value,
                      orElse: () => ClasseResposta.MEDIA_BAIXA,
                    );
                    _hasChanges = true;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).select_type;
                }
                return null;
              },
              dropdownItems: ClasseResposta.values.map((classe) {
                return DropdownMenuItem<String>(
                  value: classe.toString().split('.').last,
                  child: Text(classe.getLocalizedName(context)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ObjectTemplate.getDropdownButtonFormField(
              context: context,
              key: _texturaFieldKey,
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

  Widget _buildSistemaCard() {
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
                Icon(Icons.settings,
                    color: theme.colorScheme.primary,
                    size: 28
                ),
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
              key: _sistemaFieldKey,
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

  Widget _buildParametrosCard() {
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
                Icon(Icons.tune,
                    color: theme.colorScheme.primary,
                    size: 28
                ),
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
              key: _dataPlantioKey,
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
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildObservacoesCard() {
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
                Icon(Icons.note,
                    color: theme.colorScheme.primary,
                    size: 28
                ),
                SizedBox(width: 10),
                Text(
                  S.of(context).observations,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            TextFormField(
              controller: _observacoesController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).observations,
              ),
              maxLines: 4,
              onChanged: (value) => _hasChanges = true,
            ),
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
          if (_selectedAnalise!.laboratorioId.isNotEmpty)
            _buildInfoRow(
                Icons.science,
                S.of(context).laboratory,
                _selectedAnalise!.laboratorioId
            ),
          // Mostrar talhões
          if (_selectedAnalise!.talhoes != null && _selectedAnalise!.talhoes!.isNotEmpty)
            _buildInfoRow(
                Icons.grid_on,
                S.of(context).plot,
                _selectedAnalise!.talhoes!.join(', ')
            ),
          // Mostrar informações de fertilidade
          _buildInfoRow(
              Icons.ac_unit,
              'pH',
              _selectedAnalise!.pH.toStringAsFixed(1)
          ),
          _buildInfoRow(
              Icons.view_in_ar,
              'CTC (mmolc/dm³)',
              _selectedAnalise!.ctc.toStringAsFixed(1)
          ),
          _buildInfoRow(
              Icons.explicit,
              'V% (${S.of(context).base_saturation})',
              _selectedAnalise!.saturacaoBase.toStringAsFixed(1)
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
                  style: theme.textTheme.bodySmall,
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
}