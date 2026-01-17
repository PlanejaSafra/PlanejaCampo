import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/models/compra.dart';
import 'package:planejacampo/models/item_compra.dart';
import 'package:planejacampo/services/compra_service.dart';
import 'package:planejacampo/services/item_compra_service.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/utils/conta_bancaria_options.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/utils/meio_pagamento_options.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/screens/appbar/compra/compras_checkout_form_screen.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/utils/conta_bancaria_options.dart';

class CompraScreen extends StatefulWidget {
  final Compra compra;

  const CompraScreen({
    Key? key,
    required this.compra,
  }) : super(key: key);

  @override
  _CompraScreenState createState() => _CompraScreenState();
}

class _CompraScreenState extends State<CompraScreen> {
  final String _moduleName = 'compras';
  final CompraService _compraService = CompraService();
  final PessoaService _pessoaService = PessoaService();
  final ItemCompraService _itemCompraService = ItemCompraService();
  final ContaPagarService _contaPagarService = ContaPagarService();
  final ItemService _itemService = ItemService();
  final ContaService _contaService = ContaService();

  late Future<Compra?> _futureCompra;
  late Compra _currentCompra;
  bool _dataWasModified = false;
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentCompra = widget.compra;
    _loadCompra();
    _checkPermissions();

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('compraScreen');
    appStateManager.setShowTutorial('compraScreen', false);
  }

  void _loadCompra() {
    setState(() {
      _futureCompra = _compraService.getById(_currentCompra.id);
    });
  }

  void _checkPermissions() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEdit(_moduleName);
      _canDelete = appStateManager.canDelete(_moduleName);
    });
  }

  void _navigateToFormScreen() async {
    List<ItemCompra> itensCompra = await _itemCompraService.getByAttributes({'compraId': widget.compra.id});
    List<ContaPagar> contasPagar = await _contaPagarService.getByAttributes({
      'origemId': widget.compra.id,
      'origemTipo': 'compras'
    });

    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ComprasCheckoutFormScreen(
              compra: _currentCompra,
              carrinho: itensCompra,
              onUpdate: () {},
            ),
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
    );

    if (result != null) {
      if (result is Compra) {
        _dataWasModified = true;
        _currentCompra = result;
        _loadCompra();
        Navigator.of(context).pop(true);
        return;
      }
    }
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
      title: S.of(context).purchase_details,
      moduleName: _moduleName,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).purchase,
      nomeTutorialPlural: S.of(context).purchases,
      returnObject: _dataWasModified,
      onWillPop: () async {
        Navigator.of(context).pop(_dataWasModified);
        return false;
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      onEditPressed: _canEdit ? _navigateToFormScreen : null,
      summarySection: _buildSummarySection(),
      serviceName: _compraService,
      itemIdValue: widget.compra.id,
      itemName: S.of(context).purchase,
      fieldReference: 'compraId',
      cardSections: [
        _buildItensCompraCardSection(),
        _buildPagamentosCompraCardSection(),
      ],
      isExpanded: _isExpanded,
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      customTutorialSteps: _buildCustomTutorialSteps(),
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'items': {
        'key': GlobalKey(),
        'message': S.of(context).purchase_items_listed,
        'shape': 'RRect'
      },
      'payments': {
        'key': GlobalKey(),
        'message': S.of(context).payment_details,
        'shape': 'RRect'
      }
    };
  }

  Widget _buildSummarySection() {
    return FutureBuilder<Compra?>(
      future: _futureCompra,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        }

        final compra = snapshot.data!;

        return FutureBuilder<dynamic>(
          future: _pessoaService.getById(compra.fornecedorId),
          builder: (context, fornecedorSnapshot) {
            final fornecedorName = fornecedorSnapshot.data?.nome ?? S.of(context).unknown_supplier;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.person,
                      label: S.of(context).supplier,
                      value: fornecedorName,
                    ),
                    const SizedBox(height: 8),
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.attach_money,
                      label: S.of(context).total_value,
                      value: '${S.of(context).currency_symbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(compra.valorTotal)}',
                    ),
                    const SizedBox(height: 8),
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.calendar_today,
                      label: S.of(context).date,
                      value: FormatacaoUtil.formatDate(compra.data),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  CardSection _buildItensCompraCardSection() {
    return CardSection(
      title: S.of(context).purchase_items,
      icon: Icons.shopping_cart,
      cards: [
        FutureBuilder<List<ItemCompra>>(
          future: _itemCompraService.getByAttributes({'compraId': widget.compra.id}),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(S.of(context).not_found));
            }

            return Column(
              children: snapshot.data!.map((itemCompra) {
                return FutureBuilder<Item?>(
                  future: _itemService.getById(itemCompra.itemId),
                  builder: (context, itemSnapshot) {
                    if (!itemSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final item = itemSnapshot.data!;
                    final unidade = ItemOptions.getLocalizedUnidadesMedidaAbreviada(context)[itemCompra.unidadeMedida] ??
                        itemCompra.unidadeMedida;

                    return Card(
                      child: ListTile(
                        title: Text(item.nome),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${S.of(context).quantity}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemCompra.quantidade)} $unidade'),
                            Text('${S.of(context).unit_price}: ${S.of(context).currency_symbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemCompra.precoUnitario)}'),
                            Text('${S.of(context).total_value}: ${S.of(context).currency_symbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemCompra.valorTotal)}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  CardSection _buildPagamentosCompraCardSection() {
    return CardSection(
      title: S.of(context).payment_details,
      icon: Icons.payments,
      cards: [
        FutureBuilder<List<ContaPagar>>(
          future: _contaPagarService.getByAttributes({
            'origemId': widget.compra.id,
            'origemTipo': 'compras',
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                child: ListTile(
                  title: Text(S.of(context).loading),
                ),
              );
            } else if (snapshot.hasError) {
              return Card(
                child: ListTile(
                  title: Text(S.of(context).error_loading),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Card(
                child: ListTile(
                  title: Text(S.of(context).not_found),
                ),
              );
            }

            final List<ContaPagar> contasPagar = List<ContaPagar>.from(snapshot.data!);
            contasPagar.sort((a, b) => a.dataVencimento.compareTo(b.dataVencimento));

            return Column(
              children: contasPagar.map((conta) {
                final String? contaId = conta.contaId;

                if (contaId != null && contaId.isNotEmpty) {
                  return FutureBuilder<Conta?>(
                    future: _contaService.getById(contaId),
                    builder: (context, contaSnapshot) {
                      final String contaNome = contaSnapshot.data?.nome ?? '';
                      final String tipoConta = ContaBancariaOptions.getLocalizedTipos(context)[contaSnapshot.data?.tipo ?? ''] ?? '';

                      return Card(
                        child: ListTile(
                          title: Text(
                            '${S.of(context).payment_value}: '
                                '${S.of(context).currency_symbol} '
                                '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(conta.valor)}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${S.of(context).due_date}: ${FormatacaoUtil.formatDate(conta.dataVencimento)}'),
                              Text('${S.of(context).payment_method}: '
                                  '${MeioPagamentoOptions.getLocalizedMeiosDePagamento(context)[conta.meioPagamento] ?? conta.meioPagamento}'),
                              if (contaNome.isNotEmpty && tipoConta.isNotEmpty)
                                Text('${S.of(context).payment_account}: $contaNome ($tipoConta)'),
                              if (conta.dataPagamento != null)
                                Text('${S.of(context).payment}: ${FormatacaoUtil.formatDate(conta.dataPagamento!)}'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${S.of(context).payment_value}: '
                            '${S.of(context).currency_symbol} '
                            '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(conta.valor)}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${S.of(context).due_date}: ${FormatacaoUtil.formatDate(conta.dataVencimento)}'),
                          Text('${S.of(context).payment_method}: '
                              '${MeioPagamentoOptions.getLocalizedMeiosDePagamento(context)[conta.meioPagamento] ?? conta.meioPagamento}'),
                          if (conta.dataPagamento != null)
                            Text('${S.of(context).payment}: ${FormatacaoUtil.formatDate(conta.dataPagamento!)}'),
                        ],
                      ),
                    ),
                  );
                }
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}