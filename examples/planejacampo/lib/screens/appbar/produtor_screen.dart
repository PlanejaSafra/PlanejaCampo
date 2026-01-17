import 'package:flutter/material.dart';
import 'package:planejacampo/icons/custom_icons.dart';
import 'package:planejacampo/models/produtor.dart';
import 'package:planejacampo/services/produtor_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/screens/appbar/produtor_form_screen.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/utils/produtor_options.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/widgets/dialog_screen.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class ProdutorScreen extends StatefulWidget {
  final Produtor produtor;
  const ProdutorScreen({Key? key, required this.produtor}) : super(key: key);

  @override
  _ProdutorScreenState createState() => _ProdutorScreenState();
}

class _ProdutorScreenState extends State<ProdutorScreen> {
  final ProdutorService _produtorService = ProdutorService();
  final PropriedadeService _propriedadeService = PropriedadeService();
  late Future<Produtor?> _futureProdutor;
  late Future<List<Propriedade>> _futurePropriedades;
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  late Produtor _currentProdutor;

  // Chaves para as seções de permissões e propriedades
  final GlobalKey _customPermissionsKey = GlobalKey();
  final GlobalKey _customPropriedadesKey = GlobalKey();
  Object _returnObject = '';

  @override
  void initState() {
    super.initState();
    _currentProdutor = widget.produtor;
    _loadProdutor();
    _checkPermissions();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('produtorScreen');
    appStateManager.setShowTutorial('produtorScreen', false);
  }

  void _loadProdutor() {
    setState(() {
      _futureProdutor = _produtorService.getById(widget.produtor.id);
      _futurePropriedades = _propriedadeService.getByProdutorId(widget.produtor.id);
    });
  }

  void _checkPermissions() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEditProdutor(widget.produtor);
      _canDelete = appStateManager.canDeleteProdutor(widget.produtor);
      /*
      // Comentado para permitir a exclusão de produtores, e a limpeza de dados. Foi incluída nova mensagem para confirmar a exlcusão de produtores.
      if (_canDelete) {
        if (widget.produtor.id == appStateManager.activeProdutorId) {
          _canDelete = false;
        }
      }
      */
    });
  }

  void _navigateToFormScreen() {
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProdutorFormScreen(produtor: _currentProdutor),
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
        .then((updatedProdutor) {
      if (updatedProdutor != null) {
        setState(() {
          _returnObject = true;
          _currentProdutor = updatedProdutor;
          _loadProdutor();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).producer_details,
      moduleName: 'produtores',
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).rural_producer,
      nomeTutorialPlural: S.of(context).rural_producers,
      returnObject: _returnObject,
      onWillPop: () async {
        return true; // Permite a navegação
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      onEditPressed: _canEdit ? () => _navigateToFormScreen() : null,
      summarySection: _buildSummarySection(),
      serviceName: _produtorService,
      itemIdValue: widget.produtor.id,
      itemName: S.of(context).rural_producer,
      fieldReference: 'produtorId',
      cardSections: [
        CardSection(
          title: S.of(context).people_with_access,
          icon: Icons.lock, // Ícone representativo
          key: _customPermissionsKey,
          cards: _buildPermissoesCards(),
        ),
        CardSection(
          title: S.of(context).agricultural_properties,
          icon: CustomIcons.field_2, // Ícone representativo
          key: _customPropriedadesKey,
          cards: _buildPropriedadesCards(),
        ),
      ],
      // Atualize o customTutorialSteps na construção do SingleScreenTemplate
      customTutorialSteps: {
        'customPermissions': {
          'key': _customPermissionsKey,
          'message': S.of(context).view_user_permissions,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
        'customProperties': {
          'key': _customPropriedadesKey,
          'message': S.of(context).producer_properties_listed,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
      },
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder<Produtor?>(
      future: _futureProdutor,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final produtor = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Utilizando InfoRow para cada campo
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.person,
                    label: S.of(context).name,
                    value: produtor.nome,
                  ),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.category,
                    label: S.of(context).producer_type,
                    value: ProdutorOptions.getLocalizedTipo(context)[produtor.tipo] ?? produtor.tipo,
                  ),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: produtor.tipo == 'Pessoa Física' ? Icons.credit_card : Icons.business,
                    label: produtor.tipo == 'Pessoa Física' ? S.of(context).cpf : S.of(context).cnpj,
                    value: produtor.documento,
                  ),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.info,
                    label: S.of(context).status,
                    value: ProdutorOptions.getLocalizedStatus(context)[produtor.status] ?? produtor.status,
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  List<Widget> _buildPermissoesCards() {
    return [
      FutureBuilder<Produtor?>(
        future: _futureProdutor,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(S.of(context).loading),
            );
          } else if (snapshot.hasError) {
            return ListTile(
              leading: Icon(Icons.error, color: Theme.of(context).colorScheme.error),
              title: Text(S.of(context).error_loading),
            );
          } else if (!snapshot.hasData) {
            return ListTile(
              leading: Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
              title: Text(S.of(context).not_found),
            );
          } else {
            final produtor = snapshot.data!;
            if (produtor.permissoes.isEmpty) {
              return ListTile(
                leading: Icon(Icons.people_outline, color: Theme.of(context).colorScheme.primary),
                title: Text(S.of(context).not_found),
              );
            }
            return Column(
              children: produtor.permissoes.map((permissao) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      permissao['email'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    subtitle: Text(
                      ProdutorOptions.getLocalizedPermissoes(context)[permissao['role']] ?? permissao['role'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
    ];
  }

  List<Widget> _buildPropriedadesCards() {
    return [
      FutureBuilder<List<Propriedade>>(
        future: _futurePropriedades,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(S.of(context).loading),
            );
          } else if (snapshot.hasError) {
            return ListTile(
              leading: Icon(Icons.error, color: Theme.of(context).colorScheme.error),
              title: Text(S.of(context).error_loading),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ListTile(
              leading: Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
              title: Text(S.of(context).not_found),
            );
          } else {
            return Column(
              children: snapshot.data!.map((propriedade) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: Icon(CustomIcons.field, color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      '${S.of(context).agricultural_property}: ${propriedade.nome}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    subtitle: Text(
                      '${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(propriedade.area)} ${S.of(context).hectares}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
    ];
  }
}
