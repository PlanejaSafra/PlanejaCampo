import 'package:flutter/material.dart';
import 'package:planejacampo/models/tipo_operacao_rural.dart';
import 'package:planejacampo/services/tipo_operacao_rural_service.dart';
import 'package:planejacampo/screens/agro/tipo_operacao_rural_form_screen.dart';
import 'package:planejacampo/utils/estados_options.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/dialog_screen.dart';

class TipoOperacaoRuralScreen extends StatefulWidget {
  final TipoOperacaoRural tipoOperacaoRural;

  const TipoOperacaoRuralScreen({
    Key? key,
    required this.tipoOperacaoRural,
  }) : super(key: key);

  @override
  _TipoOperacaoRuralScreenState createState() => _TipoOperacaoRuralScreenState();
}

class _TipoOperacaoRuralScreenState extends State<TipoOperacaoRuralScreen> {
  final String _moduleName = 'tiposOperacoesRurais';
  final TipoOperacaoRuralService _tipoOperacaoRuralService = TipoOperacaoRuralService();
  late Future<TipoOperacaoRural?> _futureTipoOperacao;
  late TipoOperacaoRural _currentTipoOperacaoRural;
  Object _returnObject = '';
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentTipoOperacaoRural = widget.tipoOperacaoRural;
    _loadTipoOperacaoRural();
    _checkPermissions();

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('tipoOperacaoRuralScreen');
    appStateManager.setShowTutorial('tipoOperacaoRuralScreen', false);
  }

  void _loadTipoOperacaoRural() {
    setState(() {
      _futureTipoOperacao = _tipoOperacaoRuralService.getById(_currentTipoOperacaoRural.id);
    });
  }

  void _checkPermissions() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEdit(_moduleName);
      _canDelete = appStateManager.canDelete(_moduleName);
    });
  }

  void _navigateToFormScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TipoOperacaoRuralFormScreen(tipoOperacaoRural: _currentTipoOperacaoRural),
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
    ).then((updatedTipoOperacaoRural) {
      if (updatedTipoOperacaoRural != null) {
        _returnObject = true;
        if (updatedTipoOperacaoRural is TipoOperacaoRural) {
          setState(() {
            _currentTipoOperacaoRural = updatedTipoOperacaoRural;
          });
        }
        _loadTipoOperacaoRural();
      }
    });
  }

  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    return _isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).tipo_operacao_rural_details,
      moduleName: _moduleName,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).tipo_operacao_rural,
      nomeTutorialPlural: S.of(context).tipos_operacoes_rurais,
      returnObject: _returnObject,
      onWillPop: () async {
        return true;
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      onEditPressed: _canEdit ? _navigateToFormScreen : null,
      summarySection: _buildSummarySection(),
      serviceName: _tipoOperacaoRuralService,
      itemIdValue: widget.tipoOperacaoRural.id,
      itemName: S.of(context).tipo_operacao_rural,
      fieldReference: 'tipoOperacaoRuralId',
      cardSections: [],
      isExpanded: _isExpanded,
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      customTutorialSteps: _buildCustomTutorialSteps(),
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'tipo_operacao': {
        'key': GlobalKey(),
        'message': S.of(context).edit_tipo_operacao_info,
        'shape': 'RRect'
      }
    };
  }

  Widget _buildSummarySection() {
    return FutureBuilder<TipoOperacaoRural?>(
      future: _futureTipoOperacao,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final tipoOperacaoRural = snapshot.data!;

          // Encontra o país na lista usando a sigla
          final pais = EstadosOptions.paises.firstWhere(
                (pais) => pais['sigla'] == tipoOperacaoRural.siglaPais,
            orElse: () => {'nome': tipoOperacaoRural.siglaPais, 'sigla': tipoOperacaoRural.siglaPais},
          );

          // Obtém o nome traduzido do país
          final nomePaisLocalizado = EstadosOptions.getLocalizedPaises(context)[pais['nome']] ?? pais['nome'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.label,
                    label: S.of(context).name,
                    value: tipoOperacaoRural.nome,
                  ),
                  if (nomePaisLocalizado != null)
                    const SizedBox(height: 8),
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.language,
                      label: S.of(context).country,
                      value: nomePaisLocalizado!,
                    ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.description,
                    label: S.of(context).description,
                    value: tipoOperacaoRural.descricao,
                    valueBelowLabel: true,
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}