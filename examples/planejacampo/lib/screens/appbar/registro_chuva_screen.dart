import 'package:flutter/material.dart';
import 'package:planejacampo/models/registro_chuva.dart';
import 'package:planejacampo/services/registro_chuva_service.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/screens/appbar/registro_chuva_form_screen.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/card_section.dart';

class RegistroChuvaScreen extends StatefulWidget {
  final RegistroChuva registroChuva;

  const RegistroChuvaScreen({
    Key? key,
    required this.registroChuva,
  }) : super(key: key);

  @override
  _RegistroChuvaScreenState createState() => _RegistroChuvaScreenState();
}

class _RegistroChuvaScreenState extends State<RegistroChuvaScreen> {
  final String _moduleName = 'registrosChuvas';
  final RegistroChuvaService _registroChuvaService = RegistroChuvaService();
  final PropriedadeService _propriedadeService = PropriedadeService();

  late Future<RegistroChuva?> _futureRegistroChuva;
  late Future<Propriedade?> _futurePropriedade;
  Object _returnObject = '';

  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  late RegistroChuva _currentRegistroChuva;

  @override
  void initState() {
    super.initState();
    _currentRegistroChuva = widget.registroChuva;
    _loadRegistroChuva();
    _checkPermissions();
    final AppStateManager appStateManager =
    Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('registroChuvaScreen');
    appStateManager.setShowTutorial('registroChuvaScreen', false);
  }

  void _loadRegistroChuva() {
    setState(() {
      _futureRegistroChuva =
          _registroChuvaService.getById(widget.registroChuva.id);
      _futurePropriedade =
          _propriedadeService.getById(_currentRegistroChuva.propriedadeId);
    });
  }

  void _checkPermissions() {
    final appStateManager =
    Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEdit(_moduleName);
      _canDelete = appStateManager.canDelete(_moduleName);
    });
  }

  void _navigateToFormScreen() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => RegistroChuvaFormScreen(
          registroChuva: _currentRegistroChuva,
        ),
      ),
    )
        .then((result) {
      if (result != null && result != '') {
        _currentRegistroChuva = result;
        if (result is RegistroChuva) {
          setState(() {
            _returnObject = true;
          });
        }
        _loadRegistroChuva();
      }
    });
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).confirm_deletion),
        content: Text(S
            .of(context)
            .confirm_deletion_message(S.of(context).rain_record)),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(S.of(context).delete),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await _registroChuvaService.delete(_currentRegistroChuva.id);
        Navigator.of(context).pop(true); // Retorna true para indicar que houve exclusão
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error_deleting)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).rain_record_details,
      moduleName: _moduleName,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).rain_record,
      nomeTutorialPlural: S.of(context).rain_records,
      returnObject: _returnObject,
      onWillPop: () async {
        return true; // Permite a navegação
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      onEditPressed: _canEdit ? () => _navigateToFormScreen() : null,
      onDeletePressed: _canDelete ? _confirmDelete : null,
      summarySection: _buildSummarySection(),
      serviceName: _registroChuvaService,
      itemIdValue: widget.registroChuva.id,
      itemName: S.of(context).rain_record,
      fieldReference: 'registroChuvaId',
      cardSections: [], // Adicione seções adicionais aqui, se necessário
      customTutorialSteps: {
        // Adicione passos do tutorial personalizados se necessário
      },
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder<RegistroChuva?>(
      future: _futureRegistroChuva,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final registroChuva = snapshot.data!;
          return FutureBuilder<Propriedade?>(
            future: _futurePropriedade,
            builder: (context, propriedadeSnapshot) {
              final propriedadeName = propriedadeSnapshot.data?.nome ?? S.of(context).unknown_property;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Seção de Cabeçalho
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ícone Representativo
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.opacity, // Ícone para Registro de Chuva
                              size: 50,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Informações Básicas
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context).rain_record,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      FormatacaoUtil.formatDate(registroChuva.data),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Informações Detalhadas
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.home,
                        label: S.of(context).agricultural_property,
                        value: propriedadeName,
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.calendar_today,
                        label: S.of(context).date,
                        value: FormatacaoUtil.formatDate(registroChuva.data),
                      ),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.opacity,
                        label: S.of(context).rain_quantity,
                        value: '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registroChuva.quantidade)} mm',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
