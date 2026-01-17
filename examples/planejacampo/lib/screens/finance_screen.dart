import 'package:fl_chart/fl_chart.dart'; // Importe a biblioteca de gráficos
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/widgets/base_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/services/compra_service.dart'; // Importe o CompraService
import 'package:planejacampo/services/item_compra_service.dart'; // Importe o ItemCompraService
import 'package:planejacampo/models/compra.dart'; // Importe o modelo de Compra
import 'package:planejacampo/models/item_compra.dart'; // Importe o modelo de ItemCompra
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/themes.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/themes/chart_theme.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  _FinanceScreenState createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {

  final ItemService _itemService = ItemService(); 
  bool _showTutorial = false;
  bool _isInitialized = false;
  bool _tutorialAlreadyStarted = false;
  final CompraService _compraService = CompraService(); // Instância do serviço de compra
  final ItemCompraService _itemCompraService = ItemCompraService(); // Instância do serviço de itens de compra
  final ContaPagarService _contaPagarService = ContaPagarService();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeState();
    });
  }

  void _initializeState() async {
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    if (mounted) {
      setState(() {
        _showTutorial = appStateManager.showTutorial('financeScreen');
        _isInitialized = true;
        if (_showTutorial && !_tutorialAlreadyStarted) {
          _startTutorial();
        }
      });
    }
  }

  // Busca os valores totais de compras e parcelas a pagar
  Future<Map<String, double>> _getTotaisMes() async {
    final DateTime now = DateTime.now();
    final DateTime primeiroDia = DateTime(now.year, now.month, 1);
    final DateTime ultimoDia = DateTime(now.year, now.month + 1, 0);
    final String produtorId = AppStateManager().activeProdutorId!;

    // Total Comprado - com base na data da compra
    final compras = await _compraService.getByAttributesWithOperators({
      'produtorId': [{'operator': '==', 'value': produtorId}],
      'data': [
        {'operator': '>=', 'value': Timestamp.fromDate(primeiroDia)},
        {'operator': '<=', 'value': Timestamp.fromDate(ultimoDia)}
      ],
    });

    double totalComprado = compras.fold(0.0, (sum, compra) => sum + compra.valorTotal);
    //print('totalComprado: $totalComprado');

    // Total a Pagar - com base na data de vencimento das parcelas
    List<ContaPagar> contasPagar = await _contaPagarService.getByAttributesWithOperators({
      'dataVencimento': [
        {'operator': '>=', 'value': Timestamp.fromDate(primeiroDia)},
        {'operator': '<=', 'value': Timestamp.fromDate(ultimoDia)}
      ],
    });

    double totalAPagar = contasPagar.fold(0.0, (sum, contaPagar) => sum + contaPagar.valor);

    print('financeScreen: primeiro dia: $primeiroDia, ultimo dia: $ultimoDia, totalComprado: $totalComprado, total a pagar: $totalAPagar');

    return {'comprado': totalComprado, 'aPagar': totalAPagar};
  }

  // Busca os cinco itens mais comprados no mês
    // Método atualizado para buscar os nomes dos itens
  Future<List<Map<String, dynamic>>> _getTopGastosItens() async {
    final DateTime now = DateTime.now();
    final DateTime primeiroDia = DateTime(now.year, now.month, 1);
    final DateTime ultimoDia = DateTime(now.year, now.month + 1, 0);
    final String produtorId = AppStateManager().activeProdutorId!;

    final compras = await _compraService.getByAttributesWithOperators({
      'produtorId': [{'operator': '==', 'value': produtorId}],
      'data': [
        {'operator': '>=', 'value': Timestamp.fromDate(primeiroDia)},
        {'operator': '<=', 'value': Timestamp.fromDate(ultimoDia)}
      ],
    });

    Map<String, double> gastosPorItem = {};
    Map<String, String> itemIdToNome = {};

    for (Compra compra in compras) {
      final itensCompra = await _itemCompraService.getByAttributes({'compraId': compra.id});
      for (ItemCompra itemCompra in itensCompra) {
        gastosPorItem.update(itemCompra.itemId, (valor) => valor + itemCompra.valorTotal, ifAbsent: () => itemCompra.valorTotal);
        
        if (!itemIdToNome.containsKey(itemCompra.itemId)) {
          final item = await _itemService.getById(itemCompra.itemId);
          itemIdToNome[itemCompra.itemId] = item?.nome ?? 'Item Desconhecido';
        }
      }
    }

    final topGastos = gastosPorItem.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    double outros = 0.0;
    List<Map<String, dynamic>> topItens = [];
    for (int i = 0; i < topGastos.length; i++) {
      if (i < 5) {
        topItens.add({
          'nome': itemIdToNome[topGastos[i].key] ?? 'Item Desconhecido',
          'valor': topGastos[i].value
        });
      } else {
        outros += topGastos[i].value;
      }
    }
    if (outros > 0) {
      topItens.add({'nome': 'Outros', 'valor': outros});
    }

    return topItens;
  }

  // Monta o gráfico de anel (doughnut)
  Widget _buildGraficoAnel(List<Map<String, dynamic>> topItens, BuildContext context) {
  final appStateManager = AppStateManager();
  final locale = appStateManager.appLocale.toString();
  final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

  // Acessa as configurações do tema de gráficos
  final chartTheme = Theme.of(context).extension<ChartTheme>()!;

  return Container(
    height: 300,
    width: 300,
    child: PieChart(
      PieChartData(
        sections: topItens.map((item) {
          return PieChartSectionData(
            color: AppThemes.getRandomColor(), // Se você quiser que o tema controle, pode usar uma cor padronizada
            value: item['valor'],
            title: '${item['nome']}\n${currencySymbol}${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(item['valor'])}',
            radius: 80,
            titleStyle: chartTheme.tooltipTextStyle.copyWith(fontSize: 12),  // Usa o estilo de tooltip definido no tema
            titlePositionPercentageOffset: 0.55,
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 50,  // Controla o espaço no centro do gráfico
      ),
    ),
  );
}


  Widget _buildGraficoBarra(double totalComprado, double totalAPagar, BuildContext context) {
  final appStateManager = AppStateManager();
  final locale = appStateManager.appLocale.toString();
  final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;
  final maxValue = totalComprado > totalAPagar ? totalComprado : totalAPagar;

  // Acessa as configurações do tema de gráficos
  final chartTheme = Theme.of(context).extension<ChartTheme>()!;

  return BarChart(
    BarChartData(
      barGroups: [
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(
            toY: totalComprado,
            color: chartTheme.barColorType1, // Usa cor do tema para "Comprado"
            width: chartTheme.barWidth,         // Usa largura definida no tema
          ),
        ]),
        BarChartGroupData(x: 1, barRods: [
          BarChartRodData(
            toY: totalAPagar,
            color: chartTheme.barColorType2,  // Usa cor do tema para "A Pagar"
            width: chartTheme.barWidth,        // Usa largura definida no tema
          ),
        ]),
      ],
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            double value = groupIndex == 0 ? totalComprado : totalAPagar;
            String formattedValue = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(value);
            return BarTooltipItem(
              '$currencySymbol $formattedValue',
              chartTheme.tooltipTextStyle,  // Usa estilo de texto do tema para tooltip
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(
          axisNameWidget: Text(
            S.of(context).totalSpentThisMonth(currencySymbol),  // Usa internacionalização para a frase completa
            style: chartTheme.axisTextStyle,  // Usa estilo de texto do tema para os eixos
          ),

          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value == maxValue) {
                // Arredonda o valor máximo para cima
                final roundedValue = (value / 1000).ceil() * 1000;
                return Text(
                  FormatacaoUtil.instance.formatNumberWithAbbreviation(roundedValue.toDouble()),
                  style: chartTheme.axisTextStyle,  // Usa estilo de texto do tema para os eixos
                );
              }
              return Text(
                FormatacaoUtil.instance.formatNumberWithAbbreviation(value),
                style: chartTheme.axisTextStyle,  // Usa estilo de texto do tema para os eixos
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                value == 0 ? S.of(context).purchased : S.of(context).toPay,
                style: chartTheme.axisTextStyle,  // Usa estilo de texto do tema para os títulos
              );
            },
          ),
        ),
        topTitles: AxisTitles(
          axisNameWidget: Text(
            S.of(context).values,
            style: chartTheme.axisTextStyle.copyWith(fontWeight: FontWeight.bold),  // Usa estilo de texto do tema para os eixos
          ),
        ),
      ),
      maxY: (maxValue / 1000).ceil() * 1000,  // Arredonda o valor máximo para cima
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<AppStateManager>(
      builder: (context, appStateManager, child) {
        return BaseTemplate(
          title: 'PlanejaCampo',
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text(S.of(context).home)),
                ),
                // Gráfico de barras - Total Comprado e Total a Pagar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,  // Centraliza o conteúdo da coluna
                    children: [
                      Center(  // Centraliza o texto do título
                        child: Text(
                          S.of(context).comparisonOfMonthlyExpenses,  // Internacionalização do título
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(  // Substitua headline6 por headlineSmall
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FutureBuilder<Map<String, double>>(
                        future: _getTotaisMes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text(S.of(context).error_loading);
                          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            final totais = snapshot.data!;
                            // Verifica se há valores maiores que zero para exibir o gráfico de barras
                            if (totais['comprado']! > 0 || totais['aPagar']! > 0) {
                              return SizedBox(
                                height: 300, // Defina uma altura adequada
                                width: double.infinity, // Use toda a largura disponível
                                child: _buildGraficoBarra(totais['comprado']!, totais['aPagar']!, context),
                              );
                            } else {
                              return Text(S.of(context).no_purchase_records); // Mensagem internacionalizada
                            }
                          } else {
                            return Text(S.of(context).no_purchase_records); // Mensagem internacionalizada
                          }
                        },
                      ),
                    ],
                  ),
                ),


                // Gráfico de anel - Top 5 itens comprados no mês
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,  // Centraliza o conteúdo da coluna
                    children: [
                      Center(  // Centraliza o texto do título
                        child: Text(
                          S.of(context).mostPurchasedItemsThisMonth,  // Internacionalização do título
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(  // Substitua headline6 por headlineSmall
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getTopGastosItens(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text(S.of(context).error_loading);
                          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            return SizedBox(
                              height: 300, // Defina uma altura adequada
                              width: double.infinity, // Use toda a largura disponível
                              child: _buildGraficoAnel(snapshot.data!, context),
                            );
                          } else {
                            return Text(S.of(context).no_purchase_records); // Mensagem internacionalizada
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          selectedIndex: 1,
          showTutorial: _showTutorial,
          onHelpPressed: () {
            if (!_tutorialAlreadyStarted) {
              setState(() {
                _showTutorial = true;
                _startTutorial();
              });
            }
          },
          onTutorialFinished: _onTutorialFinished,
        );
      },
    );
  }

  void _startTutorial() {
    if (!_tutorialAlreadyStarted) {
      setState(() {
        _tutorialAlreadyStarted = true;
      });
    }
  }

  void _onTutorialFinished() {
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    appStateManager.setShowTutorial('financeScreen', false);
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
    }
  }
}
