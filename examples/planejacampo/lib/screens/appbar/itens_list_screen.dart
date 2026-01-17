import 'package:flutter/material.dart';
import 'package:planejacampo/models/estoque.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/screens/appbar/item_form_screen.dart';
import 'package:planejacampo/screens/appbar/item_screen.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/estoques/estoque_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/l10n/l10n.dart';

class ItensListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;
  final String? categoria; // Novo parâmetro opcional

  const ItensListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
    this.categoria, // Adiciona categoria como opcional
  }) : super(key: key);

  @override
  _ItensListScreenState createState() => _ItensListScreenState();
}

class _ItensListScreenState extends State<ItensListScreen> {
  final String _moduleName = 'itens';
  final ItemService _itemService = ItemService();
  final EstoqueService _estoqueService = EstoqueService();
  final PropriedadeService _propriedadeService = PropriedadeService();
  late Future<List<Item>> _itensFuture;
  Map<String, List<Estoque>> _estoquePorItem = {};
  Map<String, String> _nomePropriedades = {};
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _itensFuture = _loadData();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('itensListScreen');
    appStateManager.setShowTutorial('itensListScreen', false);
  }

  Future<List<Item>> _loadData() async {
    try {
      final String produtorId = Provider.of<AppStateManager>(context, listen: false).activeProdutorId!;
      List<Item> itens;

      if (widget.categoria != null) {
        // Se categoria foi fornecida, aplica o filtro
        itens = await _itemService.getByAttributes({
          'categoria': widget.categoria,
        });
      } else {
        // Caso contrário, carrega todos os itens
        itens = await _itemService.getByProdutorId(produtorId);
      }

      for (var item in itens) {
        final estoques = await _estoqueService.getByAttributes({
          'itemId': item.id,
          'produtorId': produtorId
        });
        _estoquePorItem[item.id] = estoques;

        for (var estoque in estoques) {
          if (!_nomePropriedades.containsKey(estoque.propriedadeId)) {
            final propriedade = await _propriedadeService.getById(estoque.propriedadeId);
            if (propriedade != null) {
              _nomePropriedades[estoque.propriedadeId] = propriedade.nome;
            }
          }
        }
      }

      return itens;
    } catch (e) {
      throw e;
    }
  }

  void _refreshItens() {
    _returnObject = true;
    setState(() {
      _estoquePorItem.clear();
      _nomePropriedades.clear();
      _itensFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTemplate<Item>(
      icon: Icons.inventory_2,
      future: _itensFuture,
      serviceName: _itemService,
      moduleName: _moduleName,
      title: widget.isSelectMode ? S.of(context).select_input_or_product : S.of(context).inputs_and_products,
      itemTitleBuilder: (item) => item.nome,
      itemSubtitleBuilder: (item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${S.of(context).type}: ${ItemOptions.getLocalizedTipos(context)[item.tipo] ?? item.tipo}'),
          Text('${S.of(context).categoria}: ${ItemOptions.getLocalizedCategorias(context)[item.categoria] ?? item.categoria}'),
          Text('${S.of(context).unit_of_measure}: ${ItemOptions.getLocalizedUnidadesMedida(context)[item.unidadeMedida] ?? item.unidadeMedida}'),
        ],
      ),
      itemExpandedContentWidgets: (item) {
        final List<Widget> widgets = [];

        if (item.descricao.isNotEmpty) {
          widgets.add(Text('${S.of(context).description}: ${item.descricao}'));
        }
        widgets.add(Text('${S.of(context).decay_factor}: ${item.fatorDecaimento}'));
        widgets.add(Text('${S.of(context).stock_movements}: ${item.movimentaEstoque ? S.of(context).yes : S.of(context).no}'));

        final estoques = _estoquePorItem[item.id] ?? [];
        if (estoques.isNotEmpty) {
          widgets.add(const SizedBox(height: 16));
          widgets.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                S.of(context).stocks,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );

          widgets.addAll(
            estoques.map((estoque) {
              final propriedadeNome = _nomePropriedades[estoque.propriedadeId] ??
                  S.of(context).unknown_property;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(propriedadeNome)),
                    Text(
                      '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(estoque.quantidade)} ${ItemOptions.getLocalizedUnidadesMedidaAbreviada(context)[estoque.unidadeMedida] ?? estoque.unidadeMedida}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }
        return widgets;
      },
      itemLeadingIcon: Icons.inventory,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).not_found,
      onRefresh: _refreshItens,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).item,
      nomeTutorialPlural: S.of(context).inputs_and_products,
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      viewScreenBuilder: (item) => ItemScreen(item: item!),
      formScreenBuilder: (item) => ItemFormScreen(item: item),
      onWillPop: () async => true,
    );
  }
}