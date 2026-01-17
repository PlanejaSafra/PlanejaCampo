import 'package:flutter/material.dart';
import 'package:planejacampo/models/contabil/banco.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/services/contabil/banco_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/conta_bancaria_options.dart';
import 'package:planejacampo/screens/finances/banco_form_screen.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/screens/finances/conta_dialog_screen.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/utils/estados_options.dart';

class BancoScreen extends StatefulWidget {
  final Banco banco;

  const BancoScreen({
    Key? key,
    required this.banco,
  }) : super(key: key);

  @override
  _BancoScreenState createState() => _BancoScreenState();
}

class _BancoScreenState extends State<BancoScreen> {
  final String _moduleName = 'bancos';
  final BancoService _bancoService = BancoService();
  final ContaService _contaService = ContaService();
  late Future<Banco?> _futureBanco;
  late Future<List<Conta>> _futureContas;
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  late Banco _currentBanco;
  Object _returnObject = '';
  final GlobalKey _contasKey = GlobalKey();
  final GlobalKey _addContaKey = GlobalKey();
  bool _isExpanded = false;

  late ContaDialogScreen _contaDialogScreen;

  final GlobalKey _firstContaMoreOptionsKey = GlobalKey();
  final GlobalKey _firstContaEditKey = GlobalKey();
  final GlobalKey _firstContaDeleteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentBanco = widget.banco;
    _loadBanco();
    _checkPermissions();

    _contaDialogScreen = ContaDialogScreen(
      bancoId: widget.banco.id,
      contaService: _contaService,
      canEdit: _canEdit,
      canDelete: _canDelete,
      onUpdate: () {
        _returnObject = true;
        _loadBanco();
        setState(() {});
      },
      contasKey: _contasKey,
      firstContaMoreOptionsKey: _firstContaMoreOptionsKey,
      firstContaEditKey: _firstContaEditKey,
      firstContaDeleteKey: _firstContaDeleteKey,
    );

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('bancoScreen');
    appStateManager.setShowTutorial('bancoScreen', false);
  }

  void _loadBanco() {
    setState(() {
      _futureBanco = _bancoService.getById(widget.banco.id);
      _futureContas = _contaService.getByAttributes({'bancoId': widget.banco.id});
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
        pageBuilder: (context, animation, secondaryAnimation) => BancoFormScreen(banco: _currentBanco),
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
    ).then((updatedBanco) {
      if (updatedBanco != null) {
        _returnObject = true;
        if (updatedBanco is Banco) {
          setState(() {
            _currentBanco = updatedBanco;
          });
        }
        _loadBanco();
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_returnObject);
        return false;
      },
      child: SingleScreenTemplate(
        title: S.of(context).bank_details,
        moduleName: _moduleName,
        showTutorial: _showTutorial,
        nomeTutorial: S.of(context).bank,
        nomeTutorialPlural: S.of(context).banks,
        returnObject: _returnObject,
        onWillPop: () async {
          return true;
        },
        canEdit: _canEdit,
        canDelete: _canDelete,
        onEditPressed: _canEdit ? _navigateToFormScreen : null,
        summarySection: _buildSummarySection(),
        serviceName: _bancoService,
        itemIdValue: widget.banco.id,
        itemName: S.of(context).bank,
        fieldReference: 'bancoId',
        cardSections: _buildCardSections(),
        isExpanded: _isExpanded,
        onFloatingActionButtonPressed: _toggleFloatingActionButton,
        customTutorialSteps: {
          'contas': {
            'key': _contasKey,
            'message': S.of(context).bank_accounts_listed,
            'shape': 'RRect',
            'align': 'ContentAlign.top',
          },
          'moreOptionsButton': {
            'key': _firstContaMoreOptionsKey,
            'message': S.of(context).click_to_see_more_options_on_first_account,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
            'hasMoreOptions': true,
          },
        },
        customActionTutorialSteps: {
          'addConta': {
            'key': _addContaKey,
            'message': S.of(context).add_account,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
          },
        },
        additionalFloatingActionButtons: (BuildContext context) => [
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () async {
              _toggleFloatingActionButton();
              bool? result = await _contaDialogScreen.addConta(context);
              if (result == true) {
                _returnObject = true;
                setState(() {});
              }
            },
            icon: Icons.add,
            text: S.of(context).add_account,
            key: _addContaKey,
            heroTag: 'addConta',
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder<Banco?>(
      future: _futureBanco,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final banco = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.account_balance,
                    label: S.of(context).name,
                    value: banco.nome,
                  ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.public,
                    label: S.of(context).country,
                    value: _getLocalizedCountryName(context, banco.siglaPais),
                  ),
                  if (banco.endereco != null && banco.endereco!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.location_on,
                      label: S.of(context).address,
                      value: banco.endereco!,
                    ),
                  ],
                  if (banco.telefone != null && banco.telefone!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.phone,
                      label: S.of(context).phone,
                      value: banco.telefone!,
                    ),
                  ],
                  if (banco.contato != null && banco.contato!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.contact_mail,
                      label: S.of(context).contact,
                      value: banco.contato!,
                    ),
                  ],
                ],
              ),
            ),
          );
        }
      },
    );
  }

  String _getLocalizedCountryName(BuildContext context, String countrySigla) {
    final Map<String, String> paisesMap = EstadosOptions.getLocalizedPaises(context);
    final pais = EstadosOptions.paises.firstWhere((p) => p['sigla'] == countrySigla, orElse: () => {'nome': countrySigla});
    return paisesMap[pais['nome']!] ?? pais['nome']!;
  }

  List<CardSection> _buildCardSections() {
    return [
      ObjectTemplate.buildCardSectionWithFuture<Conta>(
        key: _contasKey,
        title: S.of(context).accounts,
        iconePrincipal: Icons.account_balance_wallet,
        future: _futureContas,
        itemTitle: (conta) => conta.nome,
        itemSubtitle: (conta) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).account_type}: ${ContaBancariaOptions.getLocalizedTipos(context)[conta.tipo] ?? conta.tipo}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (conta.numeroConta != null && conta.numeroConta!.isNotEmpty)
                Text(
                  '${S.of(context).account_number}: ${conta.numeroConta}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          );
        },
        onEdit: (conta) => _contaDialogScreen.editConta(context, conta),
        onDelete: (conta) => _contaDialogScreen.deleteConta(context, conta),
        itemLeadingIcon: Icons.account_balance, // Ícone representativo para Conta
        loadingText: S.of(context).loading,
        errorText: S.of(context).error_loading,
        notFoundText: S.of(context).not_found,
        firstItemMoreOptionsKey: _firstContaMoreOptionsKey,
      ),
    ];
  }
}