import 'package:flutter/material.dart';
import 'package:planejacampo/models/pessoa.dart';
import 'package:planejacampo/screens/appbar/pessoa_form_screen.dart';
import 'package:planejacampo/screens/appbar/pessoa_screen.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/pessoa_options.dart';
import 'package:planejacampo/l10n/l10n.dart';

class PessoasListScreen extends StatefulWidget {
  final List<String>? vinculos;
  final bool isSelectMode;
  final bool isSetMode;

  const PessoasListScreen({
    Key? key,
    this.vinculos,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _PessoasListScreenState createState() => _PessoasListScreenState();
}

class _PessoasListScreenState extends State<PessoasListScreen> {
  final String _moduleName = 'pessoas';
  final PessoaService _pessoaService = PessoaService();
  late Future<List<Pessoa>> _pessoasFuture;
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _pessoasFuture = _loadPessoas();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('pessoasListScreen');
    appStateManager.setShowTutorial('pessoasListScreen', false);
  }

  Future<List<Pessoa>> _loadPessoas() async {
    try {
      if (widget.vinculos != null && widget.vinculos!.isNotEmpty) {
        return await _pessoaService.getByVinculos(widget.vinculos!);
      } else {
        return await _pessoaService.getByProdutorId(
          Provider.of<AppStateManager>(context, listen: false).activeProdutorId!,
        );
      }
    } catch (e) {
      throw e;
    }
  }


  void _refreshPessoas() {
    _returnObject = true;
    setState(() {
      _pessoasFuture = _loadPessoas();
    });
  }

  String _getTitle(BuildContext context) {
    if (widget.vinculos != null) {
      final vinculosMap = PessoaOptions.getLocalizedVinculos(context);
      return vinculosMap[widget.vinculos!] ?? '${widget.vinculos}s';
    }
    return widget.isSelectMode ? S.of(context).select_person : S.of(context).people_entities;
  }

  @override
  Widget build(BuildContext context) {
    return ListTemplate<Pessoa>(
      icon: Icons.people,
      future: _pessoasFuture,
      serviceName: _pessoaService,
      itemTitleBuilder: (pessoa) => pessoa.nome,
      itemSubtitleBuilder: (pessoa) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${S.of(context).type}: ${PessoaOptions.getLocalizedTipos(context)[pessoa.tipo] ?? pessoa.tipo ?? ''}'),
          Text('${S.of(context).relationship}: ${PessoaOptions.getLocalizedVinculos(context)[pessoa.vinculo] ?? pessoa.vinculo}'),
          if (pessoa.documento != null)
            Text('${S.of(context).document}: ${pessoa.documento}'),
        ],
      ),
      moduleName: _moduleName,
      title: _getTitle(context),
      customTutorialSteps: _buildCustomTutorialSteps(),
      errorText: S.of(context).error_loading,
      formScreenBuilder: (pessoa) => PessoaFormScreen(pessoa: pessoa),
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      itemExpandedContentWidgets: (pessoa) => [
        if (pessoa.telefone != null)
          Text('${S.of(context).phone}: ${pessoa.telefone}'),
        if (pessoa.email != null)
          Text('${S.of(context).email}: ${pessoa.email}'),
        if (pessoa.endereco != null)
          Text('${S.of(context).address}: ${pessoa.endereco}'),
        if (pessoa.notas != null)
          Text('${S.of(context).notes}: ${pessoa.notas}'),
      ],
      itemLeadingIcon: Icons.person,
      loadingText: S.of(context).loading,
      nomeTutorial: widget.vinculos != null
          ? PessoaOptions.getLocalizedVinculos(context)[widget.vinculos!] ?? S.of(context).individual
          : S.of(context).person,
      nomeTutorialPlural: widget.vinculos != null
          ? PessoaOptions.getLocalizedVinculos(context)[widget.vinculos!] ?? S.of(context).people_entities
          : S.of(context).people_entities,
      notFoundText: S.of(context).not_found,
      onRefresh: _refreshPessoas,
      showTutorial: _showTutorial,
      viewScreenBuilder: (pessoa) => PessoaScreen(pessoa: pessoa!),
      onWillPop: () async => true,
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {};
  }
}