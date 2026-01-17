import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:planejacampo/models/abastecimento_frota.dart';
import 'package:planejacampo/models/frota.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/models/operacao_rural.dart';
import 'package:planejacampo/models/compra.dart';
import 'package:planejacampo/models/item_compra.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/screens/agro/atividades_rurais_list_screen.dart';
import 'package:planejacampo/services/abastecimento_frota_service.dart';
import 'package:planejacampo/services/compra_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/item_compra_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/services/operacao_rural_service.dart';
import 'package:planejacampo/services/estoques/estoque_service.dart';
import 'package:planejacampo/screens/appbar/itens_list_screen.dart';
import 'package:planejacampo/screens/appbar/propriedades_list_screen.dart';
import 'package:planejacampo/screens/appbar/pessoas_list_screen.dart';
import 'package:planejacampo/screens/agro/operacoes_rurais_list_screen.dart';
import 'package:planejacampo/services/tipo_operacao_rural_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/meio_pagamento_options.dart';
import 'package:planejacampo/utils/conta_bancaria_options.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:intl/intl.dart';

class AbastecimentoFrotaFormScreen extends StatefulWidget {
  final AbastecimentoFrota? abastecimentoFrota;
  final Frota frota;
  final OperacaoRural? operacaoRural;

  const AbastecimentoFrotaFormScreen({
    Key? key,
    this.abastecimentoFrota,
    required this.frota,
    this.operacaoRural,
  }) : super(key: key);

  @override
  _AbastecimentoFrotaFormScreenState createState() => _AbastecimentoFrotaFormScreenState();
}

class _AbastecimentoFrotaFormScreenState extends State<AbastecimentoFrotaFormScreen> {
  // FormKey e Controllers Principais
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();

// No início da classe, altere a definição dos controllers
  final MoneyMaskedTextController _quantidadeController = FormatacaoUtil.getMaskedTextController(0);
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _unidadeMedidaController = TextEditingController();
  final TextEditingController _propriedadeController = TextEditingController();
  final TextEditingController _cmpAtualController = TextEditingController();
  final TextEditingController _operacaoController = TextEditingController();
  final TextEditingController _numeroParcelasController = TextEditingController(text: '1');

  // Controllers para Abastecimento Externo
  final TextEditingController _fornecedorController = TextEditingController();
  final MoneyMaskedTextController _valorTotalController = FormatacaoUtil.getMaskedTextController(0);
  final TextEditingController _valorUnitarioController = TextEditingController();

  // Keys para Tutorial
  final GlobalKey _identificacaoKey = GlobalKey();
  final GlobalKey _itemKey = GlobalKey();
  final GlobalKey _quantidadeKey = GlobalKey();
  final GlobalKey _fornecedorKey = GlobalKey();
  final GlobalKey _valorTotalKey = GlobalKey();
  final GlobalKey _pagamentoKey = GlobalKey();
  final GlobalKey _operacaoKey = GlobalKey();

  // Services
  final AbastecimentoFrotaService _abastecimentoService = AbastecimentoFrotaService();
  final ItemService _itemService = ItemService();
  final EstoqueService _estoqueService = EstoqueService();
  final ContaService _contaService = ContaService();
  final PessoaService _pessoaService = PessoaService();
  final PropriedadeService _propriedadeService = PropriedadeService();
  final CompraService _compraService = CompraService();
  final ItemCompraService _itemCompraService = ItemCompraService();
  final ContaPagarService _contaPagarService = ContaPagarService();
  final OperacaoRuralService _operacaoRuralService = OperacaoRuralService();
  final TipoOperacaoRuralService _tipoOperacaoRuralService = TipoOperacaoRuralService();

  // Variáveis de Estado
  late AbastecimentoFrota _currentAbastecimento;
  String? _selectedItemId;
  String _selectedPropriedadeId = '';
  String? _fornecedorId;
  String? _operacaoId;
  DateTime _data = DateTime.now();
  bool _externo = false;
  bool _hasChanges = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  bool _isExpanded = false;
  Object _returnObject = false;

  // Variáveis para Pagamento
  String _selectedMeioPagamento = 'Pix/TED';
  String? _selectedContaPagamentoCompra;
  List<Conta> _contas = [];
  bool _isLoadingContas = true;
  Map<String, String> _contaNomeToId = {};

  // Focus Nodes
  final FocusNode _quantidadeFocusNode = FocusNode();
  final FocusNode _valorTotalFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit('frotas');
    _canDelete = appStateManager.canDelete('frotas');
    _showTutorial = appStateManager.showTutorial('abastecimentoFrotaFormScreen');
    appStateManager.setShowTutorial('abastecimentoFrotaFormScreen', false);

    _initializeData();
    _carregarContas();
  }

  void _initializeData() {
    if (widget.abastecimentoFrota != null) {
      _initializeExistingAbastecimento();
    } else {
      _initializeNewAbastecimento();
    }
  }

  void _initializeExistingAbastecimento() {
    _currentAbastecimento = widget.abastecimentoFrota!;
    _numeroParcelasController.text = (_currentAbastecimento.numeroParcelas ?? 1).toString();
    _selectedContaPagamentoCompra = _currentAbastecimento.contaId;

    setState(() {
      _selectedItemId = _currentAbastecimento.itemId;
      _selectedPropriedadeId = _currentAbastecimento.propriedadeId;
      _data = _currentAbastecimento.data;
      _externo = _currentAbastecimento.externo;
      _operacaoId = _currentAbastecimento.operacaoRuralId;

      _dataController.text = FormatacaoUtil.formatDate(_data);
      _quantidadeController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(_currentAbastecimento.quantidadeUtilizada);
      _valorTotalController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(_currentAbastecimento.valorTotal ?? 0);
      _unidadeMedidaController.text = _currentAbastecimento.unidadeMedida;
      _cmpAtualController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(_currentAbastecimento.cmpAtual);

      // Se for abastecimento externo, carrega dados da compra
      if (_externo && _currentAbastecimento.compraId != null) {
        _carregarDadosCompra(_currentAbastecimento.compraId!);
      }

      _loadItemDetails();
      _loadPropriedadeDetails();
      _loadOperacaoDetails();
    });
  }

  void _carregarContas() async {
    try {
      final produtorId = Provider.of<AppStateManager>(context, listen: false).activeProdutorId!;
      List<Conta> contas = await ContaBancariaOptions.buscarContasBancarias(_contaService, produtorId);

      setState(() {
        _contas = contas;
        _isLoadingContas = false;
        _contaNomeToId = {
          for (var conta in _contas) conta.nome: conta.id,
        };

        // Selecionar conta padrão para o meio de pagamento, se estiver criando um novo abastecimento
        if (widget.abastecimentoFrota == null && _externo) {
          _selecionarContaPadraoParaMeioPagamento();
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

// Novo método para selecionar conta padrão para o meio de pagamento
  void _selecionarContaPadraoParaMeioPagamento() {
    if (_selectedMeioPagamento != null && MeioPagamentoOptions.requiresContaPagamento(_selectedMeioPagamento)) {
      final contasDisponiveis = _contas.where(
              (conta) => ContaBancariaOptions.isContaAllowedForPagamento(_selectedMeioPagamento, conta)
      ).toList();

      if (contasDisponiveis.isNotEmpty) {
        _selectedContaPagamentoCompra = contasDisponiveis.first.id;
      }
    }
  }

  void _initializeNewAbastecimento() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);

    _currentAbastecimento = AbastecimentoFrota(
      id: DateTime.now().toString(),
      produtorId: appStateManager.activeProdutorId!,
      propriedadeId: appStateManager.activePropriedadeId!,
      frotaId: widget.frota.id,
      itemId: '',
      data: _data,
      quantidadeUtilizada: 0,
      unidadeMedida: '',
      cmpAtual: 0,
      unidadeMedidaCMP: '',
      tipoMovimentacaoEstoque: 'Saida',
      categoriaMovimentacaoEstoque: 'Consumo',
      externo: false,
    );

    setState(() {
      _selectedPropriedadeId = appStateManager.activePropriedadeId!;
      _dataController.text = FormatacaoUtil.formatDate(_data);

      // Se recebeu operação como parâmetro
      if (widget.operacaoRural != null) {
        _operacaoId = widget.operacaoRural!.id;
        _operacaoController.text = widget.operacaoRural!.descricao ?? '';
      }
    });

    _loadPropriedadeDetails();

    // Se as contas já foram carregadas e estamos em abastecimento externo, seleciona conta padrão
    if (!_isLoadingContas && _externo) {
      _selecionarContaPadraoParaMeioPagamento();
    }
  }

  Future<void> _carregarDadosCompra(String compraId) async {
    try {
      final compra = await _compraService.getById(compraId);
      if (compra != null) {
        // Carrega fornecedor
        if (compra.fornecedorId.isNotEmpty) {
          final fornecedor = await _pessoaService.getById(compra.fornecedorId);
          if (fornecedor != null) {
            _fornecedorId = fornecedor.id;
            _fornecedorController.text = fornecedor.nome;
          }
        }

        // Carrega item compra
        final itensCompra = await _itemCompraService.getByAttributes({'compraId': compraId});
        if (itensCompra.isNotEmpty) {
          final itemCompra = itensCompra.first;
          _valorTotalController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemCompra.valorTotal);
          _valorUnitarioController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(itemCompra.precoUnitario);
        }

        // Carrega contas a pagar
        final contasPagar = await _contaPagarService.getByAttributes({
          'origemId': compraId,
          'origemTipo': 'compras',
        });

        if (contasPagar.isNotEmpty) {
          final contaPagar = contasPagar.first;
          _selectedMeioPagamento = contaPagar.meioPagamento ?? 'Pix/TED';

          // Carregar número de parcelas
          if (contaPagar.totalParcelas != null) {
            _numeroParcelasController.text = contaPagar.totalParcelas.toString();
          }

          // Atribuir contaId ao _selectedContaPagamentoCompra
          _selectedContaPagamentoCompra = contaPagar.contaId;

          // Aguardar carregamento das contas para garantir seleção correta
          if (_isLoadingContas) {
            await Future.doWhile(() async {
              await Future.delayed(Duration(milliseconds: 100));
              return _isLoadingContas;
            });
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar dados da compra: $e');
    }
  }

  void _loadItemDetails() async {
    if (_selectedItemId != null && _selectedItemId!.isNotEmpty) {
      final item = await _itemService.getById(_selectedItemId!);
      if (item != null && mounted) {
        setState(() {
          _itemController.text = item.nome;
          if (widget.abastecimentoFrota == null) {
            _unidadeMedidaController.text = item.unidadeMedida;
          }
          _hasChanges = true;
        });
        _updateCMPAtual();
      }
    }
  }

  void _loadPropriedadeDetails() async {
    if (_selectedPropriedadeId.isNotEmpty) {
      final propriedade = await _propriedadeService.getById(_selectedPropriedadeId);
      if (propriedade != null && mounted) {
        setState(() {
          _propriedadeController.text = propriedade.nome;
          _hasChanges = true;
        });
      }
    }
  }

  void _loadOperacaoDetails() async {
    if (_operacaoId != null && _operacaoId!.isNotEmpty) {
      final operacao = await _operacaoRuralService.getById(_operacaoId!);
      if (operacao != null && mounted) {
        setState(() {
          _operacaoController.text = operacao.descricao ?? '';
          _hasChanges = true;
        });
      }
    }
  }

  void _selectItem() async {
    final selectedItem = await Navigator.push<Item>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ItensListScreen(
              isSelectMode: true,
              categoria: 'Combustível', // Alterado de tipoItem para categoria
            ),
      ),
    );

    if (selectedItem != null && mounted) {
      setState(() {
        _selectedItemId = selectedItem.id;
        _itemController.text = selectedItem.nome;
        _unidadeMedidaController.text = selectedItem.unidadeMedida;
        _hasChanges = true;
      });
      _updateCMPAtual();
    }
  }

  void _selectPropriedade() async {
    final selectedPropriedade = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropriedadesListScreen(isSelectMode: true),
      ),
    );

    if (selectedPropriedade != null && mounted) {
      setState(() {
        _selectedPropriedadeId = selectedPropriedade.id;
        _propriedadeController.text = selectedPropriedade.nome;
        _hasChanges = true;
      });
      _updateCMPAtual();
    }
  }

  // No AbastecimentoFrotaFormScreen, atualize o método _selectOperacao():
  void _selectOperacao() async {
    AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    if (appStateManager.activeAtividadeRural == null) {
      final _atividadeRural = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AtividadesRuraisListScreen(
                isSelectMode: true,
                isSetMode: true,
              ),
        ),
      );
    }
    if (appStateManager.activeAtividadeRural != null) {
      final operacao = await Navigator.push<OperacaoRural>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OperacoesRuraisListScreen(
                atividadeId: appStateManager.activeAtividadeRural!.id,
                isSelectMode: true,
                isSetMode: false,
              ),
        ),
      );

      if (operacao != null && mounted) {
        // Carregar o tipo da operação
        final tipo = await _tipoOperacaoRuralService.getById(operacao.tipoOperacaoRuralId);
        String operacaoTexto = tipo?.nome ?? S
            .of(context)
            .unknown_type;

        if (operacao.descricao?.isNotEmpty ?? false) {
          operacaoTexto += ' - ${operacao.descricao}';
        }

        setState(() {
          _operacaoId = operacao.id;
          _operacaoController.text = operacaoTexto;
          _hasChanges = true;
        });
      }
    }
  }

  void _selecionarFornecedor() async {
    final fornecedor = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PessoasListScreen(
              isSelectMode: true,
              vinculos: ['Fornecedor'],
            ),
      ),
    );

    if (fornecedor != null && mounted) {
      setState(() {
        _fornecedorId = fornecedor.id;
        _fornecedorController.text = fornecedor.nome;
        _hasChanges = true;
      });
    }
  }

  void _updateCMPAtual() async {
    if (_selectedItemId != null && _selectedPropriedadeId.isNotEmpty) {
      final mapEstoqueAnterior = await _estoqueService.getEstoqueAnterior(
        propriedadeId: _selectedPropriedadeId,
        itemId: _selectedItemId!,
        dataReferencia: _data,
      );

      if (mapEstoqueAnterior.isNotEmpty && mounted) {
        String unidadeMedidaOrigem = mapEstoqueAnterior['unidadeMedidaCMP'];
        String unidadeMedidaDestino = _unidadeMedidaController.text;
        double cmpOriginal = mapEstoqueAnterior['cmp'];

        if (unidadeMedidaOrigem != unidadeMedidaDestino) {
          double valorConvertido = _estoqueService.converterUnidadeMedida(
            1.0,
            unidadeMedidaOrigem,
            unidadeMedidaDestino,
          );

          double cmpConvertido = cmpOriginal / valorConvertido;

          setState(() {
            _cmpAtualController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(cmpConvertido);
            _hasChanges = true;
          });
        } else {
          setState(() {
            _cmpAtualController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(cmpOriginal);
            _hasChanges = true;
          });
        }
      } else if (mounted) {
        setState(() {
          _cmpAtualController.text = '0.00';
          _hasChanges = true;
        });
      }
    }
  }

  void _calcularValorUnitario(String novoValorTotal) {
    if (novoValorTotal.isNotEmpty && _quantidadeController.text.isNotEmpty) {
      try {
        double valorTotal = FormatacaoUtil.instance.parseNumber(novoValorTotal);
        double quantidade = FormatacaoUtil.instance.parseNumber(_quantidadeController.text);

        if (quantidade > 0) {
          double valorUnitario = valorTotal / quantidade;
          setState(() {
            _valorUnitarioController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(valorUnitario);
            _hasChanges = true;
          });
        }
      } catch (e) {
        print('Erro ao calcular valor unitário: $e');
      }
    }
  }

  int _countContasForMeioPagamento(String meioPagamento) {
    return _contas
        .where((conta) => ContaBancariaOptions.isContaAllowedForPagamento(meioPagamento, conta))
        .length;
  }

  String _getContaNomeById(String? contaId) {
    if (contaId == null || contaId.isEmpty) return '-';
    try {
      return _contas
          .firstWhere((c) => c.id == contaId)
          .nome;
    } catch (e) {
      return '-';
    }
  }

  Conta? _findContaById(String? contaId) {
    if (contaId == null || contaId.isEmpty) return null;
    try {
      return _contas.firstWhere((c) => c.id == contaId);
    } catch (e) {
      return null;
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges ? _currentAbastecimento : _returnObject);
        return false;
      },
      child: FormTemplate(
        title: widget.abastecimentoFrota == null
            ? S
            .of(context)
            .add_refueling
            : S
            .of(context)
            .edit_refueling,
        formKey: _formKey,
        onSave: _salvarAbastecimento,
        moduleName: 'frotas',
        isNewItem: widget.abastecimentoFrota == null,
        canEdit: _canEdit,
        canDelete: _canDelete,
        showTutorial: _showTutorial,
        returnObject: _returnObject,
        onWillPop: () async => true,
        customTutorialSteps: _buildCustomTutorialSteps(),
        body: _buildFormBody(context),
      ),
    );
  }

  Widget _buildFormBody(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIdentificacaoSection(theme),
            SizedBox(height: 24),
            _buildItemSection(theme),
            SizedBox(height: 24),
            _buildQuantidadeSection(theme),
            if (_externo) ...[
              SizedBox(height: 24),
              _buildAbastecimentoExternoSection(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdentificacaoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment, color: theme.colorScheme.primary),
            SizedBox(width: 8),
            Text(
              S
                  .of(context)
                  .identification,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Data
        TextFormField(
          controller: _dataController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S
                .of(context)
                .date,
            suffixIcon: Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _data,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              setState(() {
                _data = pickedDate;
                _dataController.text = FormatacaoUtil.formatDate(pickedDate);
                _hasChanges = true;
              });
              _updateCMPAtual();
            }
          },
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return S
                  .of(context)
                  .select_date;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Operação (opcional)
        TextFormField(
          key: _operacaoKey,
          controller: _operacaoController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S
                .of(context)
                .rural_operation,
            suffixIcon: Icon(Icons.agriculture),
          ),
          readOnly: true,
          onTap: _selectOperacao,
        ),
        SizedBox(height: 16),

        // Propriedade
        TextFormField(
          controller: _propriedadeController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S
                .of(context)
                .stock_property,
            suffixIcon: Icon(Icons.business),
          ),
          readOnly: true,
          onTap: _selectPropriedade,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return S
                  .of(context)
                  .select_stock_property;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Switch para abastecimento externo
        // No SwitchListTile, modifique o onChanged:
        SwitchListTile(
          title: Text(S.of(context).external_refueling),
          value: _externo,
          onChanged: (bool value) {
            setState(() {
              _externo = value;
              _hasChanges = true;

              // Se ativar o abastecimento externo, seleciona a conta padrão
              if (value && !_isLoadingContas) {
                _selecionarContaPadraoParaMeioPagamento();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildItemSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_gas_station, color: theme.colorScheme.primary),
            SizedBox(width: 8),
            Text(
              S
                  .of(context)
                  .item,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Item (Combustível)
        TextFormField(
          key: _itemKey,
          controller: _itemController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S
                .of(context)
                .item,
            suffixIcon: Icon(Icons.search),
          ),
          readOnly: true,
          enabled: widget.abastecimentoFrota?.itemId == null,
          onTap: widget.abastecimentoFrota?.itemId != null ? null : _selectItem,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return S
                  .of(context)
                  .please_select_item;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Unidade de Medida
        TextFormField(
          controller: _unidadeMedidaController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S
                .of(context)
                .unit_of_measure,
            suffixIcon: Icon(Icons.straighten),
          ),
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildQuantidadeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.scale, color: theme.colorScheme.primary),
            SizedBox(width: 8),
            Text(
              S
                  .of(context)
                  .quantity_and_weight,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Quantidade
        TextFormField(
          key: _quantidadeKey,
          controller: _quantidadeController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S
                .of(context)
                .quantity,
            suffixIcon: Icon(Icons.monitor_weight),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            if (_externo) {
              _calcularValorUnitario(_valorTotalController.text);
            }
            _hasChanges = true;
          },
          validator: (value) {
            if (value?.isEmpty ?? true || FormatacaoUtil.instance.parseNumber(value!) <= 0) {
              return S
                  .of(context)
                  .please_enter_valid_number;
            }
            return null;
          },
        ),

        if (!_externo) ...[
          SizedBox(height: 16),

          // CMP
          TextFormField(
            controller: _cmpAtualController,
            decoration: ObjectTemplate.getInputDecoration(
              context,
              S
                  .of(context)
                  .cmp,
              suffixIcon: Icon(Icons.attach_money),
            ),
            readOnly: true,
            enabled: false,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAbastecimentoExternoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments, color: theme.colorScheme.primary),
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

        // Fornecedor
        TextFormField(
          key: _fornecedorKey,
          controller: _fornecedorController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).supplier,
            suffixIcon: Icon(Icons.person_search),
          ),
          readOnly: true,
          onTap: _selecionarFornecedor,
          validator: (value) {
            if (_externo && (value?.isEmpty ?? true)) {
              return S.of(context).supplier_required;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Valor Total
        TextFormField(
          key: _valorTotalKey,
          controller: _valorTotalController,
          focusNode: _valorTotalFocusNode,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).total_value,
            suffixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _calcularValorUnitario(value);
            _hasChanges = true;
          },
          validator: (value) {
            if (_externo && (value?.isEmpty ?? true || FormatacaoUtil.instance.parseNumber(value!) <= 0)) {
              return S.of(context).please_enter_valid_number;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Valor Unitário (calculado)
        TextFormField(
          controller: _valorUnitarioController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).unit_price,
            suffixIcon: Icon(Icons.attach_money),
          ),
          readOnly: true,
          enabled: false,
        ),
        SizedBox(height: 16),

        // Número de Parcelas
        ObjectTemplate.getDropdownButtonFormField(
          context: context,
          labelText: S.of(context).number_of_installments,
          value: _numeroParcelasController.text,
          items: List.generate(12, (index) => (index + 1).toString()),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _numeroParcelasController.text = newValue;
                _hasChanges = true;
              });
            }
          },
          suffixIcon: Icon(Icons.format_list_numbered),
        ),
        SizedBox(height: 16),

        // Forma de Pagamento
        // Forma de Pagamento
        ObjectTemplate.getDropdownButtonFormField(
          context: context,
          labelText: S.of(context).payment_method,
          value: MeioPagamentoOptions.getLocalizedMeiosDePagamento(context)[_selectedMeioPagamento] ?? '',
          items: MeioPagamentoOptions.getLocalizedMeiosDePagamentoString(context),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                final oldMeioPagamento = _selectedMeioPagamento;
                _selectedMeioPagamento = MeioPagamentoOptions
                    .getLocalizedMeiosDePagamento(context)
                    .entries
                    .firstWhere((entry) => entry.value == newValue)
                    .key;

                // Verifica se o novo meio de pagamento requer conta
                if (MeioPagamentoOptions.requiresContaPagamento(_selectedMeioPagamento)) {
                  // Tenta encontrar uma conta padrão para o novo meio de pagamento
                  final contasDisponiveis = _contas.where(
                          (conta) => ContaBancariaOptions.isContaAllowedForPagamento(_selectedMeioPagamento, conta)
                  ).toList();

                  if (contasDisponiveis.isNotEmpty) {
                    _selectedContaPagamentoCompra = contasDisponiveis.first.id;
                  } else {
                    _selectedContaPagamentoCompra = null;
                  }
                } else {
                  // Se não requer conta, limpa a seleção
                  _selectedContaPagamentoCompra = null;
                }

                _hasChanges = true;
              });
            }
          },
          validator: (value) {
            if (_externo && (value == null || value.isEmpty)) {
              return S.of(context).select_payment_method;
            }
            return null;
          },
        ),

        // Meio de Pagamento (Condicional)
        if (_externo && MeioPagamentoOptions.requiresContaPagamento(_selectedMeioPagamento) &&
            _countContasForMeioPagamento(_selectedMeioPagamento) > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ObjectTemplate.getDropdownButtonFormField(
              context: context,
              labelText: S.of(context).payment_account,
              value: _selectedContaPagamentoCompra != null
                  ? _getContaNomeById(_selectedContaPagamentoCompra)
                  : null,
              items: ContaBancariaOptions.getAllowedContaBancariaNames(_selectedMeioPagamento, _contas),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedContaPagamentoCompra = _contaNomeToId[newValue];
                    _hasChanges = true;
                  });
                }
              },
              validator: (value) {
                if (_externo && MeioPagamentoOptions.requiresContaPagamento(_selectedMeioPagamento) &&
                    (value == null || value.isEmpty)) {
                  return S.of(context).payment_account_required;
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  Future<void> _salvarAbastecimento() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Apenas constrói o objeto atualizado sem persistir
        _currentAbastecimento = _currentAbastecimento.copyWith(
          itemId: _selectedItemId,
          propriedadeId: _selectedPropriedadeId,
          data: _data,
          quantidadeUtilizada: FormatacaoUtil.instance.parseNumber(_quantidadeController.text),
          unidadeMedida: _unidadeMedidaController.text,
          cmpAtual: _externo
              ? FormatacaoUtil.instance.parseNumber(_valorUnitarioController.text)
              : FormatacaoUtil.instance.parseNumber(_cmpAtualController.text),
          unidadeMedidaCMP: _unidadeMedidaController.text,
          operacaoRuralId: _operacaoId,
          externo: _externo,
          fornecedorId: _fornecedorId,
          valorTotal: _externo ? FormatacaoUtil.instance.parseNumber(_valorTotalController.text) : null,
          meioPagamento: _externo ? _selectedMeioPagamento : null,
          contaId: _externo ? _selectedContaPagamentoCompra : null,
          numeroParcelas: _externo ? int.tryParse(_numeroParcelasController.text) ?? 1 : null,
        );

        Navigator.of(context).pop(_currentAbastecimento);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_saving_refueling(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    Map<String, Map<String, dynamic>> steps = {
      'customIdentificacao': {
        'key': _identificacaoKey,
        'message': S
            .of(context)
            .identification,
        'shape': 'RRect',
      },
      'customItem': {
        'key': _itemKey,
        'message': S
            .of(context)
            .select_item,
        'shape': 'RRect',
      },
      'customQuantidade': {
        'key': _quantidadeKey,
        'message': S
            .of(context)
            .quantity_used,
        'shape': 'RRect',
      },
      'customOperacao': {
        'key': _operacaoKey,
        'message': S
            .of(context)
            .rural_operation,
        'shape': 'RRect',
      },
    };

    if (_externo) {
      steps.addAll({
        'customFornecedor': {
          'key': _fornecedorKey,
          'message': S
              .of(context)
              .supplier_required,
          'shape': 'RRect',
        },
        'customValorTotal': {
          'key': _valorTotalKey,
          'message': S
              .of(context)
              .total_value,
          'shape': 'RRect',
        },
      });
    }

    return steps;
  }

  @override
  void dispose() {
    // Dispose dos controllers
    _itemController.dispose();
    _quantidadeController.dispose();
    _dataController.dispose();
    _unidadeMedidaController.dispose();
    _propriedadeController.dispose();
    _cmpAtualController.dispose();
    _operacaoController.dispose();
    _fornecedorController.dispose();
    _valorTotalController.dispose();
    _valorUnitarioController.dispose();

    // Dispose dos focus nodes
    _quantidadeFocusNode.dispose();
    _valorTotalFocusNode.dispose();

    super.dispose();
  }
}