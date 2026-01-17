// pessoa_screen.dart
import 'package:flutter/material.dart';
import 'package:planejacampo/models/pessoa.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/screens/appbar/pessoa_form_screen.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/pessoa_options.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/card_section.dart';

class PessoaScreen extends StatefulWidget {
  final Pessoa pessoa;

  const PessoaScreen({
    Key? key,
    required this.pessoa,
  }) : super(key: key);

  @override
  _PessoaScreenState createState() => _PessoaScreenState();
}

class _PessoaScreenState extends State<PessoaScreen> {
  final String _moduleName = 'pessoas';
  final PessoaService _pessoaService = PessoaService();
  late Future<Pessoa?> _futurePessoa;
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  late Pessoa _currentPessoa;
  Object _returnObject = '';

  final GlobalKey _detalhesKey = GlobalKey();

  // Definição das GlobalKeys para seções adicionais, se necessário
  // final GlobalKey _propriedadesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentPessoa = widget.pessoa;
    _loadPessoa();
    _checkPermissions();
    final AppStateManager appStateManager =
    Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('pessoaScreen');
    appStateManager.setShowTutorial('pessoaScreen', false);
  }

  void _loadPessoa() {
    setState(() {
      _futurePessoa = _pessoaService.getById(widget.pessoa.id);
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
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PessoaFormScreen(pessoa: _currentPessoa),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    ).then((updatedPessoa) {
      if (updatedPessoa != null) {
        if (updatedPessoa is Pessoa) {
          setState(() {
            _currentPessoa = updatedPessoa;
          });
        }
        _returnObject = true;
        _loadPessoa(); // Recarrega os dados da pessoa, se necessário
      }
    });
  }

  Future<void> _confirmDelete() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_delete),
          content: Text(S.of(context).are_you_sure_delete_person),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).delete),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _pessoaService.delete(widget.pessoa.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).person_deleted_successfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_deleting_person(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<CardSection> _buildAdditionalCardSections() {
    // Se você tiver outras seções para exibir, como listas de relacionamentos,
    // use o método buildCardSectionWithFuture para construí-las.

    // Exemplo: Lista de Propriedades relacionadas à Pessoa
    /*
    return [
      ObjectTemplate.buildCardSectionWithFuture<Propriedade>(
        key: _propriedadesKey,
        title: S.of(context).properties,
        icon: Icons.home_work,
        future: _pessoaService.getPropriedades(widget.pessoa.id),
        itemTitle: (propriedade) => propriedade.nome,
        itemSubtitle: (propriedade) => Text(
          '${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(propriedade.area)} ${S.of(context).hectares}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onEdit: (propriedade) => _navigateToPropriedadeForm(propriedade),
        onDelete: (propriedade) => _confirmDeletePropriedade(propriedade),
        itemLeadingIcon: Icons.home_work,
        loadingText: S.of(context).loading,
        errorText: S.of(context).error_loading_properties,
        notFoundText: S.of(context).no_properties_found,
      ),
    ];
    */

    // Se não houver seções adicionais, retorne uma lista vazia
    return [];
  }

  // Métodos auxiliares para seções adicionais (Exemplo)
  /*
  void _navigateToPropriedadeForm(Propriedade propriedade) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropriedadeFormScreen(propriedade: propriedade),
      ),
    ).then((updatedPropriedade) {
      if (updatedPropriedade != null) {
        // Atualize a lista de propriedades ou outros estados conforme necessário
        setState(() {
          _returnObject = true;
          _loadPessoa(); // Recarrega os dados para refletir as alterações
        });
      }
    });
  }

  Future<void> _confirmDeletePropriedade(Propriedade propriedade) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_delete_property),
          content: Text(S.of(context).are_you_sure_delete_property),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).delete),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _propriedadeService.delete(propriedade.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).property_deleted_successfully),
            backgroundColor: Colors.green,
          ),
        );
        _loadPessoa(); // Recarrega os dados para refletir a exclusão
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_deleting_property(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_returnObject);
        return false; // Impede o comportamento padrão de pop
      },
      child: SingleScreenTemplate(
        title: S.of(context).person_details,
        moduleName: _moduleName,
        showTutorial: _showTutorial,
        nomeTutorial: S.of(context).person,
        nomeTutorialPlural: S.of(context).people,
        returnObject: _returnObject,
        onWillPop: () async {
          return true; // Permite a navegação
        },
        canEdit: _canEdit,
        canDelete: _canDelete,
        onEditPressed: _canEdit ? () => _navigateToFormScreen() : null,
        onDeletePressed: _canDelete ? _confirmDelete : null,
        summarySection: _buildSummarySection(),
        serviceName: _pessoaService,
        itemIdValue: widget.pessoa.id,
        itemName: S.of(context).people,
        fieldReference: 'pessoaId',
        cardSections: _buildAdditionalCardSections(), // Adiciona seções de cartões, se houver
        isExpanded: false, // Controla o estado dos botões flutuantes
        onFloatingActionButtonPressed: null, // Implementar se necessário
        customTutorialSteps: {
          'customDetalhes': {
            'key': _detalhesKey,
            'message': S.of(context).person_details_info,
            'shape': 'RRect',
            'align': 'ContentAlign.top',
          },
          // Adicione mais passos de tutorial conforme necessário
        },
        customActionTutorialSteps: {
          // Adicione passos de tutorial para ações, se necessário
        },
        additionalFloatingActionButtons: (BuildContext context) => [
          // Adicione botões flutuantes adicionais, se necessário
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder<Pessoa?>(
      future: _futurePessoa,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final pessoa = snapshot.data!;
          final localizedTipos = PessoaOptions.getLocalizedTipos(context);
          final localizedVinculos = PessoaOptions.getLocalizedVinculos(context);
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Utilizando buildInfoRow para cada campo com ícones
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.person, // Ícone representativo para Nome
                    label: S.of(context).name,
                    value: pessoa.nome,
                    valueBelowLabel: false,
                  ),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.type_specimen, // Ícone representativo para Relacionamento
                    label: S.of(context).relationship,
                    value: localizedVinculos[pessoa.vinculo] ?? pessoa.vinculo,
                  ),
                  if (pessoa.tipo != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.category, // Ícone representativo para Tipo
                      label: S.of(context).type,
                      value: localizedTipos[pessoa.tipo] ?? pessoa.tipo!,
                    ),
                  if (pessoa.documento != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.document_scanner, // Ícone representativo para Documento
                      label: S.of(context).document,
                      value: pessoa.documento!,
                    ),
                  if (pessoa.telefone != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.phone, // Ícone representativo para Telefone
                      label: S.of(context).phone,
                      value: pessoa.telefone!,
                    ),
                  if (pessoa.email != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.email, // Ícone representativo para Email
                      label: 'Email',
                      value: pessoa.email!,
                    ),
                  if (pessoa.endereco != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.home, // Ícone representativo para Endereço
                      label: S.of(context).address,
                      value: pessoa.endereco!,
                    ),
                  if (pessoa.notas != null)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.note, // Ícone representativo para Notas
                      label: S.of(context).notes,
                      value: pessoa.notas!,
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
