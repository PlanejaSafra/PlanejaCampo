// ... outros imports
import 'package:flutter/material.dart';
import 'package:planejacampo/models/contabil/banco.dart';
import 'package:planejacampo/models/item_compra.dart';
import 'package:planejacampo/models/compra.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/services/compra_service.dart';
import 'package:planejacampo/services/contabil/banco_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/screens/appbar/pessoas_list_screen.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:flutter/services.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart'; // Import necessário para acessar as traduções
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/screens/appbar/itens_list_screen.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/utils/meio_pagamento_options.dart';
import 'package:planejacampo/utils/conta_bancaria_options.dart';
import 'package:planejacampo/screens/appbar/propriedades_list_screen.dart';
import 'package:planejacampo/screens/appbar/compra/item_compra_form_screen.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:collection/collection.dart';

class ComprasCheckoutFormScreen extends StatefulWidget {
  final List<ItemCompra> carrinho;
  final Compra? compra;
  final VoidCallback onUpdate;

  const ComprasCheckoutFormScreen({
    Key? key,
    required this.carrinho,
    this.compra,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _ComprasCheckoutFormScreenState createState() => _ComprasCheckoutFormScreenState();
}

class _ComprasCheckoutFormScreenState extends State<ComprasCheckoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fornecedorController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _valorTotalController = TextEditingController();
  final TextEditingController _numeroParcelasController = TextEditingController(text: '1');
  final TextEditingController propriedadeController = TextEditingController();
  final PessoaService _pessoaService = PessoaService();
  final CompraService _compraService = CompraService();
  final ContaPagarService _contaPagarService = ContaPagarService();
  final ScrollController _scrollController = ScrollController(); // Adicionado
  final FocusNode _fornecedorFocusNode = FocusNode(); // Adicionado
  final GlobalKey _itensCompraKey = GlobalKey();
  final GlobalKey _fornecedorKey = GlobalKey();
  final GlobalKey _dataKey = GlobalKey();
  final GlobalKey _valorTotalKey = GlobalKey();
  final GlobalKey _pagamentosSectionKey = GlobalKey();
  final GlobalKey _itensSectionKey = GlobalKey();
  final GlobalKey _addItemCompraKey = GlobalKey();
  final GlobalKey _addPaymentKey = GlobalKey();

  // **Novo GlobalKey para o campo Meio de Pagamento na Compra**
  final GlobalKey<FormFieldState> _meioPagamentoKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _contaPagamentoCompraKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _parcelasKey = GlobalKey<FormFieldState>();

  // **Variável de estado para armazenar o meio de pagamento selecionado na compra**
  String? _selectedContaPagamentoCompra;

  List<TextEditingController> _valorParcelasControllers = [];
  String _selectedMeioPagamento = 'Pix/TED';
  List<ContaPagar> _contasPagar = [];
  List<ItemCompra> _itensCompra = [];
  double _valorTotal = 0.0;
  bool _parcelasModificadas = false;
  bool _itensModificados = false; // Adicionado
  String? _fornecedorId; // Adicione esta variável
  bool _showTutorial = false;
  bool _isLoading = false; // Declaração do _isLoading na classe
  List<ItemCompra> _carrinhoLocal = [];
  bool _showAdditionalButtons = true;
  bool _isExpanded = false;
  Object _returnObject = false;
  List<Conta> _contas = [];
  bool _isLoadingContas = true;
  Map<String, String> _contaNomeToId = {};

  // Métodos de inicialização da aplicação.
  @override
  void initState() {
    super.initState();

    // Clona os itens do carrinho para a lista local
    _carrinhoLocal = List.from(widget.carrinho);

    // Verifica se deve exibir tutorial
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('comprasCheckoutFormScreen');
    appStateManager.setShowTutorial('comprasCheckoutFormScreen', false);

    // Carrega a lista de contas disponíveis (para popular combo de meios de pagamento)
    _carregarContas();

    // Caso haja uma compra existente, carrega seus dados
    if (widget.compra != null) {
      _dataController.text = FormatacaoUtil.formatDate(widget.compra!.data);

      if (widget.compra!.fornecedorId.isNotEmpty) {
        _carregarNomeFornecedor(widget.compra!.fornecedorId);
      }

      // Carrega contas a pagar já existentes para essa compra
      _carregarContasPagarExistentes(widget.compra!);

    } else {
      // Se for uma compra nova, define a data para hoje
      _dataController.text = FormatacaoUtil.formatDate(DateTime.now());
    }

    // Calcula o valor total inicial do carrinho
    _calcularValorTotal();

    // Se for uma nova compra com itens no carrinho, gera as parcelas
    if (widget.compra == null && _carrinhoLocal.isNotEmpty) {
      _gerarParcelas();
    }

  }


  // **Função Auxiliar para Contar Contas Disponíveis para um Tipo de Pagamento**
  int _countContasForMeioPagamento(String meioPagamento) {
    return _contas.where((conta) => ContaBancariaOptions.isContaAllowedForPagamento(meioPagamento, conta)).length;
  }

  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded; // Alterna o estado
    });
    return _isExpanded;
  }

  String getBancoName(String? bancoId) {
    // Implemente aqui sua lógica para obter o nome do banco.
    // Se você já tiver uma lista de bancos, procure pelo bancoId.
    return bancoId ?? '';
  }

  /// Novo método para buscar contas utilizando FormasDePagamentoOptions.buscarContas
  Future<void> _carregarContas() async {
    try {
      final ContaService contaService = ContaService();
      final produtorId = Provider.of<AppStateManager>(context, listen: false).activeProdutorId!;

      // Busca as contas permitidas para o produtor atual
      List<Conta> contas = await ContaBancariaOptions.buscarContasBancarias(contaService, produtorId);
      //print("listando contas - contas $contas, tamanho: ${contas.length}");
      setState(() {
        _contas = contas;
        _isLoadingContas = false;

        // Mapeia nome -> ID das contas
        _contaNomeToId = {
          for (var conta in _contas) conta.nome: conta.id,
        };

        // Se quiser inicializar contaPagamento das contasPagar existentes, faça algo como:
        for (int i = 0; i < _contasPagar.length; i++) {
          ContaPagar c = _contasPagar[i];
          if (MeioPagamentoOptions.requiresContaPagamento(c.meioPagamento)) {
            if (c.contaId == null || c.contaId!.isEmpty) {
              Conta? defaultConta = ContaBancariaOptions.getDefaultContaBancaria(c.meioPagamento, _contas);
              _contasPagar[i] = c.copyWith(contaId: defaultConta?.id);
            }
          } else {
            _contasPagar[i] = c.copyWith(contaId: null);
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingContas = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context).error_loading}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  String _getContaNomeById(String? contaId) {
    if (contaId == null || contaId.isEmpty) return '-';
    Conta? conta;
    try {
      conta = _contas.firstWhere((c) => c.id == contaId);
    } catch (e) {
      conta = null;
    }
    return conta?.nome ?? '-';
  }

  Conta? _findContaById(String? contaId) {
    if (contaId == null || contaId.isEmpty) return null;
    try {
      return _contas.firstWhere((c) => c.id == contaId);
    } catch (e) {
      return null;
    }
  }

  void _carregarNomeFornecedor(String fornecedorId) async {
    final fornecedor = await _pessoaService.getById(fornecedorId);
    if (fornecedor != null) {
      setState(() {
        _fornecedorId = fornecedor.id; // Armazena o ID do fornecedor
        _fornecedorController.text = fornecedor.nome; // Exibe o nome do fornecedor
      });
    }
  }

  void _selecionarFornecedor() async {
    //_carrinhoLocal = widget.carrinho;
    final fornecedor = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PessoasListScreen(isSelectMode: true, vinculos: ['Fornecedor']),
      ),
    );
    if (fornecedor != null) {
      setState(() {
        //widget.carrinho.clear();
        //widget.carrinho.addAll(_carrinhoLocal);
        _fornecedorId = fornecedor.id; // Armazena o ID do fornecedor
        _fornecedorController.text = fornecedor.nome; // Exibe o nome do fornecedor
      });
    }
  }

  void _carregarContasPagarExistentes(Compra compra) async {
     List<ContaPagar> contas = await _contaPagarService.getByAttributes({
       'origemId': compra.id,
       'origemTipo': 'compras'
     });
     setState(() {
         if (contas.isNotEmpty) {
           _contasPagar = contas;
           _numeroParcelasController.text = contas.length.toString();
           _initializeParcelasControllers();
         } else {
           _gerarParcelas();
         }
     });
  }

  void _initializeParcelasControllers() {
    // Limpa os controladores antigos
    _valorParcelasControllers.forEach((controller) => controller.dispose());

    // Cria novos controladores para cada pagamento existente
    _valorParcelasControllers = _contasPagar.map((conta) {
      final controller = TextEditingController(
        text: FormatacaoUtil.formatNumberWithTwoDecimalPlaces(conta.valor),
      );

      // Adiciona listener para detectar alterações manuais
      controller.addListener(() {
        _parcelasModificadas = true;
      });

      return controller;
    }).toList();
  }

  // Método para criação do formulário de compra.
  Widget _buildCompraFormSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seção de Identificação
        Row(
          children: [
            Icon(Icons.shopping_cart, color: theme.colorScheme.primary),
            SizedBox(width: 8),
            Text(
              S.of(context).identification,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Fornecedor
        TextFormField(
          key: _fornecedorKey,
          controller: _fornecedorController,
          readOnly: true,
          onTap: _selecionarFornecedor,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).supplier,
            suffixIcon: Icon(Icons.person_search),
          ),
        ),
        SizedBox(height: 16),

        // Data da Compra
        TextFormField(
          key: _dataKey,
          controller: _dataController,
          readOnly: true,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).date,
            suffixIcon: Icon(Icons.calendar_today),
          ),
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              setState(() {
                _dataController.text = FormatacaoUtil.formatDate(pickedDate);
                _gerarParcelas();
              });
            }
          },
        ),
        SizedBox(height: 16),

        // Valor Total
        TextFormField(
          key: _valorTotalKey,
          controller: _valorTotalController,
          readOnly: true,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).total_value,
            suffixIcon: Icon(Icons.attach_money),
          ),
        ),
        SizedBox(height: 24),

        // Seção de Pagamento
        Row(
          children: [
            Icon(Icons.payment, color: theme.colorScheme.primary),
            SizedBox(width: 8),
            Text(
              S.of(context).payment_details,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Tipo de Pagamento
        ObjectTemplate.getDropdownButtonFormField(
          key: _meioPagamentoKey,
          context: context,
          labelText: S.of(context).payment_method,
          value: MeioPagamentoOptions.getLocalizedMeiosDePagamento(context)[_selectedMeioPagamento] ?? '',
          items: MeioPagamentoOptions.getLocalizedMeiosDePagamentoString(context),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedMeioPagamento = MeioPagamentoOptions.getLocalizedMeiosDePagamento(context)
                    .entries
                    .firstWhere((entry) => entry.value == newValue)
                    .key;
                _selectedContaPagamentoCompra = null;
                _gerarParcelas();
              });
            }
          },
          suffixIcon: Icon(Icons.payment),
        ),
        SizedBox(height: 16),

        // Meio de Pagamento (Condicional)
        if (MeioPagamentoOptions.requiresContaPagamento(_selectedMeioPagamento) &&
            _countContasForMeioPagamento(_selectedMeioPagamento) > 1)
          Column(
            children: [
              ObjectTemplate.getDropdownButtonFormField(
                context: context,
                labelText: S.of(context).payment_account,
                value: _selectedContaPagamentoCompra,
                dropdownItems: _contas
                    .where((conta) =>
                    ContaBancariaOptions.isContaAllowedForPagamento(_selectedMeioPagamento, conta))
                    .map((conta) => DropdownMenuItem<String>(
                  value: conta.id,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (conta.bancoId != null && conta.bancoId!.isNotEmpty)
                          FutureBuilder<Banco?>(
                            future: BancoService().getById(conta.bancoId!),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Text(
                                  snapshot.data!.nome,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        Text(
                          conta.nome,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ))
                    .toList(),
                selectedItemBuilder: (BuildContext context) {
                  return _contas
                      .where((conta) =>
                      ContaBancariaOptions.isContaAllowedForPagamento(_selectedMeioPagamento, conta))
                      .map<Widget>((conta) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (conta.bancoId != null && conta.bancoId!.isNotEmpty)
                            FutureBuilder<Banco?>(
                              future: BancoService().getById(conta.bancoId!),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Flexible(
                                    child: Text(
                                      '${snapshot.data!.nome} - ',
                                      style: Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          Flexible(
                            child: Text(
                              conta.nome,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedContaPagamentoCompra = newValue;
                      _gerarParcelas();
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).payment_account_required;
                  }
                  return null;
                },
                suffixIcon: Icon(Icons.credit_card),
              ),
              SizedBox(height: 16),
            ],
          ),






        // Número de Parcelas
        ObjectTemplate.getDropdownButtonFormField(
          key: _parcelasKey,
          context: context,
          labelText: S.of(context).number_of_installments,
          value: _numeroParcelasController.text,
          items: List.generate(12, (index) => (index + 1).toString()),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _numeroParcelasController.text = newValue;
                _gerarParcelas();
              });
            }
          },
          suffixIcon: Icon(Icons.format_list_numbered),
        ),
      ],
    );
  }




  // Métodos para construção e gestão de itens da compra.
  CardSection _buildItensCompraSection() {
    final theme = Theme.of(context);
    return CardSection(
      key: _itensSectionKey,
      title: S.of(context).purchase_items,
      icon: Icons.shopping_basket,
      cards: _carrinhoLocal.map((itemCompra) =>
          FutureBuilder<Item?>(
            future: ItemService().getById(itemCompra.itemId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListTile(title: Text(S.of(context).loading));
              } else if (snapshot.hasError || !snapshot.hasData) {
                return ListTile(title: Text(S.of(context).not_found));
              }

              final item = snapshot.data!;
              return FutureBuilder<Propriedade?>(
                future: PropriedadeService().getById(itemCompra.propriedadeId),
                builder: (context, propriedadeSnapshot) {
                  if (propriedadeSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text(S.of(context).loading));
                  } else if (propriedadeSnapshot.hasError || !propriedadeSnapshot.hasData) {
                    return ListTile(title: Text(S.of(context).not_found));
                  }

                  final propriedade = propriedadeSnapshot.data!;
                  return ListTile(
                    title: Text('${S.of(context).item}: ${item.nome}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${S.of(context).quantity}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemCompra.quantidade)} ${ItemOptions.getLocalizedUnidadesMedidaAbreviada(context)[itemCompra.unidadeMedida] ?? itemCompra.unidadeMedida}'),
                        Text('${S.of(context).unit_price}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemCompra.precoUnitario)}'),
                        Text('${S.of(context).total_value}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemCompra.valorTotal)}'),
                        Text('${S.of(context).stock}: ${propriedade.nome}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _manageItemCompra(item: itemCompra);
                        } else if (value == 'delete') {
                          _deleteItemCompra(itemCompra);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                              S.of(context).edit,
                            style: theme.popupMenuTheme.textStyle,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                              S.of(context).delete,
                            style: theme.popupMenuTheme.textStyle,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
      ).toList(),
    );
  }

  void _manageItemCompra({ItemCompra? item}) async {
    // Abre a tela para adicionar ou editar o item
    final ItemCompra? novoItem = await showDialog<ItemCompra>(
      context: context,
      builder: (BuildContext context) {
        return ItemCompraFormScreen(
          itemCompra: item, // Passa o item a ser editado (pode ser nulo para novo item)
          propriedadeId: item?.propriedadeId ?? AppStateManager().activePropriedadeId, // Use o propriedadeId do item ou o selecionado
          onSave: (ItemCompra novoItem) {
            // Função de callback onSave atualizada
            setState(() {
              final index = _carrinhoLocal.indexWhere((i) => i.itemId == novoItem.itemId && i.propriedadeId == novoItem.propriedadeId);

              if (index != -1) {
                // Se o item já existe no carrinho, atualiza-o
                _carrinhoLocal[index] = novoItem;
              } else {
                // Se não existe, adiciona como novo item
                _carrinhoLocal.add(novoItem);
              }

              // Atualiza o carrinho e o estado de modificação
              widget.carrinho.clear();
              widget.carrinho.addAll(_carrinhoLocal);

              _itensModificados = true;
              _calcularValorTotal();
              _gerarParcelas();
            });
          },
        );
      },
    );
  }

  void _deleteItemCompra(ItemCompra item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).confirm_deletion),
        content: Text(S.of(context).confirm_deletion_message(S.of(context).item)),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(S.of(context).delete),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      setState(() {
        _itensModificados = true;
        _carrinhoLocal.remove(item);
        _calcularValorTotal(); // Atualiza o valor total
        _gerarParcelas();      // Recalcula as parcelas
      });
    }
  }


  // Métodos para construção e gestão de pagamentos/parcelas das compras.
  CardSection _buildPagamentosSection() {
    final theme = Theme.of(context);
    return CardSection(
      key: _pagamentosSectionKey,
      title: S.of(context).payment_details,
      icon: Icons.payment,
      cards: _contasPagar.map((conta) {
        return ListTile(
          title: Text(FormatacaoUtil.formatNumberWithTwoDecimalPlaces(conta.valor)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${S.of(context).due_date}: ${FormatacaoUtil.formatDate(conta.dataVencimento)}'),
              Text('${MeioPagamentoOptions.getLocalizedMeiosDePagamento(context)[conta.meioPagamento] ?? conta.meioPagamento}'),
              if (MeioPagamentoOptions.requiresContaPagamento(conta.meioPagamento))
                Text(_getContaNomeById(conta.contaId)),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _manageContaPagar(conta: conta);
              } else if (value == 'delete') {
                _deleteContaPagar(conta);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(
                  S.of(context).edit,
                  style: theme.popupMenuTheme.textStyle,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  S.of(context).delete,
                  style: theme.popupMenuTheme.textStyle,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _deleteContaPagar(ContaPagar conta) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).confirm_deletion),
        content: Text(S.of(context).confirm_deletion_message(S.of(context).payment)),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(S.of(context).delete),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      setState(() {
        _contasPagar.remove(conta);
        _parcelasModificadas = true;
      });
    }
  }

  Future<void> _manageContaPagar({ContaPagar? conta}) async {
    final isEditing = (conta != null);

    // Controladores para valor e data de vencimento
    final TextEditingController valorController =
    FormatacaoUtil.getMaskedTextController(isEditing ? conta!.valor : 0.0);
    final TextEditingController dataVencimentoController = TextEditingController(
        text: isEditing ? FormatacaoUtil.formatDate(conta!.dataVencimento) : '');

    // Listener para marcar alterações
    dataVencimentoController.addListener(() {
      _parcelasModificadas = true;
    });

    // Variáveis locais para a seleção de forma e meio de pagamento
    String selectetMeioPagamento =
    isEditing ? conta!.meioPagamento : _selectedMeioPagamento;
    Conta? selectedContaPagamento;
    int contasDisponiveis = _countContasForMeioPagamento(selectetMeioPagamento);

    if (isEditing && MeioPagamentoOptions.requiresContaPagamento(selectetMeioPagamento)) {
      selectedContaPagamento = await _findContaById(conta!.contaId);
    } else if (MeioPagamentoOptions.requiresContaPagamento(selectetMeioPagamento)) {
      if (contasDisponiveis == 1) {
        selectedContaPagamento =
            ContaBancariaOptions.getDefaultContaBancaria(selectetMeioPagamento, _contas);
      } else if (contasDisponiveis > 1) {
        selectedContaPagamento = null;
      }
    }
    // opcionalmente, obtenha o nome para exibição (não usado no novo dropdown)
    String? contaPagamentoNome = selectedContaPagamento?.nome;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? S.of(context).edit_description(S.of(context).payment)
                    : S.of(context).add_description(S.of(context).payment),
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Campo Valor
                      TextField(
                        controller: valorController,
                        decoration: ObjectTemplate.getInputDecoration(context, S.of(context).payment_value),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FormatacaoUtil.instance.decimalInputFormatter,
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Campo Data de Vencimento
                      TextField(
                        controller: dataVencimentoController,
                        decoration: ObjectTemplate.getInputDecoration(context, S.of(context).due_date),
                        readOnly: true,
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              dataVencimentoController.text = FormatacaoUtil.formatDate(pickedDate);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      // Dropdown Tipo de Pagamento (parcela)
                      ObjectTemplate.getDropdownButtonFormField(
                        context: context,
                        labelText: S.of(context).payment_method,
                        value: MeioPagamentoOptions.getLocalizedMeiosDePagamento(context)[selectetMeioPagamento] ?? '',
                        items: MeioPagamentoOptions.getLocalizedMeiosDePagamentoString(context),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setStateDialog(() {
                              selectetMeioPagamento = MeioPagamentoOptions
                                  .getLocalizedMeiosDePagamento(context)
                                  .entries
                                  .firstWhere((entry) => entry.value == newValue)
                                  .key;
                              _parcelasModificadas = true;
                              selectedContaPagamento = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      // Dropdown Meio de Pagamento (para a parcela)
                      if (MeioPagamentoOptions.requiresContaPagamento(selectetMeioPagamento) &&
                          _countContasForMeioPagamento(selectetMeioPagamento) > 1)
                        ObjectTemplate.getDropdownButtonFormField(
                          context: context,
                          labelText: S.of(context).payment_account,
                          value: selectedContaPagamento?.id,
                          dropdownItems: _contas
                              .where((conta) => ContaBancariaOptions.isContaAllowedForPagamento(selectetMeioPagamento, conta))
                              .map((conta) => DropdownMenuItem<String>(
                            value: conta.id,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (conta.bancoId != null && conta.bancoId!.isNotEmpty)
                                    FutureBuilder<Banco?>(
                                      future: BancoService().getById(conta.bancoId!),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data != null) {
                                          return Text(
                                            snapshot.data!.nome,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  Text(
                                    conta.nome,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ))
                              .toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return _contas
                                .where((conta) => ContaBancariaOptions.isContaAllowedForPagamento(selectetMeioPagamento, conta))
                                .map<Widget>((conta) {
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (conta.bancoId != null && conta.bancoId!.isNotEmpty)
                                      FutureBuilder<Banco?>(
                                        future: BancoService().getById(conta.bancoId!),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData && snapshot.data != null) {
                                            return Flexible(
                                              child: Text(
                                                '${snapshot.data!.nome} - ',
                                                style: Theme.of(context).textTheme.bodySmall,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    Flexible(
                                      child: Text(
                                        conta.nome,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList();
                          },
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setStateDialog(() {
                                selectedContaPagamento = _contas.firstWhere((c) => c.id == newValue);
                                _parcelasModificadas = true;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return S.of(context).payment_account_required;
                            }
                            return null;
                          },
                          suffixIcon: Icon(Icons.credit_card),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  child: Text(S.of(context).save),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );
      },
    );



    if (result ?? false) {
      setState(() {
        _parcelasModificadas = true;
        String locale = Localizations.localeOf(context).toString();
        double valor =
        NumberFormat.decimalPattern(locale).parse(valorController.text).toDouble();
        final dataVencimento =
        DateFormat('dd/MM/yyyy').parse(dataVencimentoController.text);

        if (isEditing) {
          final int index = _contasPagar.indexOf(conta!);
          if (index != -1) {
            _contasPagar[index] = conta.copyWith(
              valor: valor,
              dataVencimento: dataVencimento,
              meioPagamento: selectetMeioPagamento,
            );
          }
        } else {
          _contasPagar.add(
            ContaPagar(
              id: DateTime.now().toString(),
              produtorId: Provider.of<AppStateManager>(context, listen: false).activeProdutorId!,
              contaId: selectedContaPagamento?.id ?? '',
              valor: valor,
              valorPago: 0.0,
              status: 'aberto',
              dataEmissao: DateTime.now(),
              dataVencimento: dataVencimento,
              numeroDocumento: null,
              meioPagamento: selectetMeioPagamento,
              origemId: widget.compra?.id ?? '',
              origemTipo: 'compras',
              categoria: 'Compra',
              observacoes: null,
              ativo: true,
              fornecedorId: _fornecedorId,
            ),
          );
        }
      });
    }
  }


  // Métodos utilizados na gravação da compra
  void _calcularValorTotal() {
    _valorTotal = _carrinhoLocal.fold(0.0, (sum, item) => sum + item.valorTotal);
    _valorTotalController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(_valorTotal);
  }

  bool _listasDePagamentosIguais(List<ContaPagar> lista1, List<ContaPagar> lista2) {
    if (lista1.length != lista2.length) return false;
    for (int i = 0; i < lista1.length; i++) {
      if (lista1[i].valor != lista2[i].valor ||
          lista1[i].dataVencimento != lista2[i].dataVencimento ||
          lista1[i].meioPagamento != lista2[i].meioPagamento ||
          lista1[i].contaId != lista2[i].contaId) {
        return false;
      }
    }
    return true;
  }

  Future<void> _gerarParcelas() async {
    await _carregarContas();

    int numParcelas = int.tryParse(_numeroParcelasController.text) ?? 1;
    if (numParcelas <= 0) numParcelas = 1;

    final valorParcela = _valorTotal / numParcelas;

    _valorParcelasControllers.forEach((controller) => controller.dispose());
    _valorParcelasControllers = [];

    final hasFaturamento = await MeioPagamentoOptions.requiresFaturamento(_selectedMeioPagamento);

    Conta? contaSelecionada;
    if (MeioPagamentoOptions.requiresContaPagamento(_selectedMeioPagamento)) {
      contaSelecionada = await ContaBancariaOptions.getDefaultContaBancaria(_selectedMeioPagamento, _contas);
      _selectedContaPagamentoCompra ??= contaSelecionada?.id;

      if (_selectedContaPagamentoCompra == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).no_valid_account_found),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }


    // Calcula as datas de vencimento baseadas na data da compra
    List<DateTime> datasVencimento = [];
    final dataCompra = DateFormat('dd/MM/yyyy').parse(_dataController.text);

    // Usa diretamente o método calcularDataVencimento para cada parcela
    for (int i = 0; i < numParcelas; i++) {
      // Passa o número da parcela correto (1-based) para manter a lógica original
      datasVencimento.add(ContaBancariaOptions.calcularDataVencimento(
        dataCompra,
        contaSelecionada,
        i + 1, // número da parcela (1-based)
        hasFaturamento,
      ));
    }

    final novasContas = List<ContaPagar>.generate(numParcelas, (i) {
      final controller = TextEditingController(
        text: FormatacaoUtil.formatNumberWithTwoDecimalPlaces(valorParcela),
      );
      _valorParcelasControllers.add(controller);

      String? contaId;
      if (MeioPagamentoOptions.requiresContaPagamento(_selectedMeioPagamento)) {
        final contasDisponiveis = _countContasForMeioPagamento(_selectedMeioPagamento);
        if (contasDisponiveis == 1) {
          contaId = contaSelecionada?.id;
        } else if (contasDisponiveis > 1) {
          contaId = _selectedContaPagamentoCompra;
        }
      }

      return ContaPagar(
        id: '',
        produtorId: Provider.of<AppStateManager>(context, listen: false).activeProdutorId!,
        contaId: contaId ?? '',
        valor: valorParcela,
        valorPago: 0.0,
        status: 'aberto',
        dataEmissao: dataCompra,
        dataVencimento: datasVencimento[i],
        numeroDocumento: null,
        meioPagamento: _selectedMeioPagamento,
        origemId: widget.compra?.id ?? '',
        origemTipo: 'compras',
        categoria: 'Compra',
        observacoes: null,
        ativo: true,
        fornecedorId: _fornecedorId,
      );
    });

    if (!_listasDeContasIguais(_contasPagar, novasContas)) {
      setState(() {
        _contasPagar = novasContas;
        _parcelasModificadas = true;
      });
    }
  }



  bool _listasDeContasIguais(List<ContaPagar> lista1, List<ContaPagar> lista2) {
    if (lista1.length != lista2.length) return false;
    for (int i = 0; i < lista1.length; i++) {
      if (lista1[i].valor != lista2[i].valor ||
          lista1[i].dataVencimento != lista2[i].dataVencimento ||
          lista1[i].meioPagamento != lista2[i].meioPagamento ||
          lista1[i].contaId != lista2[i].contaId) {
        return false;
      }
    }
    return true;
  }



  bool _validarTotalParcelas() {
    // Obtém o locale atual
    String locale = Localizations.localeOf(context).toString();

    // Inicializa o formatador de números baseado no locale
    NumberFormat formatador = NumberFormat.decimalPattern(locale);

    // Converte o valor total das parcelas para double usando a formatação correta
    double totalParcelas = _contasPagar.fold(0.0, (sum, conta) => sum + conta.valor);

    // Usa o formatador para analisar o valor total da compra corretamente
    double? valorTotal = formatador.parse(_valorTotalController.text).toDouble();

    // Calcula a diferença entre o valor total e o total das parcelas
    double difference = totalParcelas - valorTotal;

    // Verifica se a diferença é significativa (maior que 0.01)
    if (difference.abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).invalid_installments_total(FormatacaoUtil.formatNumberWithTwoDecimalPlaces(difference.abs())),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  void _finalizarCompra() async {
    if (_fornecedorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).supplier_required,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              // Adiciona uma verificação para garantir que o ScrollController está anexado
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0.0,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
              FocusScope.of(context).requestFocus(_fornecedorFocusNode);
            },
          ),
        ),
      );
      return;
    }

    // Validação: Garantir que todas as parcelas têm contaId válido
    if (_contasPagar.any((conta) =>
    MeioPagamentoOptions.requiresContaPagamento(conta.meioPagamento) &&
        (conta.contaId == ''))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, selecione um meio de pagamento válido para todas as parcelas.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Garantir que todas as parcelas tenham o fornecedorId
    if (_fornecedorId != null) {
      for (int i = 0; i < _contasPagar.length; i++) {
        _contasPagar[i] = _contasPagar[i].copyWith(fornecedorId: _fornecedorId);
      }
    }

    if (_formKey.currentState!.validate() && _validarTotalParcelas()) {
      final produtorId = Provider.of<AppStateManager>(context, listen: false).activeProdutor!.id;

      _calcularValorTotal();

      final DateTime dataCompra = DateFormat('dd/MM/yyyy').parse(_dataController.text);

      final compraAnterior = widget.compra;

      final Compra compraAtual = Compra(
        id: widget.compra?.id ?? DateTime.now().toString(),
        produtorId: produtorId,
        fornecedorId: _fornecedorId ?? '', // Use o ID do fornecedor aqui
        data: dataCompra,
        valorTotal: _valorTotal,
      );

      setState(() {
        _isLoading = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16.0),
                  Text(S.of(context).registering_purchase),
                ],
              ),
            ),
          );
        },
      );

      try {
        if (compraAnterior == null) {
          await _compraService.registrarCompra(compraAtual, _carrinhoLocal, _contasPagar);
        } else {
          // Verifica se a data foi alterada
          final dataOriginal = DateTime(
              compraAnterior.data.year,
              compraAnterior.data.month,
              compraAnterior.data.day
          );
          final dataNova = DateTime(
              compraAtual.data.year,
              compraAtual.data.month,
              compraAtual.data.day
          );

          // Se a data mudou, precisa atualizar os itens mesmo que eles não tenham sido modificados
          final bool dataAlterada = !dataNova.isAtSameMomentAs(dataOriginal);
          final bool precisaAtualizarItens = _itensModificados || dataAlterada;

          await _compraService.atualizarCompra(
            compraAnterior,
            compraAtual,
            _carrinhoLocal,
            _contasPagar,
            atualizarItensCompra: precisaAtualizarItens,
            atualizarPagamentosCompra: _parcelasModificadas,
          );
        }
        if (mounted) {
          setState(() {
            _carrinhoLocal.clear();
            _contasPagar.clear();
          });
          _returnObject = compraAtual;
          Navigator.of(context).pop(_returnObject); // Passa a compra atualizada e fecha a tela.
        }
      } finally {
        // Remova o diálogo e pop a tela
        if (mounted) {
          _returnObject = compraAtual;
          Navigator.of(context).pop(_returnObject); // Passa a compra atualizada e fecha a tela.
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormTemplate(
      title: widget.compra == null
          ? S.of(context).add_description(S.of(context).purchase)
          : S.of(context).edit_description(S.of(context).purchase),
      formKey: _formKey,
      onSave: _finalizarCompra,
      moduleName: 'compras',
      nomeTutorial: S.of(context).purchases,
      isNewItem: widget.compra == null,
      showTutorial: _showTutorial,
      returnObject: _returnObject,
      onWillPop: () async => true,
      customTutorialSteps: {
        'customFornecedorStep': {
          'key': _fornecedorKey,
          'message': S.of(context).click_to_select_supplier,
          'shape': 'RRect',
        },
        'customDataStep': {
          'key': _dataKey,
          'message': S.of(context).select_purchase_date,
          'shape': 'RRect',
        },
        'customValorTotalStep': {
          'key': _valorTotalKey,
          'message': S.of(context).total_value_of_purchase,
          'shape': 'RRect',
        },
        'customMeioPagamentoStep': {
          'key': _meioPagamentoKey,
          'message': S.of(context).select_payment_method,
          'shape': 'RRect',
        },
        if (_contaPagamentoCompraKey.currentState == 2)
          'customContaPagamentoCompraStep': {
            'key': _contaPagamentoCompraKey,
            'message': S.of(context).select_payment_account,
            'shape': 'RRect',
          },
        'customParcelasStep': {
          'key': _parcelasKey,
          'message': S.of(context).define_installments,
          'shape': 'RRect',
        },
        'customItensSectionStep': {
          'key': _itensSectionKey,
          'message': S.of(context).manage_items,
          'shape': 'RRect',
        },
        'customPagamentosSectionStep': {
          'key': _pagamentosSectionKey,
          'message': S.of(context).manage_payments,
          'align': 'ContentAlign.top',
          'shape': 'RRect',
        },
      },
      customActionTutorialSteps: {
        'addPayment': {
          'key': _addPaymentKey,
          'message': S.of(context).click_to_add_item,
          'shape': 'Circle',
          'align': 'ContentAlign.top',
        },
        'addItemCompra': {
          'key': _addItemCompraKey,
          'message': S.of(context).click_to_add_purchase,
          'shape': 'Circle',
          'align': 'ContentAlign.top',
        },
      },
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              _buildCompraFormSection(),
            ],
          ),
        ),
      ),
      cardSections: [
        _buildItensCompraSection(),
        _buildPagamentosSection(),
      ],
      additionalFloatingActionButtons: (context) => [
        ObjectTemplate.buildCustomFloatingActionButton(
          key: _addItemCompraKey,
          context: context,
          onPressed: () {
            setState(() {
              _toggleFloatingActionButton();
            });
            _manageItemCompra();
          },
          icon: Icons.add,
          text: S.of(context).add_item,
          toolTip: S.of(context).add_item,
          heroTag: 'addItemCompra',
        ),
        ObjectTemplate.buildCustomFloatingActionButton(
          key: _addPaymentKey,
          context: context,
          onPressed: () {
            setState(() {
              _toggleFloatingActionButton();
            });
            _manageContaPagar();
          },
          icon: Icons.add,
          text: S.of(context).add_description(S.of(context).payment),
          toolTip: S.of(context).add_description(S.of(context).payment),
          heroTag: 'addPayment',
        ),
      ],
      isExpanded: _isExpanded,
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
    );
  }
}
