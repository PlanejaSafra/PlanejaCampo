import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/models/registro_coleta.dart';
import 'package:planejacampo/screens/agro/silvicultura/registro_coleta_form_screen.dart';
import 'package:planejacampo/services/registro_coleta_service.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class RegistroColetaScreen extends StatefulWidget {
  final RegistroColeta registroColeta;

  const RegistroColetaScreen({
    Key? key,
    required this.registroColeta,
  }) : super(key: key);

  @override
  _RegistroColetaScreenState createState() => _RegistroColetaScreenState();
}

class _RegistroColetaScreenState extends State<RegistroColetaScreen> {
  final String _moduleName = 'registrosColetas';
  final RegistroColetaService _registroColetaService = RegistroColetaService();
  late Future<RegistroColeta?> _futureRegistroColeta;
  late RegistroColeta _currentRegistroColeta;
  Object _returnObject = '';
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentRegistroColeta = widget.registroColeta;
    _loadRegistroColeta();
    _checkPermissions();

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('registroColetaScreen');
    appStateManager.setShowTutorial('registroColetaScreen', false);
  }

  void _loadRegistroColeta() {
    setState(() {
      _futureRegistroColeta = _registroColetaService.getById(_currentRegistroColeta.id);
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
            RegistroColetaFormScreen(registroColeta: _currentRegistroColeta),
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
    ).then((updatedRegistroColeta) {
      if (updatedRegistroColeta != null) {
        _returnObject = true;
        if (updatedRegistroColeta is RegistroColeta) {
          setState(() {
            _currentRegistroColeta = updatedRegistroColeta;
          });
        }
        _loadRegistroColeta();
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
      title: S.of(context).collection_record_details,
      moduleName: _moduleName,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).collection_record,
      nomeTutorialPlural: S.of(context).collection_records,
      returnObject: _returnObject,
      onWillPop: () async {
        Navigator.of(context).pop(_returnObject);
        return false;
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      onEditPressed: _canEdit ? _navigateToFormScreen : null,
      summarySection: _buildSummarySection(),
      serviceName: _registroColetaService,
      itemIdValue: widget.registroColeta.id,
      itemName: S.of(context).collection_record,
      fieldReference: 'registroColetaId',
      cardSections: [],
      isExpanded: _isExpanded,
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      customTutorialSteps: _buildCustomTutorialSteps(),
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'collection_date': {
        'key': GlobalKey(),
        'message': S.of(context).collection_date_explanation,
        'shape': 'RRect'
      },
      'quantity_boxes': {
        'key': GlobalKey(),
        'message': S.of(context).quantity_boxes_explanation,
        'shape': 'RRect'
      },
      'average_weight': {
        'key': GlobalKey(),
        'message': S.of(context).average_weight_box_explanation,
        'shape': 'RRect'
      },
      'total_weight': {
        'key': GlobalKey(),
        'message': S.of(context).total_weight_explanation,
        'shape': 'RRect'
      }
    };
  }

  Widget _buildSummarySection() {
    return FutureBuilder<RegistroColeta?>(
      future: _futureRegistroColeta,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final registroColeta = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.calendar_today,
                    label: S.of(context).collection_date,
                    value: DateFormat.yMMMd().format(registroColeta.dataColeta),
                  ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.inventory_2,
                    label: S.of(context).quantity_boxes,
                    value: FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registroColeta.quantidadeCaixa ?? 0),
                  ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.scale,
                    label: S.of(context).average_weight_box,
                    value: '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registroColeta.pesoMedioCaixa ?? 0.0)} kg',
                  ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.shopping_basket,
                    label: S.of(context).total_weight,
                    value: '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registroColeta.pesoTotal ?? 0.0)} kg',
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