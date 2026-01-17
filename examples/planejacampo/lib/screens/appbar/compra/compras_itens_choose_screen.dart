import 'package:flutter/material.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/models/item_compra.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/screens/appbar/compra/compras_checkout_form_screen.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/screens/appbar/compra/item_compra_form_screen.dart';
import 'package:planejacampo/models/compra.dart';


class ComprasItensChooseScreen extends StatefulWidget {
  final List<ItemCompra> carrinho;

  const ComprasItensChooseScreen({
    Key? key,
    required this.carrinho,
  }) : super(key: key);

  @override
  _ComprasItensChooseScreenState createState() => _ComprasItensChooseScreenState();
}

class _ComprasItensChooseScreenState extends State<ComprasItensChooseScreen> {
  final ItemService _itemService = ItemService();
  late Future<List<Item>> _futureItens;
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _precoUnitarioController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Item> _filteredItens = [];
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);

    _futureItens = _itemService.getByProdutorId(AppStateManager().activeProdutorId!);

    _showTutorial = appStateManager.showTutorial('comprasItensChooseScreen');
    appStateManager.setShowTutorial('comprasItensChooseScreen', false);

    // Listener para o campo de pesquisa
    _searchController.addListener(() {
      _filterItens(_searchController.text);
    });
  }

  void _filterItens(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItens = []; // Esvazia a lista filtrada para mostrar todos os itens
      } else {
        _filteredItens = _filteredItens
            .where((item) => item.nome.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _adicionarAoCarrinho(Item item) {
    try {
      double quantidade = double.tryParse(_quantidadeController.text) ?? 1;
      double precoUnitario = double.tryParse(_precoUnitarioController.text) ?? 0;

      if (quantidade <= 0 || precoUnitario <= 0) {
        print('Erro: Quantidade ou preço unitário inválidos.');
        return;  // Verificação de erro para quantidade e preço inválidos
      }

      if (item.id.isEmpty || AppStateManager().activePropriedadeId != null) {
        print('Erro: O item ou propriedade não foi selecionado.');
        return;  // Verificação para certificar que item e propriedade estão preenchidos
      }

      int index = widget.carrinho.indexWhere((itemCompra) => itemCompra.itemId == item.id);

      if (index >= 0) {
        setState(() {
          widget.carrinho[index] = widget.carrinho[index].copyWith(
            quantidade: quantidade,
            precoUnitario: precoUnitario,
            valorTotal: quantidade * precoUnitario,
          );
        });
      } else {
        ItemCompra itemCompra = ItemCompra(
          id: DateTime.now().toString(),
          compraId: '',  // CompraId será atualizado na hora certa
          itemId: item.id,
          quantidade: quantidade,
          precoUnitario: precoUnitario,
          valorTotal: quantidade * precoUnitario,
          unidadeMedida: item.unidadeMedida,
          propriedadeId: AppStateManager().activePropriedadeId!,  // Certifique-se de que esse valor está definido
          produtorId: AppStateManager().activeProdutorId!,
        );

        setState(() {
          widget.carrinho.add(itemCompra);
        });
      }

      _quantidadeController.clear();
      _precoUnitarioController.clear();
    } catch (e) {
      print('Erro ao adicionar ao carrinho: $e');
    }
  }


  void _gerenciarItemCompra({ItemCompra? item}) async {

    final ItemCompra? novoItem = await showDialog<ItemCompra>(
      context: context,
      builder: (BuildContext context) {
        return ItemCompraFormScreen(
          itemCompra: item,
          onSave: (ItemCompra novoItem) {
            // O novo item será passado de volta para cá
          },
        );
      },
    );

    if (novoItem != null) {
      setState(() {
        int index = widget.carrinho.indexWhere((itemCompra) => itemCompra.itemId == novoItem.itemId);
        if (index >= 0) {
          widget.carrinho[index] = novoItem;
        } else {
          widget.carrinho.add(novoItem);
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).item_selection), // Internacionalizado
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: S.of(context).search_hint, // Internacionalizado
                border: const OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Item>>(
        future: _futureItens,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Erro ao carregar itens: ${snapshot.error}');
            return Center(child: Text(S.of(context).error_loading)); // Internacionalizado
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(S.of(context).not_found)); // Internacionalizado
          } else {
            List<Item> itens = snapshot.data!;
            if (_searchController.text.isNotEmpty) {
              itens = itens.where((item) => item.nome.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
            }

            return ListView.builder(
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final item = itens[index];

                // Verifica se o item já está no carrinho, se não estiver, retorna null
                ItemCompra? itemNoCarrinho = widget.carrinho.firstWhere(
                  (itemCompra) => itemCompra.itemId == item.id,
                  orElse: () => ItemCompra(
                    id: '',
                    compraId: '',
                    itemId: '',
                    quantidade: 0,
                    precoUnitario: 0,
                    valorTotal: 0,
                    unidadeMedida: item.unidadeMedida,
                    propriedadeId: '', // Inicialize conforme necessário
                    produtorId: AppStateManager().activeProdutorId!,
                  ),
                );

                return Card(
                  child: ListTile(
                    title: Text(item.nome),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (itemNoCarrinho.itemId.isNotEmpty) ...[
                          Text('${S.of(context).quantity}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemNoCarrinho.quantidade)} ${ItemOptions.getLocalizedUnidadesMedidaAbreviada(context)[itemNoCarrinho.unidadeMedida] ?? itemNoCarrinho.unidadeMedida}'),
                          Text('${S.of(context).unit_price}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemNoCarrinho.precoUnitario)}'),
                          Text('${S.of(context).total_value}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemNoCarrinho.valorTotal)}'),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        // Se o item estiver no carrinho, usa os dados do carrinho
                        // Se não estiver, cria um novo ItemCompra com base no item selecionado
                        _gerenciarItemCompra(
                          item: itemNoCarrinho.itemId.isNotEmpty 
                            ? itemNoCarrinho 
                            : ItemCompra(
                                id: DateTime.now().toString(),
                                compraId: '',
                                itemId: item.id,
                                quantidade: 0,
                                precoUnitario: 0,
                                valorTotal: 0,
                                unidadeMedida: item.unidadeMedida,
                                propriedadeId: AppStateManager().activePropriedadeId!, // Preencha conforme necessário
                                produtorId: AppStateManager().activeProdutorId!,
                              ),
                        );
                      },
                    ),
                  ),
                );
              },
            );


          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Abre a tela de checkout e aguarda o resultado
          final dynamic result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return ComprasCheckoutFormScreen(
                  carrinho: widget.carrinho,
                  onUpdate: () {
                    Navigator.pop(context, true); // Retorna true quando finalizado
                  },
                );
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0); // Começa fora da tela à direita
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

          // Tratar os diferentes tipos de retorno
          if (result is Compra) {
            // Se o resultado for uma instância de Compra
            setState(() {
              // Realiza as ações necessárias com o resultado da compra
              print('Compra retornada: ${result.toMap()}');
              Navigator.of(context).pop(result); // Retorna a compra para a tela anterior
            });
          } else if (result is List<ItemCompra>) {
            // Se o resultado for uma lista de itens de compra
            setState(() {
              widget.carrinho.clear();
              widget.carrinho.addAll(result);
            });
          } else if (result == true) {
            // Se o resultado for `true`, indicando que a ação foi bem-sucedida
            setState(() {
              Navigator.of(context).pop(true); // Retorna true para a tela anterior
            });
          } else if (result == false) {
            // Se o resultado for `false`, indicando que a ação foi cancelada ou falhou
            setState(() {
            });
          } else {
            // Se o resultado for `null` ou inesperado
          }
        },
        child: const Icon(Icons.shopping_cart_checkout),
      ),
    );
  }
}
