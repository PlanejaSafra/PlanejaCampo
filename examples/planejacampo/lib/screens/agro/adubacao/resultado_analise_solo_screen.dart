import 'package:flutter/material.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/services/agro/adubacao/resultado_analise_solo_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/services/pessoa_service.dart'; // Adicionei para carregar Pessoa
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/screens/agro/adubacao/resultado_analise_solo_form_screen.dart';

class ResultadoAnaliseSoloScreen extends StatefulWidget {
  final ResultadoAnaliseSolo resultadoAnaliseSolo;

  const ResultadoAnaliseSoloScreen({
    Key? key,
    required this.resultadoAnaliseSolo,
  }) : super(key: key);

  @override
  _ResultadoAnaliseSoloScreenState createState() => _ResultadoAnaliseSoloScreenState();
}

class _ResultadoAnaliseSoloScreenState extends State<ResultadoAnaliseSoloScreen> {
  final String _moduleName = 'recomendacoesAdubacao';
  final ResultadoAnaliseSoloService _analiseSoloService = ResultadoAnaliseSoloService();
  final TalhaoService _talhaoService = TalhaoService();
  final PessoaService _pessoaService = PessoaService(); // Serviço para Pessoa
  late Future<ResultadoAnaliseSolo?> _futureAnaliseSolo;

  // GlobalKeys para tutorial
  final GlobalKey _basicInfoKey = GlobalKey();
  final GlobalKey _phAcidezKey = GlobalKey();
  final GlobalKey _macronutrientesKey = GlobalKey();
  final GlobalKey _micronutrientesKey = GlobalKey();
  final GlobalKey _materiaOrganicaKey = GlobalKey();
  final GlobalKey _analiseGranulometricaKey = GlobalKey();

  late bool _canEdit;
  late bool _canDelete;
  late ResultadoAnaliseSolo _currentAnaliseSolo;
  Object _returnObject = '';
  bool _showTutorial = false;

  // Variáveis para armazenar nomes
  String? _laboratorioNome;
  String? _responsavelColetaNome;

  @override
  void initState() {
    super.initState();
    _currentAnaliseSolo = widget.resultadoAnaliseSolo;
    _loadAnaliseSolo();
    _checkPermissions();

    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('resultadoAnaliseSoloScreen');
    appStateManager.setShowTutorial('resultadoAnaliseSoloScreen', false);
  }

  void _loadAnaliseSolo() async {
    setState(() {
      _futureAnaliseSolo = _analiseSoloService.getById(_currentAnaliseSolo.id);
    });

    // Carregar nome do laboratório
    if (_currentAnaliseSolo.laboratorioId.isNotEmpty) {
      final laboratorio = await _pessoaService.getById(_currentAnaliseSolo.laboratorioId);
      if (laboratorio != null && mounted) {
        setState(() {
          _laboratorioNome = laboratorio.nome;
        });
      }
    }

    // Carregar nome do responsável pela coleta
    if (_currentAnaliseSolo.responsavelColetaId.isNotEmpty) {
      final responsavel = await _pessoaService.getById(_currentAnaliseSolo.responsavelColetaId);
      if (responsavel != null && mounted) {
        setState(() {
          _responsavelColetaNome = responsavel.nome;
        });
      }
    }
  }

  void _checkPermissions() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEdit(_moduleName);
      _canDelete = appStateManager.canDelete(_moduleName);
    });
  }

  void _navigateToFormScreen() {
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ResultadoAnaliseSoloFormScreen(resultadoAnaliseSolo: _currentAnaliseSolo),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    )
        .then((updatedAnaliseSolo) {
      if (updatedAnaliseSolo != null) {
        _returnObject = true;
        if (updatedAnaliseSolo is ResultadoAnaliseSolo) {
          setState(() {
            _currentAnaliseSolo = updatedAnaliseSolo;
          });
          _loadAnaliseSolo();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).soil_analysis_details,
      moduleName: _moduleName,
      returnObject: _returnObject,
      onWillPop: () async {
        return true;
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).soil_analysis,
      onEditPressed: _canEdit ? _navigateToFormScreen : null,
      summarySection: _buildSummarySection(),
      serviceName: _analiseSoloService,
      itemIdValue: widget.resultadoAnaliseSolo.id,
      itemName: S.of(context).soil_analysis,
      fieldReference: 'resultadoAnaliseSoloId',
      cardSections: [], // Lista vazia pois todas as informações estão no summarySection
      customTutorialSteps: _buildCustomTutorialSteps(),
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'informacoesBasicas': {
        'key': _basicInfoKey,
        'message': S.of(context).basic_information,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'phAcidez': {
        'key': _phAcidezKey,
        'message': S.of(context).ph_and_acidity_complex,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'macronutrientes': {
        'key': _macronutrientesKey,
        'message': S.of(context).macronutrients,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'micronutrientes': {
        'key': _micronutrientesKey,
        'message': S.of(context).micronutrients,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'materiaOrganica': {
        'key': _materiaOrganicaKey,
        'message': S.of(context).organic_matter,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'analiseGranulometrica': {
        'key': _analiseGranulometricaKey,
        'message': S.of(context).granulometric_analysis,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
    };
  }

  Widget _buildSummarySection() {
    return FutureBuilder<ResultadoAnaliseSolo?>(
      future: _futureAnaliseSolo,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final analiseSolo = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações Básicas
                  _buildInfoSection(
                    key: _basicInfoKey,
                    title: S.of(context).basic_information,
                    icon: Icons.assignment,
                    children: [
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.science,
                        label: S.of(context).laboratory,
                        value: _laboratorioNome ?? analiseSolo.laboratorioId, // Exibir nome ou ID
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.memory,
                        label: S.of(context).extraction_methodology,
                        value: analiseSolo.metodologiaExtracao,
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.person,
                        label: S.of(context).collection_responsible,
                        value: _responsavelColetaNome ?? analiseSolo.responsavelColetaId, // Exibir nome ou ID
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.calendar_today,
                        label: S.of(context).collection_date,
                        value: FormatacaoUtil.formatDate(analiseSolo.dataColeta),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.calendar_today,
                        label: S.of(context).analysis_date,
                        value: FormatacaoUtil.formatDate(analiseSolo.dataAnalise),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.height,
                        label: S.of(context).sample_depth,
                        value: analiseSolo.profundidadeAmostra.getLocalizedName(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // pH e Acidez
                  _buildInfoSection(
                    key: _phAcidezKey,
                    title: S.of(context).ph_and_acidity_complex,
                    icon: Icons.science,
                    children: [
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).ph_cacl2}",
                        value: analiseSolo.pH.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).exchangeable_aluminum} (cmolc/dm³)",
                        value: analiseSolo.al.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).potential_acidity} (cmolc/dm³)",
                        value: analiseSolo.hAl.toStringAsFixed(2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Macronutrientes
                  _buildInfoSection(
                    key: _macronutrientesKey,
                    title: S.of(context).macronutrients,
                    icon: Icons.grass,
                    children: [
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).phosphorus_resin} (mg/dm³)",
                        value: analiseSolo.fosforo.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).potassium} (mmolc/dm³)",
                        value: analiseSolo.potassio.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).calcium} (mmolc/dm³)",
                        value: analiseSolo.calcio.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).magnesium} (mmolc/dm³)",
                        value: analiseSolo.magnesio.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).sulfur} (mg/dm³)",
                        value: analiseSolo.enxofre.toStringAsFixed(2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Micronutrientes
                  _buildInfoSection(
                    key: _micronutrientesKey,
                    title: S.of(context).micronutrients,
                    icon: Icons.biotech,
                    children: [
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).boron} (mg/dm³)",
                        value: analiseSolo.boro.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).copper} (mg/dm³)",
                        value: analiseSolo.cobre.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).iron} (mg/dm³)",
                        value: analiseSolo.ferro.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).manganese} (mg/dm³)",
                        value: analiseSolo.manganes.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).zinc} (mg/dm³)",
                        value: analiseSolo.zinco.toStringAsFixed(2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Matéria Orgânica
                  _buildInfoSection(
                    key: _materiaOrganicaKey,
                    title: S.of(context).organic_matter,
                    icon: Icons.eco,
                    children: [
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).organic_matter} (g/kg)",
                        value: analiseSolo.mo.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).organic_carbon} (g/kg)",
                        value: analiseSolo.co.toStringAsFixed(2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Análise Granulométrica
                  _buildInfoSection(
                    key: _analiseGranulometricaKey,
                    title: S.of(context).granulometric_analysis,
                    icon: Icons.grain,
                    children: [
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).total_sand} (g/kg)", // Atualizado
                        value: analiseSolo.areiaTotal.toStringAsFixed(2), // Atualizado
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).silt} (g/kg)",
                        value: analiseSolo.silte.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).clay} (g/kg)",
                        value: analiseSolo.argila.toStringAsFixed(2),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.analytics,
                        label: "${S.of(context).sodium} (mmolc/dm³)",
                        value: analiseSolo.sodio.toStringAsFixed(2),
                      ),
                      if (analiseSolo.texturaSolo != null)
                        ObjectTemplate.buildInfoRow(
                          context: context,
                          icon: Icons.analytics,
                          label: S.of(context).soil_texture,
                          value: analiseSolo.texturaSolo!.getLocalizedName(context),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Key? key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
