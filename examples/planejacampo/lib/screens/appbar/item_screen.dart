import 'package:flutter/material.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/models/estoque.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/estoques/estoque_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/screens/appbar/item_form_screen.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/widgets/card_section.dart';

class ItemScreen extends StatefulWidget {
  final Item item;

  const ItemScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  final String _moduleName = 'itens';
  final ItemService _itemService = ItemService();
  final EstoqueService _estoqueService = EstoqueService();
  final PropriedadeService _propriedadeService = PropriedadeService();
  late Future<Item?> _futureItem;
  late Future<List<Estoque>> _futureEstoques;
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  late Item _currentItem;
  Object _returnObject = '';

  final GlobalKey _estoquesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _loadItem();
    _checkPermissions();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('itemScreen');
    appStateManager.setShowTutorial('itemScreen', false);
  }

  void _loadItem() {
    setState(() {
      _futureItem = _itemService.getById(widget.item.id);
      _futureEstoques = _estoqueService.getByAttributes({
        'itemId': widget.item.id,
      });
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
        pageBuilder: (context, animation, secondaryAnimation) =>
            ItemFormScreen(item: _currentItem),
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
    ).then((updatedItem) {
      if (updatedItem != null) {
        _returnObject = true;
        if (updatedItem is Item) {
          setState(() {
            _currentItem = updatedItem;
          });
        }
        _loadItem();
      }
    });
  }

  Future<void> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_deletion),
          content: Text(S.of(context).confirm_deletion_message('{nomeTutorial}')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _itemService.delete(_currentItem.id);
        Navigator.of(context).pop(true); // Retorna para a tela anterior após deletar
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error_deleting_fleet('{error}'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).input_or_product,
      moduleName: _moduleName,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).input_or_product,
      nomeTutorialPlural: S.of(context).inputs_and_products,
      returnObject: _returnObject,
      onWillPop: () async {
        return true; // Permite a navegação
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      onEditPressed: _canEdit ? () => _navigateToFormScreen() : null,
      onDeletePressed: _canDelete ? _confirmDelete : null,
      summarySection: _buildSummarySection(),
      serviceName: _itemService,
      itemIdValue: widget.item.id,
      itemName: S.of(context).item,
      fieldReference: 'itemId',
      cardSections: [
        CardSection(
          title: S.of(context).stocks,
          key: _estoquesKey,
          cards: _buildEstoquesCards(),
        ),
      ],
      customTutorialSteps: {
        'estoques': {
          'key': _estoquesKey,
          'message': S.of(context).item_stocks_listed,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
      },
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder<Item?>(
      future: _futureItem,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final item = snapshot.data!;
          final localizedTipos = ItemOptions.getLocalizedTipos(context);
          final localizedCategorias = ItemOptions.getLocalizedCategorias(context);
          final localizedUnidadesMedida = ItemOptions.getLocalizedUnidadesMedida(context);
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícone Representativo do Item
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2, // Ícone genérico para Item
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Informações Básicas do Item
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nome,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.category, color: Theme.of(context).colorScheme.secondary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  localizedTipos[item.tipo] ?? item.tipo,
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
                  // Informações Detalhadas
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.category,
                    label: S.of(context).category,
                    value: localizedCategorias[item.categoria] ?? item.categoria,
                  ),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.scale,
                    label: S.of(context).unit_of_measure,
                    value: localizedUnidadesMedida[item.unidadeMedida] ?? item.unidadeMedida,
                  ),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.percent,
                    label: S.of(context).decay_factor,
                    value: item.fatorDecaimento.toString(),
                  ),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.inventory_2,
                    label: S.of(context).stock_movements,
                    value: item.movimentaEstoque ? S.of(context).yes : S.of(context).no,
                  ),
                  if (item.descricao.isNotEmpty)
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.description,
                      label: S.of(context).description,
                      value: item.descricao,
                    ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  List<Widget> _buildEstoquesCards() {
    return [
      FutureBuilder<List<Estoque>>(
        future: _futureEstoques,
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
              children: snapshot.data!.map((estoque) {
                return FutureBuilder<Propriedade?>(
                  future: _propriedadeService.getById(estoque.propriedadeId),
                  builder: (context, propriedadeSnapshot) {
                    if (propriedadeSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        leading: const CircularProgressIndicator(),
                        title: Text(S.of(context).loading),
                      );
                    } else if (propriedadeSnapshot.hasError || !propriedadeSnapshot.hasData) {
                      return ListTile(
                        leading: Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                        title: Text(S.of(context).not_found),
                      );
                    } else {
                      final propriedade = propriedadeSnapshot.data!;
                      final unidadeMedidaCurta = estoque.unidadeMedida.split(' ').last;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: Icon(Icons.store, color: Theme.of(context).colorScheme.primary),
                          title: Text('${S.of(context).agricultural_property}: ${propriedade.nome}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${S.of(context).quantity}: ${estoque.quantidade} $unidadeMedidaCurta'),
                              Text('${S.of(context).cmp}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(estoque.cmp)}'),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            );
          }
        },
      ),
    ];
  }

}
