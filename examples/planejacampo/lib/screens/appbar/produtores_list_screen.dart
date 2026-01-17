import 'package:flutter/material.dart';
import 'package:planejacampo/models/produtor.dart';
import 'package:planejacampo/screens/appbar/produtor_form_screen.dart';
import 'package:planejacampo/screens/appbar/produtor_screen.dart';
import 'package:planejacampo/services/produtor_service.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/produtor_options.dart';

class ProdutoresListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const ProdutoresListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _ProdutoresListScreenState createState() => _ProdutoresListScreenState();
}

class _ProdutoresListScreenState extends State<ProdutoresListScreen> {
  final String _moduleName = 'produtores';
  final ProdutorService _produtorService = ProdutorService();
  late Future<List<Produtor>> _produtoresFuture;
  Object _returnObject = false;
  bool _showTutorial = false;
  bool _isSnackBarVisible = false;

  @override
  void initState() {
    super.initState();
    _produtoresFuture = _loadProdutores();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    appStateManager.checkCanCreateMoreProdutores();
    _showTutorial = appStateManager.showTutorial('produtoresListScreen');
    appStateManager.setShowTutorial('produtoresListScreen', false);
  }

  Future<List<Produtor>> _loadProdutores() async {
    try {
      return await _produtorService.getProdutores();
    } catch (e) {
      throw e;
    }
  }

  void _refreshProdutores() {
    _returnObject = true;
    setState(() {
      _produtoresFuture = _loadProdutores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appStateManager = Provider.of<AppStateManager>(context);
    final bool forceSelectMode = !appStateManager.hasActiveProdutor;

    return ListTemplate<Produtor>(
      icon: Icons.person,
      future: _produtorService.getProdutores(),
      serviceName: _produtorService,
      itemTitleBuilder: (produtor) => produtor.nome,
      itemSubtitleBuilder: (produtor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ProdutorOptions.getLocalizedTipo(context)[produtor.tipo] ?? produtor.tipo}',
          ),
          Text(
            '${produtor.tipo == 'Pessoa Física' ? S.of(context).cpf : S.of(context).cnpj}: ${produtor.documento}',
          ),
          Text(
            '${S.of(context).status}: ${ProdutorOptions.getLocalizedStatus(context)[produtor.status] ?? produtor.status}',
          ),
        ],
      ),
      moduleName: _moduleName,
      title: forceSelectMode || widget.isSelectMode ? S.of(context).select_producer : S.of(context).rural_producers,
      canEdit: (produtor) => appStateManager.canEditProdutor(produtor),
      canDelete: (produtor) => appStateManager.canDeleteProdutor(produtor),
      errorText: S.of(context).error_loading_producers,
      formScreenBuilder: (produtor) => ProdutorFormScreen(produtor: produtor),
      isSelectMode: forceSelectMode || widget.isSelectMode,
      isSetMode: widget.isSetMode,
      itemExpandedContentWidgets: (produtor) {
        final List<Widget> widgets = [];

        if (produtor.permissoes.isNotEmpty) {
          widgets.add(const SizedBox(height: 16));
          widgets.add(
            ObjectTemplate.buildCardSection(
              CardSection(
                title: S.of(context).people_with_access,
                icon: Icons.group,
                cards: produtor.permissoes.map((permissao) => ListTile(
                  title: Text(
                    permissao['email'] ?? '',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    ProdutorOptions.getLocalizedPermissoes(context)[permissao['role']] ??
                        permissao['role'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )).toList(),
              ),
              Theme.of(context),
            ),
          );
        }

        return widgets;
      },
      itemLeadingIcon: Icons.person,
      loadingText: S.of(context).loading_producers,
      nomeTutorial: S.of(context).rural_producer,
      nomeTutorialPlural: S.of(context).rural_producers,
      notFoundText: S.of(context).no_producers_found,
      onRefresh: _refreshProdutores,
      onSetMode: (produtor) => appStateManager.setActiveProdutor(produtor),
      showTutorial: _showTutorial,
      viewScreenBuilder: (produtor) => ProdutorScreen(produtor: produtor!),
      onWillPop: () async {
        if (appStateManager.activeProdutorId == null) {
          if (!_isSnackBarVisible) {
            _isSnackBarVisible = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).select_or_register_farmer),
                duration: Duration(seconds: 2),
              ),
            ).closed.then((reason) {
              _isSnackBarVisible = false;
            });
          }
          _returnObject = false;
          return false;
        }
        _returnObject = false;
        return true;
      },
    );
  }
}