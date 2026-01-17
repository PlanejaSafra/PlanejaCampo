// lancamentos_contabeis_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/models/contabil/lancamento_contabil.dart';
import 'package:planejacampo/utils/pagamento_options.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:provider/provider.dart';

import 'lancamento_contabil_form_screen.dart';
import 'lancamento_contabil_screen.dart';

class LancamentosContabeisListScreen extends StatefulWidget {
  final bool isSelectMode;
  final String? contaContabilFilter;
  final DateTime? periodoInicio;
  final DateTime? periodoFim;

  const LancamentosContabeisListScreen({
    Key? key,
    this.isSelectMode = false,
    this.contaContabilFilter,
    this.periodoInicio,
    this.periodoFim,
  }) : super(key: key);

  @override
  _LancamentosContabeisListScreenState createState() => _LancamentosContabeisListScreenState();
}

class _LancamentosContabeisListScreenState extends State<LancamentosContabeisListScreen>
    with SingleTickerProviderStateMixin {

  final String _moduleName = 'contabil';
  final LancamentoContabilService _lancamentoService = LancamentoContabilService();
  final ContaContabilService _contaContabilService = ContaContabilService();

  late Future<List<LancamentoContabil>> _lancamentosFuture;
  Object _returnObject = false;
  bool _showTutorial = false;

  // Filtros
  String? _contaContabilSelecionada;
  DateTime _dataInicio = DateTime.now().subtract(Duration(days: 30));
  DateTime _dataFim = DateTime.now();
  String _tipoFiltro = 'todos'; // 'todos', 'debito', 'credito'

  // Mapas para cache
  Map<String, String> _nomesContas = {};
  Map<String, ContaContabil> _contasDetalhes = {};

  // Tabs
  final List<String> _filterOptions = ['todos', 'debito', 'credito', 'automatico', 'manual'];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _contaContabilSelecionada = widget.contaContabilFilter;
    if (widget.periodoInicio != null) _dataInicio = widget.periodoInicio!;
    if (widget.periodoFim != null) _dataFim = widget.periodoFim!;

    _loadLancamentos();

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('lancamentosContabeisListScreen');
    appStateManager.setShowTutorial('lancamentosContabeisListScreen', false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging ||
        _tabController.index != _filterOptions.indexOf(_tipoFiltro)) {
      setState(() {
        _tipoFiltro = _filterOptions[_tabController.index];
        _loadLancamentos();
      });
    }
  }

  void _loadLancamentos() {
    setState(() {
      _lancamentosFuture = _getFilteredLancamentos();
    });
  }

  Future<List<LancamentoContabil>> _getFilteredLancamentos() async {
    Map<String, List<Map<String, dynamic>>> filters = {
      'data': [
        {'value': _dataInicio, 'operator': '>='},
        {'value': _dataFim, 'operator': '<='}
      ],
      'ativo': [
        {'value': true, 'operator': '=='}
      ],
    };

    if (_contaContabilSelecionada != null) {
      filters['contaContabilId'] = [
        {'value': _contaContabilSelecionada, 'operator': '=='}
      ];
    }

    if (_tipoFiltro == 'debito' || _tipoFiltro == 'credito') {
      filters['tipo'] = [
        {'value': _tipoFiltro, 'operator': '=='}
      ];
    } else if (_tipoFiltro == 'automatico') {
      filters['origemTipo'] = [
        {'value': 'manual', 'operator': '!='}
      ];
    } else if (_tipoFiltro == 'manual') {
      filters['origemTipo'] = [
        {'value': 'manual', 'operator': '=='}
      ];
    }

    final lancamentos = await _lancamentoService.getByAttributesWithOperators(
      filters,
      orderBy: [
        {'field': 'data', 'direction': 'desc'},
        {'field': 'timestamp', 'direction': 'desc'}
      ],
    );

    await _carregarDadosRelacionados(lancamentos);
    return lancamentos;
  }

  Future<void> _carregarDadosRelacionados(List<LancamentoContabil> lancamentos) async {
    for (var lancamento in lancamentos) {
      if (!_nomesContas.containsKey(lancamento.contaContabilId)) {
        final conta = await _contaContabilService.getById(lancamento.contaContabilId);
        if (conta != null) {
          _nomesContas[lancamento.contaContabilId] = conta.nome;
          _contasDetalhes[lancamento.contaContabilId] = conta;
        }
      }
    }
  }

  void _refreshLancamentos() {
    _returnObject = true;
    _nomesContas.clear();
    _contasDetalhes.clear();
    _loadLancamentos();
  }

  Future<void> _mostrarFiltros() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFiltrosSheet(),
    );
  }

  Widget _buildFiltrosSheet() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).filters,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),

          // Filtro de Conta
          ListTile(
            title: Text(S.of(context).account),
            subtitle: Text(_contaContabilSelecionada != null
                ? _nomesContas[_contaContabilSelecionada] ?? S.of(context).all
                : S.of(context).all),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              // TODO: Implementar seleção de conta
            },
          ),

          // Filtro de Período
          ListTile(
            title: Text(S.of(context).period),
            subtitle: Text(
                '${FormatacaoUtil.formatDate(_dataInicio)} - ${FormatacaoUtil.formatDate(_dataFim)}'
            ),
            trailing: Icon(Icons.calendar_today, size: 16),
            onTap: () async {
              // TODO: Implementar seleção de período
            },
          ),

          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _contaContabilSelecionada = null;
                    _dataInicio = DateTime.now().subtract(Duration(days: 30));
                    _dataFim = DateTime.now();
                  });
                  Navigator.pop(context);
                  _loadLancamentos();
                },
                child: Text(S.of(context).clear_filters),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadLancamentos();
                },
                child: Text(S.of(context).apply),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTipoColor(String tipo, ThemeData theme) {
    return tipo == 'Debito'
        ? Colors.red.shade700
        : Colors.green.shade700;
  }

  IconData _getTipoIcon(String tipo) {
    return tipo == 'Debito' ? Icons.arrow_upward : Icons.arrow_downward;
  }

  String _getTipoLabel(String tipo) {
    return tipo == 'Debito' ? S.of(context).debit : S.of(context).credit;
  }

  String _getOrigemLabel(LancamentoContabil lancamento) {
    if (lancamento.origemTipo == 'manual') {
      return S.of(context).manual_entry;
    }

    // Mapear tipos de origem para labels amigáveis
    final origensMap = {
      'contasPagar': S.of(context).account_payable,
      'compras': S.of(context).purchase,
      'vendas': S.of(context).sale,
      'operacoes': S.of(context).rural_operations,
    };

    return origensMap[lancamento.origemTipo] ?? lancamento.origemTipo;
  }

  String _getLocalizedFormaPagamento(String? formaPagamento) {
    if (formaPagamento == null || formaPagamento.isEmpty) {
      return S.of(context).not_found;
    }

    final localizedMap = PagamentoOptions.getLocalizedFormasDePagamento(context);
    return localizedMap[formaPagamento] ?? formaPagamento;
  }

  String _localizarDescricao(String? descricao) {
    if (descricao == null || descricao.isEmpty) {
      return '';
    }

    // Localiza as formas de pagamento na descrição
    String descricaoLocalizada = descricao;
    final localizedMap = PagamentoOptions.getLocalizedFormasDePagamento(context);

    localizedMap.forEach((chave, valorLocalizado) {
      descricaoLocalizada = descricaoLocalizada.replaceAll(chave, valorLocalizado);
    });

    return descricaoLocalizada;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppStateManager().appLocale.toString();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

    final tabBar = PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
          indicatorColor: theme.colorScheme.primary,
          tabs: _filterOptions.map((filter) {
            return Tab(
              child: Text(_getFilterLabel(filter)),
            );
          }).toList(),
        ),
      ),
    );

    return ListTemplate<LancamentoContabil>(
      icon: Icons.receipt_long,
      future: _lancamentosFuture,
      serviceName: _lancamentoService,
      moduleName: _moduleName,
      title: S.of(context).accounting_entries,
      appBarBottom: tabBar,

      itemTitleBuilder: (lancamento) {
        final nomeConta = _nomesContas[lancamento.contaContabilId] ??
            S.of(context).loading;
        return nomeConta;
      },

      itemSubtitleBuilder: (lancamento) {
        final conta = _contasDetalhes[lancamento.contaContabilId];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Valor com ícone e tipo
            Row(
              children: [
                Icon(
                  _getTipoIcon(lancamento.tipo),
                  size: 16,
                  color: _getTipoColor(lancamento.tipo, theme),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(lancamento.valor)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _getTipoColor(lancamento.tipo, theme),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),

            // Saldo após lançamento
            Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 14, color: theme.colorScheme.primary),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${S.of(context).balance}: $currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(lancamento.saldoAtual)}',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Data
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.primary),
                SizedBox(width: 4),
                Text(
                  FormatacaoUtil.formatDate(lancamento.data),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: 4),

            // Tipo do lançamento
            Row(
              children: [
                Icon(Icons.swap_vert, size: 14, color: theme.colorScheme.primary),
                SizedBox(width: 4),
                Text(
                  '${S.of(context).type}: ${_getTipoLabel(lancamento.tipo)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),

            // Código da conta
            if (conta != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.tag, size: 14, color: theme.colorScheme.primary),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${S.of(context).account_code}: ${conta.codigo}',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },

      itemExpandedContentWidgets: (lancamento) {
        final List<Widget> widgets = [];
        final conta = _contasDetalhes[lancamento.contaContabilId];

        widgets.add(
          Container(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).details,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),

                // Natureza da conta
                if (conta != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, size: 16, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${S.of(context).account_nature}: ${conta.natureza}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Origem
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.source, size: 16, color: theme.colorScheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${S.of(context).origin}: ${_getOrigemLabel(lancamento)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                // Descrição (se houver)
                if (lancamento.descricao != null && lancamento.descricao!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description, size: 16, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${S.of(context).description}: ${_localizarDescricao(lancamento.descricao)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Timestamp
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: theme.colorScheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${S.of(context).timestamp}: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(lancamento.timestamp)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lote (se houver)
                if (lancamento.loteId != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.group_work, size: 16, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${S.of(context).batch}: ${lancamento.loteId}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );

        return widgets;
      },

      itemLeadingIcon: Icons.receipt,

      cardDecoration: (lancamento) => BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTipoColor(lancamento.tipo, theme).withOpacity(0.3),
          width: 1.5,
        ),
      ),

      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_entries_found,
      onRefresh: _refreshLancamentos,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).accounting_entry,
      nomeTutorialPlural: S.of(context).accounting_entries,
      isSelectMode: widget.isSelectMode,
      viewScreenBuilder: (lancamento) => LancamentoContabilScreen(lancamento: lancamento!),
      formScreenBuilder: (lancamento) => LancamentoContabilFormScreen(lancamento: lancamento),
      onWillPop: () async => true,

    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'todos':
        return S.of(context).all;
      case 'debito':
        return S.of(context).debit;
      case 'credito':
        return S.of(context).credit;
      case 'automatico':
        return S.of(context).automatic;
      case 'manual':
        return S.of(context).manual;
      default:
        return filter;
    }
  }
}