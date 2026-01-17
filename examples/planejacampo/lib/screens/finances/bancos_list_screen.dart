import 'package:flutter/material.dart';
import 'package:planejacampo/models/contabil/banco.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/screens/finances/banco_form_screen.dart';
import 'package:planejacampo/screens/finances/banco_screen.dart';
import 'package:planejacampo/services/contabil/banco_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/utils/conta_bancaria_options.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/estados_options.dart';

class BancosListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const BancosListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _BancosListScreenState createState() => _BancosListScreenState();
}

class _BancosListScreenState extends State<BancosListScreen> {
  final String _moduleName = 'bancos';
  final BancoService _bancoService = BancoService();
  final ContaService _contaService = ContaService();
  late Future<Map<String, List<Conta>>> _bancosEContasFuture;
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _bancosEContasFuture = _loadBancosEContas();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('bancosListScreen');
    appStateManager.setShowTutorial('bancosListScreen', false);
  }

  Future<Map<String, List<Conta>>> _loadBancosEContas() async {
    try {
      final Map<String, List<Conta>> contasMap = {};
      final bancos = await _bancoService.getByAttributes({
        'produtorId': Provider.of<AppStateManager>(context, listen: false).activeProdutorId,
      });

      // Para cada banco, carrega suas contas
      for (var banco in bancos) {
        final contas = await _contaService.getByAttributes({
          'bancoId': banco.id,
        });
        contasMap[banco.id] = contas;
      }

      return contasMap;
    } catch (e) {
      throw e;
    }
  }

  void _refreshBancos() {
    _returnObject = true;
    setState(() {
      _bancosEContasFuture = _loadBancosEContas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appStateManager = Provider.of<AppStateManager>(context);

    return FutureBuilder<Map<String, List<Conta>>>(
      future: _bancosEContasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        }

        final contasMap = snapshot.data ?? {};

        return ListTemplate<Banco>(
          icon: Icons.account_balance,
          future: _bancoService.getByAttributes({
            'produtorId': appStateManager.activeProdutorId,
          }),
          serviceName: _bancoService,
          itemTitleBuilder: (banco) => banco.nome,
          itemSubtitleBuilder: (banco) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).country}: ${EstadosOptions.getLocalizedPaises(context)[banco.siglaPais] ?? banco.siglaPais}',
              ),
              if (banco.telefone != null)
                Text(
                  '${S.of(context).phone}: ${banco.telefone}',
                ),
            ],
          ),
          moduleName: _moduleName,
          title: widget.isSelectMode ? S.of(context).select_bank : S.of(context).banks,
          customTutorialSteps: {},
          errorText: S.of(context).error_loading,
          formScreenBuilder: (banco) => BancoFormScreen(banco: banco),
          isSelectMode: widget.isSelectMode,
          isSetMode: widget.isSetMode,
            itemExpandedContentWidgets: (banco) {
              final List<Widget> widgets = [];
              final contas = contasMap[banco.id] ?? [];

              if (banco.endereco != null) {
                widgets.add(ObjectTemplate.buildInfoRow(
                  context: context,
                  icon: Icons.location_on,
                  label: S.of(context).address,
                  value: banco.endereco!,
                ));
              }

              if (banco.contato != null) {
                widgets.add(ObjectTemplate.buildInfoRow(
                  context: context,
                  icon: Icons.contact_phone,
                  label: S.of(context).contact,
                  value: banco.contato!,
                ));
              }

              if (contas.isNotEmpty) {
                widgets.add(const SizedBox(height: 16));
                widgets.add(
                  ObjectTemplate.buildCardSection(
                    CardSection(
                      title: S.of(context).accounts,
                      icon: Icons.account_balance_wallet,
                      cards: contas.map((conta) => ListTile(
                        leading: Icon(
                          conta.tipo == 'Crédito'
                              ? Icons.credit_card
                              : Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          conta.nome,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ContaBancariaOptions.getLocalizedTipos(context)[conta.tipo] ?? conta.tipo,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (conta.numeroConta != null) Text(
                              '${S.of(context).account_number}: ${conta.numeroConta}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                    Theme.of(context),
                  ),
                );
              }

              return widgets;
            },
          itemLeadingIcon: Icons.account_balance,
          loadingText: S.of(context).loading,
          nomeTutorial: S.of(context).bank,
          nomeTutorialPlural: S.of(context).banks,
          notFoundText: S.of(context).not_found,
          onRefresh: _refreshBancos,
          showTutorial: _showTutorial,
          viewScreenBuilder: (banco) => BancoScreen(banco: banco!),
          onWillPop: () async => true,
        );
      },
    );
  }
}