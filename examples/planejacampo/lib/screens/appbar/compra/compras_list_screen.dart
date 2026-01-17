import 'package:flutter/material.dart';
import 'package:planejacampo/models/compra.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/models/item_compra.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/screens/appbar/compra/compras_checkout_form_screen.dart';
import 'package:planejacampo/services/compra_service.dart';
import 'package:planejacampo/services/item_compra_service.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/screens/appbar/compra/compra_screen.dart';
import 'package:planejacampo/screens/appbar/compra/compras_itens_choose_screen.dart';

class ComprasListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const ComprasListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _ComprasListScreenState createState() => _ComprasListScreenState();
}

class _ComprasListScreenState extends State<ComprasListScreen> {
  final String _moduleName = 'compras';
  final CompraService _compraService = CompraService();
  final PessoaService _pessoaService = PessoaService();
  final ItemCompraService _itemCompraService = ItemCompraService();
  final ContaPagarService _contaPagarService = ContaPagarService();

  late Future<List<Compra>> _comprasFuture = Future.value([]);
  Map<String, String> _nomesFornecedores = {};
  Map<String, List<ItemCompra>> _itensCompra = {};
  Map<String, List<ContaPagar>> _contasPagarCompra = {};

  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _comprasFuture = _loadData();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('comprasListScreen');
    appStateManager.setShowTutorial('comprasListScreen', false);
  }

  Future<List<Compra>> _loadData() async {
    try {
      final String produtorId = Provider.of<AppStateManager>(context, listen: false).activeProdutorId!;

      final compras = await _compraService.getByProdutorId(produtorId);

      for (var compra in compras) {
        if (!_nomesFornecedores.containsKey(compra.fornecedorId)) {
          final fornecedor = await _pessoaService.getById(compra.fornecedorId);
          if (fornecedor != null) {
            _nomesFornecedores[compra.fornecedorId] = fornecedor.nome;
          }
        }

        final itens = await _itemCompraService.getByAttributes({'compraId': compra.id});
        _itensCompra[compra.id] = itens;

        final contasPagar = await _contaPagarService.getByAttributes({
          'origemId': compra.id,
          'origemTipo': 'compras',
        });
        _contasPagarCompra[compra.id] = contasPagar;
      }

      return compras;
    } catch (e) {
      throw e;
    }
  }

  void _refreshCompras() {
    _returnObject = true;
    setState(() {
      _nomesFornecedores.clear();
      _itensCompra.clear();
      _contasPagarCompra.clear();
      _comprasFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTemplate<Compra>(
      icon: Icons.shopping_cart,
      future: _comprasFuture.then((compras) {
        compras.sort((a, b) => b.data.compareTo(a.data)); // Ordena localmente por data decrescente
        return compras;
      }),
      serviceName: _compraService,
      moduleName: _moduleName,
      title: widget.isSelectMode ? S.of(context).select_purchase : S.of(context).purchases,
      itemTitleBuilder: (compra) => FormatacaoUtil.formatDate(compra.data),
      itemSubtitleBuilder: (compra) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${S.of(context).supplier}: ${_nomesFornecedores[compra.fornecedorId] ?? S.of(context).unknown_supplier}'),
          Text('${S.of(context).total_value}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(compra.valorTotal)}'),
        ],
      ),
      itemExpandedContentWidgets: (compra) {
        final List<Widget> widgets = [];
        final itens = _itensCompra[compra.id] ?? [];
        final contasPagar = _contasPagarCompra[compra.id] ?? [];

        if (itens.isNotEmpty) {
          widgets.add(const SizedBox(height: 16));
          widgets.add(
            ObjectTemplate.buildCardSection(
              CardSection(
                title: S.of(context).purchase_items,
                icon: Icons.shopping_basket,
                cards: itens.map((item) {
                  // Aqui vamos adicionar um FutureBuilder para obter o nome do item
                  return FutureBuilder<Item?>(
                    future: ItemService().getById(item.itemId),
                    builder: (context, snapshot) {
                      final itemName = snapshot.data?.nome ?? S.of(context).not_found;

                      return ListTile(
                        title: Text(
                          itemName,  // Agora exibimos o nome do item
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.quantidade} ${item.unidadeMedida}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${S.of(context).unit_price}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(item.precoUnitario)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${S.of(context).total_value}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(item.valorTotal)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              Theme.of(context),
            ),
          );
        }

        if (contasPagar.isNotEmpty) {
          widgets.add(const SizedBox(height: 16));
          widgets.add(
            ObjectTemplate.buildCardSection(
              CardSection(
                title: S.of(context).payment_details,
                icon: Icons.payment,
                cards: contasPagar.map((conta) => ListTile(
                  title: Text(
                    FormatacaoUtil.formatNumberWithTwoDecimalPlaces(conta.valor),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${S.of(context).due_date}: ${FormatacaoUtil.formatDate(conta.dataVencimento)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${S.of(context).payment_method}: ${conta.meioPagamento}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (conta.dataPagamento != null)
                        Text(
                          '${S.of(context).payment}: ${FormatacaoUtil.formatDate(conta.dataPagamento!)}',
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
      itemLeadingIcon: Icons.receipt,
      loadingText: S.of(context).loading,
      notFoundText: S.of(context).not_found,
      errorText: S.of(context).error_loading,
      nomeTutorial: S.of(context).purchase,
      nomeTutorialPlural: S.of(context).purchases,
      showTutorial: _showTutorial,
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      onRefresh: _refreshCompras,
      formScreenBuilder: (compra) {
        if (compra == null) {
          return ComprasItensChooseScreen(carrinho: []);
        } else {
          return ComprasCheckoutFormScreen(
            carrinho: _itensCompra[compra.id] ?? [],
            compra: compra,
            onUpdate: _refreshCompras,
          );
        }
      },
      viewScreenBuilder: (compra) => CompraScreen(compra: compra!),
      onWillPop: () async => true,
    );
  }
}
