// lib/screens/agro/adubacao/resultado_analise_solo_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/models/pessoa.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/screens/appbar/pessoas_list_screen.dart';
import 'package:planejacampo/services/agro/adubacao/resultado_analise_solo_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/screens/appbar/talhoes_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';

class ResultadoAnaliseSoloFormScreen extends StatefulWidget {
  final ResultadoAnaliseSolo? resultadoAnaliseSolo;

  const ResultadoAnaliseSoloFormScreen({
    Key? key,
    this.resultadoAnaliseSolo,
  }) : super(key: key);

  @override
  _ResultadoAnaliseSoloFormScreenState createState() => _ResultadoAnaliseSoloFormScreenState();
}

class _ResultadoAnaliseSoloFormScreenState extends State<ResultadoAnaliseSoloFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ResultadoAnaliseSolo _currentAnaliseSolo;

  // Services
  final ResultadoAnaliseSoloService _analiseSoloService = ResultadoAnaliseSoloService();
  final TalhaoService _talhaoService = TalhaoService();
  final PessoaService _pessoaService = PessoaService();

  // Estado e controle
  List<String> _selectedTalhoes = [];
  String? _laboratorioId;
  String? _responsavelColetaId;
  TexturaSolo? _selectedTexturaSolo;
  ProfundidadeAmostra _selectedProfundidadeAmostra = ProfundidadeAmostra.SUPERFICIAL;
  bool _hasChanges = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  Object _returnObject = false;

  // Keys para tutorial
  final GlobalKey _identificacaoKey = GlobalKey();
  final GlobalKey _analiseQuimicaKey = GlobalKey();
  final GlobalKey _micronutrientesKey = GlobalKey();
  final GlobalKey _analiseGranulometricaKey = GlobalKey();
  final GlobalKey _metodologiaKey = GlobalKey();
  final GlobalKey _analiseFisicaSoloKey = GlobalKey();

  // Controllers para campos gerais
  final TextEditingController _laboratorioController = TextEditingController();
  TextEditingController _metodologiaController = TextEditingController();
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _dataColetaController = TextEditingController();
  final TextEditingController _dataAnaliseController = TextEditingController();
  final TextEditingController _talhaoController = TextEditingController();

  // Controllers para pH e acidez
  late TextEditingController _phController;
  late TextEditingController _alController;
  late TextEditingController _hAlController;

  // Controllers para macronutrientes
  late TextEditingController _pResinaController;
  late TextEditingController _potassioController;
  late TextEditingController _calcioController;
  late TextEditingController _magnesioController;
  late TextEditingController _enxofreController;

  // Controllers para micronutrientes
  late TextEditingController _boroController;
  late TextEditingController _cobreController;
  late TextEditingController _ferroController;
  late TextEditingController _manganesController;
  late TextEditingController _zincoController;

  // Controllers para matéria orgânica
  late TextEditingController _moController;
  late TextEditingController _coController;

  // Controllers para análise física
  late TextEditingController _silteController;
  late TextEditingController _argilaController;
  late TextEditingController _sodioController;

  // Controller para areiaTotal
  final TextEditingController _areiaTotalController = TextEditingController();

  // Controllers para areiaGrossa e areiaFina
  late TextEditingController _areiaGrossaController;
  late TextEditingController _areiaFinaController;

  late MetodoExtracao _selectedMetodoExtracao;

  // Campos calculados
  double _computedAreiaTotal = 1000.0; // Inicializa com 1000 g/kg
  TexturaSolo? _computedTexturaSolo;

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit('recomendacoesAdubacao');
    _canDelete = appStateManager.canDelete('recomendacoesAdubacao');
    _showTutorial = appStateManager.showTutorial('resultadoAnaliseSoloFormScreen');
    appStateManager.setShowTutorial('resultadoAnaliseSoloFormScreen', false);

    _initializeCurrentAnaliseSolo();
    _initializeControllers();

    _selectedMetodoExtracao = widget.resultadoAnaliseSolo?.metodologiaExtracao != null
        ? MetodoExtracao.values.firstWhere(
          (e) => e.toString().split('.').last == widget.resultadoAnaliseSolo!.metodologiaExtracao,
      orElse: () => MetodoExtracao.MEHLICH,
    )
        : MetodoExtracao.MEHLICH;
  }

  void _initializeCurrentAnaliseSolo() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _currentAnaliseSolo = widget.resultadoAnaliseSolo ??
        ResultadoAnaliseSolo(
          id: DateTime.now().toString(),
          produtorId: appStateManager.activeProdutorId!,
          propriedadeId: appStateManager.activePropriedadeId!,
          talhoes: [], // Inicializado como lista vazia
          laboratorioId: '',
          metodologiaExtracao: '',
          responsavelColetaId: '',
          dataColeta: DateTime.now(),
          dataAnalise: DateTime.now(),
          pH: 0.0,
          al: 0.0,
          hAl: 0.0,
          fosforo: 0.0,
          potassio: 0.0,
          calcio: 0.0,
          magnesio: 0.0,
          enxofre: 0.0,
          boro: 0.0,
          cobre: 0.0,
          ferro: 0.0,
          manganes: 0.0,
          zinco: 0.0,
          mo: 0.0,
          co: 0.0,
          silte: 0.0,
          argila: 0.0,
          areiaTotal: 1000.0, // Inicializa com 1000 g/kg
          areiaGrossa: 0.0,
          areiaFina: 0.0,
          sodio: 0.0,
          profundidadeAmostra: ProfundidadeAmostra.SUPERFICIAL, // Atribuição correta do enum
          texturaSolo: null,
          observacoes: [],
        );
    if (widget.resultadoAnaliseSolo != null) {
      _laboratorioId = widget.resultadoAnaliseSolo!.laboratorioId;
      _responsavelColetaId = widget.resultadoAnaliseSolo!.responsavelColetaId;
      _computedAreiaTotal = widget.resultadoAnaliseSolo!.areiaTotal;
      // Removido: Inicialização dos controladores
      // _areiaGrossaController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.areiaGrossa);
      // _areiaFinaController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.areiaFina);
      // _computeAreiaTotal();
      // _computeTexturaSolo();
    }
  }

  void _initializeControllers() {
    // Inicializa campos gerais
    _metodologiaController = TextEditingController(text: _currentAnaliseSolo.metodologiaExtracao);
    _dataColetaController.text = FormatacaoUtil.formatDate(_currentAnaliseSolo.dataColeta);
    _dataAnaliseController.text = FormatacaoUtil.formatDate(_currentAnaliseSolo.dataAnalise);
    _selectedProfundidadeAmostra = _currentAnaliseSolo.profundidadeAmostra;

    // Inicializa controllers numéricos usando FormatacaoUtil
    _phController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.pH);
    _alController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.al);
    _hAlController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.hAl);

    _pResinaController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.fosforo);
    _potassioController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.potassio);
    _calcioController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.calcio);
    _magnesioController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.magnesio);
    _enxofreController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.enxofre);

    _boroController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.boro);
    _cobreController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.cobre);
    _ferroController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.ferro);
    _manganesController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.manganes);
    _zincoController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.zinco);

    _moController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.mo);
    _coController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.co);

    _silteController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.silte);
    _argilaController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.argila);
    _sodioController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.sodio);

    // Inicializa o controller de areiaTotal
    _areiaTotalController.text = _currentAnaliseSolo.areiaTotal.toStringAsFixed(1);

    // Inicializa os controllers de areiaGrossa e areiaFina com mascaramento
    _areiaGrossaController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.areiaGrossa);
    _areiaFinaController = FormatacaoUtil.getMaskedTextController(_currentAnaliseSolo.areiaFina);

    // Define os valores iniciais formatados usando um método de formatação adequado
    // Esses métodos foram comentados conforme instrução do usuário
    //_areiaGrossaController.text = FormatacaoUtil.formatNumber(_currentAnaliseSolo.areiaGrossa, 2);
    //_areiaFinaController.text = FormatacaoUtil.formatNumber(_currentAnaliseSolo.areiaFina, 2);

    _selectedTalhoes = _currentAnaliseSolo.talhoes ?? [];
    _selectedTexturaSolo = _currentAnaliseSolo.texturaSolo;

    if (_selectedTalhoes.isNotEmpty) {
      _loadTalhaoDetails();
    }

    // Carrega os nomes do laboratório e do responsável, se existirem
    if (_currentAnaliseSolo.laboratorioId.isNotEmpty) {
      _loadLaboratorioDetails();
    }

    if (_currentAnaliseSolo.responsavelColetaId.isNotEmpty) {
      _loadResponsavelColetaDetails();
    }

    // Adiciona listeners para recalcular 'areiaTotal' e calcular a textura do solo
    _silteController.addListener(() {
      setState(() {
        _hasChanges = true;
        _computeAreiaTotal();
        _computeTexturaSolo();
      });
    });

    _argilaController.addListener(() {
      setState(() {
        _hasChanges = true;
        _computeAreiaTotal();
        _computeTexturaSolo();
      });
    });

    // Adiciona listeners para recalcular a validação de areiaGrossa e areiaFina
    _areiaGrossaController.addListener(() {
      setState(() {
        _hasChanges = true;
      });
    });

    _areiaFinaController.addListener(() {
      setState(() {
        _hasChanges = true;
      });
    });

    // **Chame as funções de cálculo após inicializar os controladores**
    _computeAreiaTotal();
    _computeTexturaSolo();
  }

  void _computeAreiaTotal() {
    double silte = FormatacaoUtil.instance.parseNumber(_silteController.text);
    double argila = FormatacaoUtil.instance.parseNumber(_argilaController.text);
    double areiaTotal = 1000 - (silte + argila);

    setState(() {
      _computedAreiaTotal = areiaTotal;
      _areiaTotalController.text = _computedAreiaTotal.toStringAsFixed(1);
    });
  }

  void _computeTexturaSolo() {
    double argila = FormatacaoUtil.instance.parseNumber(_argilaController.text);

    if (argila > 350) {
      _computedTexturaSolo = TexturaSolo.ARGILOSO;
    } else if (argila > 150) {
      _computedTexturaSolo = TexturaSolo.MEDIO;
    } else {
      _computedTexturaSolo = TexturaSolo.ARENOSO;
    }
  }

  void _loadTalhaoDetails() async {
    if (_selectedTalhoes.isNotEmpty) {
      // Supondo que você queira concatenar os nomes dos talhões
      List<String> nomesTalhoes = [];
      for (var talhaoId in _selectedTalhoes) {
        final talhao = await _talhaoService.getById(talhaoId);
        if (talhao != null) {
          nomesTalhoes.add(talhao.nome);
        }
      }
      if (mounted) {
        setState(() {
          _talhaoController.text = nomesTalhoes.join(', ');
          _hasChanges = true;
        });
      }
    }
  }

  Future<void> _selectTalhao() async {
    final selectedTalhoes = await Navigator.push<List<Talhao>>(
      context,
      MaterialPageRoute(
        builder: (context) => TalhoesListScreen(isSelectMode: true),
      ),
    );

    if (selectedTalhoes != null && mounted) {
      setState(() {
        _selectedTalhoes = selectedTalhoes.map((talhao) => talhao.id).toList();
        _talhaoController.text = selectedTalhoes.map((talhao) => talhao.nome).join(', ');
        _hasChanges = true;
      });
    }
  }

  void _selectLaboratorio() async {
    final selectedPessoa = await Navigator.push<Pessoa>(
      context,
      MaterialPageRoute(
        builder: (context) => PessoasListScreen(
          isSelectMode: true,
          vinculos: ['Fornecedor'], // Apenas fornecedores para laboratório
        ),
      ),
    );

    if (selectedPessoa != null && mounted) {
      setState(() {
        _laboratorioId = selectedPessoa.id;
        _laboratorioController.text = selectedPessoa.nome;
        _hasChanges = true;
      });
    }
  }

  void _selectResponsavelColeta() async {
    final selectedPessoa = await Navigator.push<Pessoa>(
      context,
      MaterialPageRoute(
        builder: (context) => PessoasListScreen(
          isSelectMode: true,
          vinculos: ['Funcionario', 'Parceiro', 'Fornecedor'], // Múltiplos tipos
        ),
      ),
    );

    if (selectedPessoa != null && mounted) {
      setState(() {
        _responsavelColetaId = selectedPessoa.id;
        _responsavelController.text = selectedPessoa.nome;
        _hasChanges = true;
      });
    }
  }

  void _loadLaboratorioDetails() async {
    final laboratorio = await _pessoaService.getById(_currentAnaliseSolo.laboratorioId);
    if (laboratorio != null && mounted) {
      setState(() {
        _laboratorioController.text = laboratorio.nome;
      });
    }
  }

  void _loadResponsavelColetaDetails() async {
    final responsavel = await _pessoaService.getById(_currentAnaliseSolo.responsavelColetaId);
    if (responsavel != null && mounted) {
      setState(() {
        _responsavelController.text = responsavel.nome;
      });
    }
  }

  Future<void> _saveAnaliseSolo() async {
    if (_canEdit) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        try {
          // Recupera os valores
          double silte = FormatacaoUtil.instance.parseNumber(_silteController.text);
          double argila = FormatacaoUtil.instance.parseNumber(_argilaController.text);
          double areiaTotal = _computedAreiaTotal;
          double areiaGrossa = FormatacaoUtil.instance.parseNumber(_areiaGrossaController.text);
          double areiaFina = FormatacaoUtil.instance.parseNumber(_areiaFinaController.text);

          // Removida a validação da soma de Areia Grossa e Areia Fina
          /*
          if ((areiaGrossa + areiaFina) != areiaTotal) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  S.of(context).sum_of_coarse_and_fine_sand_must_equal_total_areia != null
                      ? S.of(context).sum_of_coarse_and_fine_sand_must_equal_total_areia(areiaTotal.toStringAsFixed(1))
                      : 'A soma de Areia Grossa e Areia Fina deve ser igual a Areia Total ($areiaTotal g/kg).',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          */

          // Calcula a textura do solo
          TexturaSolo? textura = _computedTexturaSolo;

          _currentAnaliseSolo = _currentAnaliseSolo.copyWith(
            talhoes: _selectedTalhoes,
            laboratorioId: _laboratorioId ?? '',
            metodologiaExtracao: _selectedMetodoExtracao.toString().split('.').last,
            responsavelColetaId: _responsavelColetaId ?? '',
            dataColeta: _currentAnaliseSolo.dataColeta,
            dataAnalise: _currentAnaliseSolo.dataAnalise,
            profundidadeAmostra: _selectedProfundidadeAmostra,
            pH: FormatacaoUtil.instance.parseNumber(_phController.text),
            al: FormatacaoUtil.instance.parseNumber(_alController.text),
            hAl: FormatacaoUtil.instance.parseNumber(_hAlController.text),
            fosforo: FormatacaoUtil.instance.parseNumber(_pResinaController.text),
            potassio: FormatacaoUtil.instance.parseNumber(_potassioController.text),
            calcio: FormatacaoUtil.instance.parseNumber(_calcioController.text),
            magnesio: FormatacaoUtil.instance.parseNumber(_magnesioController.text),
            enxofre: FormatacaoUtil.instance.parseNumber(_enxofreController.text),
            boro: FormatacaoUtil.instance.parseNumber(_boroController.text),
            cobre: FormatacaoUtil.instance.parseNumber(_cobreController.text),
            ferro: FormatacaoUtil.instance.parseNumber(_ferroController.text),
            manganes: FormatacaoUtil.instance.parseNumber(_manganesController.text),
            zinco: FormatacaoUtil.instance.parseNumber(_zincoController.text),
            mo: FormatacaoUtil.instance.parseNumber(_moController.text),
            co: FormatacaoUtil.instance.parseNumber(_coController.text),
            silte: silte,
            argila: argila,
            sodio: FormatacaoUtil.instance.parseNumber(_sodioController.text),
            texturaSolo: textura,
            areiaTotal: areiaTotal, // Agora corretamente aceito no copyWith
            areiaGrossa: areiaGrossa,
            areiaFina: areiaFina,
          );

          if (widget.resultadoAnaliseSolo == null) {
            await _analiseSoloService.add(_currentAnaliseSolo);
          } else {
            await _analiseSoloService.update(_currentAnaliseSolo.id, _currentAnaliseSolo);
          }

          _returnObject = widget.resultadoAnaliseSolo == null ? true : _currentAnaliseSolo;
          if (!mounted) return;
          Navigator.of(context).pop(_returnObject);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context).error_saving_soil_analysis != null
                    ? S.of(context).error_saving_soil_analysis(e.toString())
                    : 'Erro ao salvar análise de solo: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).no_permission_to_save != null
                ? S.of(context).no_permission_to_save(S.of(context).soil_analysis)
                : 'Você não tem permissão para salvar a análise de solo.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
    }
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).required_field;
    }
    try {
      final number = double.parse(value.replaceAll(',', '.'));
      if (number < 0) {
        return S.of(context).value_must_be_positive;
      }
    } catch (e) {
      return S.of(context).invalid_number;
    }
    return null;
  }

  String? _validateSilteArgila(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).required_field;
    }
    try {
      // Obtém os valores de Silte e Argila
      final silte = double.parse(_silteController.text.replaceAll(',', '.'));
      final argila = double.parse(_argilaController.text.replaceAll(',', '.'));

      // Calcula a soma de Silte e Argila
      if ((silte + argila) > 1000) {
        return S.of(context).sum_of_silt_and_clay_cannot_exceed_1000;
      }
    } catch (e) {
      return S.of(context).invalid_number;
    }
    return null;
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'identificacao': {
        'key': _identificacaoKey,
        'message': S.of(context).soil_analysis_identification,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'analiseQuimica': {
        'key': _analiseQuimicaKey,
        'message': S.of(context).chemical_analysis_results,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'micronutrientes': {
        'key': _micronutrientesKey,
        'message': S.of(context).micronutrients,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'analiseGranulometrica': {
        'key': _analiseGranulometricaKey,
        'message': S.of(context).granulometric_analysis,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'metodologia': {
        'key': _metodologiaKey,
        'message': S.of(context).extraction_methodology,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'analiseFisicaSolo': {
        'key': _analiseFisicaSoloKey,
        'message': S.of(context).soil_physical_analysis, // Certifique-se de adicionar esta chave de localização
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges ? _currentAnaliseSolo : _returnObject);
        return false;
      },
      child: FormTemplate(
        title: widget.resultadoAnaliseSolo == null
            ? S.of(context).add_soil_analysis
            : S.of(context).edit_soil_analysis,
        formKey: _formKey,
        onSave: _saveAnaliseSolo,
        moduleName: 'recomendacoesAdubacao',
        isNewItem: widget.resultadoAnaliseSolo == null,
        canEdit: _canEdit,
        canDelete: _canDelete,
        showTutorial: _showTutorial,
        customTutorialSteps: _buildCustomTutorialSteps(),
        returnObject: _returnObject,
        onWillPop: () async => true,
        body: _buildFormBody(),
      ),
    );
  }

  Widget _buildFormBody() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Identificação
            _buildSectionHeader(
              theme,
              Icons.assignment,
              S.of(context).identification,
              key: _identificacaoKey,
            ),
            SizedBox(height: 16),
            _buildIdentificationSection(),
            SizedBox(height: 24),

            // 2. Metodologia de Extração
            _buildSectionHeader(
              theme,
              Icons.science,
              S.of(context).extraction_methodology,
              key: _metodologiaKey,
            ),
            SizedBox(height: 16),
            _buildExtractionMethodologySection(),
            SizedBox(height: 24),

            // 3. Análises Químicas
            _buildSectionHeader(
              theme,
              Icons.science,
              S.of(context).chemical_analysis_results,
              key: _analiseQuimicaKey,
            ),
            SizedBox(height: 16),
            _buildChemicalAnalysisSection(),
            SizedBox(height: 24),

            // 4. Micronutrientes
            _buildSectionHeader(
              theme,
              Icons.biotech,
              S.of(context).micronutrients,
              key: _micronutrientesKey,
            ),
            SizedBox(height: 16),
            _buildMicronutrientsSection(),
            SizedBox(height: 24),

            // 5. Análise Granulométrica
            _buildSectionHeader(
              theme,
              Icons.grain,
              S.of(context).granulometric_analysis,
              key: _analiseGranulometricaKey,
            ),
            SizedBox(height: 16),
            _buildGranulometricSection(),
            SizedBox(height: 24),

            // 6. Análise Física do Solo (opcional)
            /*
            _buildSectionHeader(
              theme,
              Icons.grain,
              S.of(context).soil_physical_analysis,
              key: _analiseFisicaSoloKey,
            ),
            SizedBox(height: 16),
            _buildSoilPhysicalAnalysisSection(),
            SizedBox(height: 24),
            */
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, IconData icon, String title, {Key? key}) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        SizedBox(width: 8),
        Expanded( // Adicionado Expanded para evitar overflow
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis, // Adicionado para lidar com textos longos
          ),
        ),
      ],
    );
  }

  Widget _buildIdentificationSection() {
    return Column(
      children: [
        // Campo para Selecionar Talhões
        TextFormField(
          controller: _talhaoController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).plots,
            suffixIcon: Icon(Icons.search),
          ),
          readOnly: true,
          onTap: _selectTalhao,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return S.of(context).select_talhao;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Campo para Selecionar Laboratório
        TextFormField(
          controller: _laboratorioController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).laboratory,
            suffixIcon: Icon(Icons.person_search),
          ),
          readOnly: true,
          onTap: _selectLaboratorio,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return S.of(context).enter_laboratory;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Campo para Selecionar Responsável pela Coleta
        TextFormField(
          controller: _responsavelController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).collection_responsible,
            suffixIcon: Icon(Icons.person_search),
          ),
          readOnly: true,
          onTap: _selectResponsavelColeta,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return S.of(context).enter_responsible;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Campos para Data de Coleta e Análise
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _dataColetaController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).collection_date,
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _currentAnaliseSolo.dataColeta,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _currentAnaliseSolo = _currentAnaliseSolo.copyWith(dataColeta: pickedDate);
                      _dataColetaController.text = FormatacaoUtil.formatDate(pickedDate);
                      _hasChanges = true;
                      _computeAreiaTotal();
                      _computeTexturaSolo();
                    });
                  }
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return S.of(context).select_collection_date;
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _dataAnaliseController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).analysis_date,
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _currentAnaliseSolo.dataAnalise,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _currentAnaliseSolo = _currentAnaliseSolo.copyWith(dataAnalise: pickedDate);
                      _dataAnaliseController.text = FormatacaoUtil.formatDate(pickedDate);
                      _hasChanges = true;
                      _computeAreiaTotal();
                      _computeTexturaSolo();
                    });
                  }
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return S.of(context).select_analysis_date;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Campo para Profundidade da Amostra
        SizedBox(
          width: double.infinity, // Garante que ocupe toda a largura disponível
          child: DropdownButtonFormField<ProfundidadeAmostra>(
            decoration: ObjectTemplate.getInputDecoration(
              context,
              S.of(context).sample_depth,
            ),
            value: _selectedProfundidadeAmostra,
            isExpanded: true, // Adicionado para expandir o dropdown
            items: ProfundidadeAmostra.values.map((ProfundidadeAmostra profundidade) {
              return DropdownMenuItem<ProfundidadeAmostra>(
                value: profundidade,
                child: Text(
                  profundidade.getLocalizedName(context),
                  overflow: TextOverflow.ellipsis, // Evita overflow do texto
                ),
              );
            }).toList(),
            onChanged: (ProfundidadeAmostra? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedProfundidadeAmostra = newValue;
                  _hasChanges = true;
                });
              }
            },
            validator: (value) {
              if (value == null) {
                return S.of(context).select_sample_depth;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExtractionMethodologySection() {
    return DropdownButtonFormField<MetodoExtracao>(
      decoration: ObjectTemplate.getInputDecoration(
        context,
        S.of(context).extraction_method,
        suffixIcon: Icon(Icons.science),
      ),
      value: _selectedMetodoExtracao,
      items: MetodoExtracao.values.map((metodo) {
        return DropdownMenuItem<MetodoExtracao>(
          value: metodo,
          child: Text(metodo.getLocalizedName(context)),
        );
      }).toList(),
      onChanged: (MetodoExtracao? value) {
        if (value != null) {
          setState(() {
            _selectedMetodoExtracao = value;
            _metodologiaController.text = value.toString().split('.').last;
            _hasChanges = true;
          });
        }
      },
      validator: (value) {
        if (value == null) {
          return S.of(context).select_extraction_method;
        }
        return null;
      },
    );
  }

  Widget _buildChemicalAnalysisSection() {
    return Column(
      children: [
        // pH CaCl2
        TextFormField(
          controller: _phController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).ph_cacl2,
            suffixIcon: Icon(Icons.science),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            setState(() {
              _hasChanges = true;
            });
          },
          validator: _validateNumber,
        ),
        SizedBox(height: 16),

        // Fósforo
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pResinaController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  _selectedMetodoExtracao == MetodoExtracao.MEHLICH
                      ? S.of(context).phosphorus_mehlich
                      : S.of(context).phosphorus_resin,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // S-SO4
        TextFormField(
          controller: _enxofreController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).sulfur,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            setState(() {
              _hasChanges = true;
            });
          },
          validator: _validateNumber,
        ),
        SizedBox(height: 16),

        // K+, Ca2+
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _potassioController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).potassium,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _calcioController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).calcium,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Mg2+, Na+
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _magnesioController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).magnesium,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _sodioController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).sodium,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Al3+, H+Al
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _alController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).exchangeable_aluminum,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _hAlController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).potential_acidity,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // MO e CO
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _moController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).organic_matter,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _coController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).organic_carbon,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMicronutrientsSection() {
    return Column(
      children: [
        // Boro
        TextFormField(
          controller: _boroController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).boron,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            setState(() {
              _hasChanges = true;
            });
          },
          validator: _validateNumber,
        ),
        SizedBox(height: 16),

        // Cobre e Ferro
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cobreController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).copper,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _ferroController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).iron,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Manganês e Zinco
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _manganesController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).manganese,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _zincoController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).zinc,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                validator: _validateNumber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGranulometricSection() {
    return Column(
      children: [
        // Silte e Argila
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _silteController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).silt,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  // Removida a lógica de recalculação direta
                  _computeAreiaTotal();
                  _computeTexturaSolo();
                },
                validator: _validateSilteArgila,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _argilaController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).clay,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  // Removida a lógica de recalculação direta
                  _computeAreiaTotal();
                  _computeTexturaSolo();
                },
                validator: _validateSilteArgila,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Areia Total (Read-Only)
        TextFormField(
          controller: _areiaTotalController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).total_sand, // Utiliza chave de localização
          ).copyWith(
            enabled: false,
          ),
          readOnly: true,
        ),
        SizedBox(height: 16),

        // Campos para Areia Grossa e Areia Fina com Formatação semelhante a Silte e Argila
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _areiaGrossaController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).coarse_sand, // Utiliza chave de localização
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                    // Recalcular a textura se necessário
                    _computeAreiaTotal();
                    _computeTexturaSolo();
                  });
                },
                validator: _validateNumber, // Atualizar validador
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _areiaFinaController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).fine_sand, // Utiliza chave de localização
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    _hasChanges = true;
                    // Recalcular a textura se necessário
                    _computeAreiaTotal();
                    _computeTexturaSolo();
                  });
                },
                validator: _validateNumber, // Atualizar validador
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Textura do Solo (Read-Only)
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge,
                  children: [
                    TextSpan(
                      text: '${S.of(context).soil_texture_label}: ', // Utiliza chave de localização
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: _computedTexturaSolo?.getLocalizedName(context) ?? S.of(context).not_determined, // Utiliza chave de localização
                    ),
                  ],
                ),
              ),
            ),
            if (_computedTexturaSolo == null)
              Tooltip(
                message: S.of(context).soil_texture_not_determined_tooltip, // Utiliza chave de localização
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {String? tooltip}) {
    Widget row = Row(
      children: [
        Expanded(
          flex: 2, // Ajuste o flex conforme necessário
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 3, // Ajuste o flex conforme necessário
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: row,
      );
    }

    return row;
  }

  @override
  void dispose() {
    _laboratorioController.dispose();
    _metodologiaController.dispose();
    _responsavelController.dispose();
    _dataColetaController.dispose();
    _dataAnaliseController.dispose();
    _talhaoController.dispose();

    _phController.dispose();
    _alController.dispose();
    _hAlController.dispose();
    _pResinaController.dispose();
    _potassioController.dispose();
    _calcioController.dispose();
    _magnesioController.dispose();
    _enxofreController.dispose();
    _boroController.dispose();
    _cobreController.dispose();
    _ferroController.dispose();
    _manganesController.dispose();
    _zincoController.dispose();
    _moController.dispose();
    _coController.dispose();
    _silteController.dispose();
    _argilaController.dispose();
    _sodioController.dispose();
    _areiaTotalController.dispose();
    _areiaGrossaController.dispose();
    _areiaFinaController.dispose();
    super.dispose();
  }
}
