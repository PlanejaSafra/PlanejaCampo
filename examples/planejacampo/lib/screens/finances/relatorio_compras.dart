import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/compra_service.dart';
import 'package:planejacampo/services/item_compra_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/models/compra.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/models/item_compra.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/themes/chart_theme.dart';
import 'package:planejacampo/themes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/screens/selecao_mes_ano_screen.dart';

class RelatorioComprasScreen extends StatefulWidget {
  const RelatorioComprasScreen({Key? key}) : super(key: key);

  @override
  _RelatorioComprasScreenState createState() => _RelatorioComprasScreenState();
}

class _RelatorioComprasScreenState extends State<RelatorioComprasScreen> {
  final String _moduleName = 'relatorioCompras';
  final CompraService _compraService = CompraService();
  final ItemCompraService _itemCompraService = ItemCompraService();
  final ContaPagarService _contaPagarService = ContaPagarService();
  final ContaService _contaService = ContaService();
  final ItemService _itemService = ItemService();

  late DateTime _selectedDate;
  late Future<Map<String, double>> _futureTotais;
  late Future<List<Map<String, dynamic>>> _futureTopGastosItens;

  // Novo Future para o segundo gráfico
  late Future<Map<String, double>> _futureAPagarContaPagamento;

  final GlobalKey _graficoBarraKey = GlobalKey();
  final GlobalKey _graficoAnelKey = GlobalKey();
  final GlobalKey _graficoAPagarContaPagamentoKey = GlobalKey(); // Nova chave para o segundo gráfico

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureTotais = _getTotaisMes(_selectedDate);
      _futureTopGastosItens = _getTopGastosItens(_selectedDate);
      _futureAPagarContaPagamento = _getAPagarPorContaPagamento(_selectedDate); // Carregar novo Future
    });
  }

  final List<Color> _graphColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.cyan,
    Colors.indigo,
    Colors.lime,
    Colors.amber,
    Colors.deepOrange,
    Colors.lightBlue,
  ];


  Future<Map<String, double>> _getTotaisMes(DateTime dataReferencia) async {
    final DateTime primeiroDia = DateTime(dataReferencia.year, dataReferencia.month, 1);
    final DateTime ultimoDia = DateTime(dataReferencia.year, dataReferencia.month + 1, 0);
    final String produtorId = Provider.of<AppStateManager>(context, listen: false).activeProdutorId!;

    double totalComprado = 0.0;
    double totalAPagar = 0.0;
    double totalCreditoFatura = 0.0;

    final compras = await _compraService.getByAttributesWithOperators({
      'produtorId': [{'operator': '==', 'value': produtorId}],
      'data': [
        {'operator': '>=', 'value': Timestamp.fromDate(primeiroDia)},
        {'operator': '<=', 'value': Timestamp.fromDate(ultimoDia)}
      ],
    });

    for (var compra in compras) {
      totalComprado += compra.valorTotal;
    }

    final contasPagar = await _contaPagarService.getByAttributes(
        {},
        attributesWithOperators: {
          'dataVencimento': [
            {'operator': '>=', 'value': Timestamp.fromDate(primeiroDia)},
            {'operator': '<=', 'value': Timestamp.fromDate(ultimoDia)}
          ]
        }
    );

    for (var contaPagar in contasPagar) {
      // Verifica se a data de vencimento está dentro do mês selecionado
      if (!contaPagar.dataVencimento.isBefore(primeiroDia) && !contaPagar.dataVencimento.isAfter(ultimoDia)) {
        // Se for cartão de crédito
        if (contaPagar.meioPagamento == 'Crédito' && contaPagar.contaId != null) {
          final conta = await _contaService.getById(contaPagar.contaId!);
          if (conta != null && conta.tipo == 'Crédito') {
            totalCreditoFatura += contaPagar.valor;
          }
        }
        totalAPagar += contaPagar.valor;
      }
    }


    return {
      'comprado': totalComprado,
      'aPagar': totalAPagar,
      'creditoFatura': totalCreditoFatura,
    };
  }


  // Novo método para obter total a pagar por meio de pagamento
  Future<Map<String, double>> _getAPagarPorContaPagamento(DateTime dataReferencia) async {
    final DateTime primeiroDia = DateTime(dataReferencia.year, dataReferencia.month, 1);
    final DateTime ultimoDia = DateTime(dataReferencia.year, dataReferencia.month + 1, 0);
    final String produtorId = Provider.of<AppStateManager>(context, listen: false).activeProdutorId!;

    Map<String, double> aPagarPorContaPagamento = {};

    final contasPagar = await _contaPagarService.getByAttributes(
        {},
        attributesWithOperators: {
          'produtorId': [{'operator': '==', 'value': produtorId}],
          'dataVencimento': [
            {'operator': '>=', 'value': Timestamp.fromDate(primeiroDia)},
            {'operator': '<=', 'value': Timestamp.fromDate(ultimoDia)}
          ]
        }
    );

    for (var contaPagar in contasPagar) {
      if (contaPagar.contaId != null) {
        final contaId = await _contaService.getById(contaPagar.contaId!);
        if (contaId != null) {
          aPagarPorContaPagamento.update(
            contaId.nome,
                (valor) => valor + contaPagar.valor,
            ifAbsent: () => contaPagar.valor,
          );
        }
      } else {
        aPagarPorContaPagamento.update(
          S.of(context).unknown_payment_account,
              (valor) => valor + contaPagar.valor,
          ifAbsent: () => contaPagar.valor,
        );
      }
    }


    return aPagarPorContaPagamento;
  }

  Future<List<Map<String, dynamic>>> _getTopGastosItens(DateTime date) async {
    final DateTime primeiroDia = DateTime(date.year, date.month, 1);
    final DateTime ultimoDia = DateTime(date.year, date.month + 1, 0);
    final String produtorId = Provider.of<AppStateManager>(context, listen: false).activeProdutorId!;

    final compras = await _compraService.getByAttributesWithOperators({
      'produtorId': [{'operator': '==', 'value': produtorId}],
      'data': [
        {'operator': '>=', 'value': Timestamp.fromDate(primeiroDia)},
        {'operator': '<=', 'value': Timestamp.fromDate(ultimoDia)}
      ],
    });

    Map<String, double> gastosPorItem = {};

    for (Compra compra in compras) {
      final itensCompra = await _itemCompraService.getByAttributes({'compraId': compra.id});
      for (ItemCompra itemCompra in itensCompra) {
        final item = await _itemService.getById(itemCompra.itemId);
        if (item != null) {
          gastosPorItem.update(item.nome, (valor) => valor + itemCompra.valorTotal, ifAbsent: () => itemCompra.valorTotal);
        }
      }
    }

    final topGastos = gastosPorItem.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    double outros = 0.0;
    List<Map<String, dynamic>> topItens = [];
    for (int i = 0; i < topGastos.length; i++) {
      if (i < 5) {
        topItens.add({
          'nome': topGastos[i].key,
          'valor': topGastos[i].value
        });
      } else {
        outros += topGastos[i].value;
      }
    }
    if (outros > 0) {
      topItens.add({'nome': S.of(context).others, 'valor': outros});
    }

    return topItens;
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).financial_report,
      moduleName: _moduleName,
      summarySection: _buildSummarySection(),
      serviceName: _compraService,
      itemIdValue: '',
      itemName: S.of(context).financial_report,
      fieldReference: '',
      returnObject: '',
      cardSections: [
        // Primeiro Gráfico: Total Comprado e Total a Pagar
        CardSection(
          title: S.of(context).monthly_expenses,
          key: _graficoBarraKey,
          cards: [_buildGraficoBarra()],
        ),
        // Segundo Gráfico: Total a Pagar por Meio de Pagamento
        CardSection(
          title: S.of(context).total_payments_by_account, // Adicione uma nova string de localização
          key: _graficoAPagarContaPagamentoKey,
          cards: [_buildGraficoAPagarContaPagamento()],
        ),
        CardSection(
          title: S.of(context).top_expenses,
          key: _graficoAnelKey,
          cards: [_buildGraficoAnel()],
        ),
      ],
      customTutorialSteps: {
        'customGraficoBarra': {
          'key': _graficoBarraKey,
          'message': S.of(context).monthly_expenses_graph,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
        'customGraficoAnel': {
          'key': _graficoAnelKey,
          'message': S.of(context).top_expenses_graph,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
        // Adicione um passo de tutorial para o novo gráfico, se necessário
      },
      onWillPop: () async {
        return true;
      },
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateSelector(),
        SizedBox(height: 16),
        FutureBuilder<Map<String, double>>(
          future: _futureTotais,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text(S.of(context).error_loading);
            } else if (!snapshot.hasData) {
              return Text(S.of(context).no_purchase_records);
            } else {
              final totais = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${S.of(context).purchased}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(totais['comprado']!)}'),
                  Text('${S.of(context).toPay}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(totais['aPagar']!)}'),
                  Text('${S.of(context).credit_card}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(totais['creditoFatura']!)}'),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).referenceMonth,
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                FormatacaoUtil.formatDateMonthYear(_selectedDate),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.calendar_today),
                label: Text(S.of(context).change),
                onPressed: () async {
                  final DateTime? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelecaoMesAnoScreen(
                        initialDate: _selectedDate,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedDate = result;
                      _loadData();
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoBarra() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    final locale = appStateManager.appLocale.toString();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;
    final chartTheme = Theme.of(context).extension<ChartTheme>()!;

    // Definindo os títulos das categorias
    final List<String> _categories = [
      S.of(context).purchased,
      S.of(context).toPay,
    ];

    return Column(
      children: [
        Container(
          height: 200,
          child: FutureBuilder<Map<String, double>>(
            future: _futureTotais,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || !snapshot.hasData) {
                return Text(S.of(context).error_loading);
              } else {
                final totais = snapshot.data!;
                // Considerar apenas 'comprado' e 'aPagar'
                final maxValue = [totais['comprado']!, totais['aPagar']!].reduce((max, value) => max > value ? max : value);

                return BarChart(
                  BarChartData(
                    maxY: maxValue * 1.2, // Adiciona um pouco de espaço acima
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false, // Removendo as labels do eixo X
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              FormatacaoUtil.instance.formatNumberWithAbbreviation(value),
                              style: chartTheme.axisTextStyle,
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                        axisNameWidget: Text(
                          S.of(context).totalSpentThisMonth(currencySymbol),
                          style: chartTheme.axisTextStyle,
                        ),
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(_categories.length, (index) {
                      String key;
                      if (index == 0) {
                        key = 'comprado';
                      } else if (index == 1) {
                        key = 'aPagar';
                      } else {
                        key = '';
                      }
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: totais[key]!,
                            color: _graphColors[index % _graphColors.length], // Atribui cor específica
                            width: chartTheme.barWidth,
                          ),
                        ],
                      );
                    }),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String title;
                          switch (group.x) {
                            case 0:
                              title = S.of(context).purchased;
                              break;
                            case 1:
                              title = S.of(context).toPay;
                              break;
                            default:
                              title = '';
                          }
                          return BarTooltipItem(
                            '$title\n$currencySymbol${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(rod.toY)}',
                            chartTheme.tooltipTextStyle,
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        SizedBox(height: 16),
        // Construindo a legenda
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_categories.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: _graphColors[index % _graphColors.length],
                  ),
                  SizedBox(width: 4),
                  Text(
                    _categories[index],
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }



  // Novo método para construir o segundo gráfico: Total a Pagar por Meio de Pagamento
  Widget _buildGraficoAPagarContaPagamento() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    final locale = appStateManager.appLocale.toString();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;
    final chartTheme = Theme.of(context).extension<ChartTheme>()!;

    return Column(
      children: [
        Container(
          height: 200,
          child: FutureBuilder<Map<String, double>>(
            future: _futureAPagarContaPagamento,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || !snapshot.hasData) {
                return Text(S.of(context).error_loading);
              } else {
                final aPagarContaPagamento = snapshot.data!;
                if (aPagarContaPagamento.isEmpty) {
                  return Text(S.of(context).no_purchase_records);
                }
                final maxValue = aPagarContaPagamento.values.isNotEmpty
                    ? aPagarContaPagamento.values.reduce((max, value) => max > value ? max : value)
                    : 0.0;

                final keys = aPagarContaPagamento.keys.toList();
                return BarChart(
                  BarChartData(
                    maxY: maxValue * 1.2, // Adiciona um pouco de espaço acima
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false, // Removendo as labels do eixo X
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              FormatacaoUtil.instance.formatNumberWithAbbreviation(value),
                              style: chartTheme.axisTextStyle,
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                        axisNameWidget: Text(
                          S.of(context).total_payments_by_account_label,
                          style: chartTheme.axisTextStyle,
                        ),
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: aPagarContaPagamento.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final contaId = entry.value.key;
                      final valor = entry.value.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: valor,
                            color: _graphColors[index % _graphColors.length], // Atribui cor diferente
                            width: chartTheme.barWidth,
                          ),
                        ],
                      );
                    }).toList(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final contaId = aPagarContaPagamento.keys.elementAt(group.x);
                          return BarTooltipItem(
                            '$contaId\n$currencySymbol${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(rod.toY)}',
                            chartTheme.tooltipTextStyle,
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        SizedBox(height: 16),
        _buildLegenda(),
      ],
    );
  }

  Widget _buildLegenda() {
    return FutureBuilder<Map<String, double>>(
      future: _futureAPagarContaPagamento,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(); // Não exibe nada enquanto carrega
        } else if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(); // Não exibe nada em caso de erro
        } else {
          final aPagarContaPagamento = snapshot.data!;
          if (aPagarContaPagamento.isEmpty) {
            return SizedBox(); // Não exibe nada se estiver vazio
          }

          final keys = aPagarContaPagamento.keys.toList();

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(keys.length, (index) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: _graphColors[index % _graphColors.length],
                  ),
                  SizedBox(width: 4),
                  Text(
                    keys[index],
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              );
            }),
          );
        }
      },
    );
  }



  Widget _buildGraficoAnel() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    final locale = appStateManager.appLocale.toString();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;
    final chartTheme = Theme.of(context).extension<ChartTheme>()!;

    return Column(
      children: [
        Container(
          height: 200,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureTopGastosItens,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError || !snapshot.hasData) {
                return Text(S.of(context).error_loading);
              } else {
                final topItens = snapshot.data!;
                return PieChart(
                  PieChartData(
                    sections: topItens.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return PieChartSectionData(
                        color: _graphColors[index % _graphColors.length], // Usando cores distintas
                        value: item['valor'],
                        title: '${item['nome']}\n$currencySymbol${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(item['valor'])}',
                        radius: 50,
                        titleStyle: chartTheme.tooltipTextStyle.copyWith(fontSize: 12),
                        titlePositionPercentageOffset: 0.55,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Você pode adicionar interatividade aqui se desejar
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ),
        SizedBox(height: 16),
        // Construindo a legenda para o gráfico de anel
        _buildLegenda(),
      ],
    );
  }

}
