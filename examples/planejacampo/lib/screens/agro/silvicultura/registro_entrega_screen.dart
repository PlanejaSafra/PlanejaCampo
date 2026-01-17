import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/models/registro_entrega.dart';
import 'package:planejacampo/screens/agro/silvicultura/registro_entrega_form_screen.dart';
import 'package:planejacampo/services/registro_entrega_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/object_template.dart';

class RegistroEntregaScreen extends StatefulWidget {
  final RegistroEntrega registroEntrega;

  const RegistroEntregaScreen({
    Key? key,
    required this.registroEntrega,
  }) : super(key: key);

  @override
  _RegistroEntregaScreenState createState() => _RegistroEntregaScreenState();
}

class _RegistroEntregaScreenState extends State<RegistroEntregaScreen> {
  final String _moduleName = 'registrosEntregas';
  final RegistroEntregaService _registroEntregaService = RegistroEntregaService();
  final PessoaService _pessoaService = PessoaService();
  late Future<RegistroEntrega?> _futureRegistroEntrega;
  late RegistroEntrega _currentRegistroEntrega;
  Object _returnObject = '';
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentRegistroEntrega = widget.registroEntrega;
    _loadRegistroEntrega();
    _checkPermissions();

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('registroEntregaScreen');
    appStateManager.setShowTutorial('registroEntregaScreen', false);
  }

  void _loadRegistroEntrega() {
    setState(() {
      _futureRegistroEntrega = _registroEntregaService.getById(_currentRegistroEntrega.id);
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
            RegistroEntregaFormScreen(registroEntrega: _currentRegistroEntrega),
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
    ).then((updatedRegistroEntrega) {
      if (updatedRegistroEntrega != null) {
        _returnObject = true;
        if (updatedRegistroEntrega is RegistroEntrega) {
          setState(() {
            _currentRegistroEntrega = updatedRegistroEntrega;
          });
        }
        _loadRegistroEntrega();
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
      title: S.of(context).delivery_record_details,
      moduleName: _moduleName,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).delivery_record,
      nomeTutorialPlural: S.of(context).delivery_records,
      returnObject: _returnObject,
      onWillPop: () async {
        Navigator.of(context).pop(_returnObject);
        return false;
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      onEditPressed: _canEdit ? _navigateToFormScreen : null,
      summarySection: _buildSummarySection(),
      serviceName: _registroEntregaService,
      itemIdValue: widget.registroEntrega.id,
      itemName: S.of(context).delivery_record,
      fieldReference: 'registroEntregaId',
      cardSections: [],
      isExpanded: _isExpanded,
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      customTutorialSteps: _buildCustomTutorialSteps(),
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'delivery_date': {
        'key': GlobalKey(),
        'message': S.of(context).delivery_date_explanation,
        'shape': 'RRect'
      },
      'quantity_boxes': {
        'key': GlobalKey(),
        'message': S.of(context).quantity_boxes_explanation,
        'shape': 'RRect'
      },
      'total_weight': {
        'key': GlobalKey(),
        'message': S.of(context).total_weight_delivery_explanation,
        'shape': 'RRect'
      },
      'producer_weight': {
        'key': GlobalKey(),
        'message': S.of(context).producer_weight_explanation,
        'shape': 'RRect'
      },
      'negotiated_value': {
        'key': GlobalKey(),
        'message': S.of(context).negotiated_value_explanation,
        'shape': 'RRect'
      }
    };
  }

  Widget _buildSummarySection() {
    return FutureBuilder<RegistroEntrega?>(
      future: _futureRegistroEntrega,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final registroEntrega = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.calendar_today,
                    label: S.of(context).delivery_date,
                    value: DateFormat.yMMMd().format(registroEntrega.dataEntrega),
                  ),
                  const SizedBox(height: 8),
                  if (registroEntrega.sangradorId != null)
                    FutureBuilder(
                      future: _pessoaService.getById(registroEntrega.sangradorId!),
                      builder: (context, pessoaSnapshot) {
                        return ObjectTemplate.buildInfoRow(
                          context: context,
                          icon: Icons.person,
                          label: S.of(context).bleeder,
                          value: pessoaSnapshot.data?.nome ?? S.of(context).not_found,
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  if (registroEntrega.pesoSangrador != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.scale,
                      label: S.of(context).bleeder_weight,
                      value: registroEntrega.pesoSangrador!,
                    ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.inventory_2,
                    label: S.of(context).quantity_boxes,
                    value: FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registroEntrega.quantidadeCaixas),
                  ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.scale,
                    label: S.of(context).total_weight_delivery,
                    value: '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registroEntrega.pesoTotalEntrega)} kg',
                  ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.person,
                    label: S.of(context).producer_weight,
                    value: '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registroEntrega.pesoProdutor)} kg',
                  ),
                  if (registroEntrega.compradorId != null)
                    FutureBuilder(
                      future: _pessoaService.getById(registroEntrega.compradorId!),
                      builder: (context, pessoaSnapshot) {
                        return ObjectTemplate.buildInfoRow(
                          context: context,
                          icon: Icons.business,
                          label: S.of(context).buyer,
                          value: pessoaSnapshot.data?.nome ?? S.of(context).not_found,
                        );
                      },
                    ),
                  if (registroEntrega.dataPrevistaRecebimento != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.event,
                      label: S.of(context).expected_receipt_date,
                      value: DateFormat.yMMMd().format(registroEntrega.dataPrevistaRecebimento!),
                    ),
                  if (registroEntrega.valorNegociadoPorKg != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.monetization_on,
                      label: S.of(context).negotiated_value_per_kg,
                      value: '${S.of(context).currency_symbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registroEntrega.valorNegociadoPorKg!)}',
                    ),
                  if (registroEntrega.valorProdutor != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.account_balance_wallet,
                      label: S.of(context).producer_value,
                      value: '${S.of(context).currency_symbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registroEntrega.valorProdutor!)}',
                    ),
                  if (registroEntrega.quantidadeJaRecebida != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.check_circle,
                      label: S.of(context).quantity_already_received,
                      value: FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registroEntrega.quantidadeJaRecebida!),
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