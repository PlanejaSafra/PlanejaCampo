import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/entrega_service.dart';
import '../services/parceiro_service.dart';
import '../services/pdf_service.dart';
import '../models/financeiro_helper.dart';

class FechamentoEntregaScreen extends StatefulWidget {
  const FechamentoEntregaScreen({super.key});

  @override
  State<FechamentoEntregaScreen> createState() =>
      _FechamentoEntregaScreenState();
}

class _FechamentoEntregaScreenState extends State<FechamentoEntregaScreen> {
  final _precoController = TextEditingController();
  double _precoPorKg = 0.0;

  @override
  void dispose() {
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final entregaService = context.watch<EntregaService>();
    final parceiroService = context.watch<ParceiroService>();
    final currentEntrega = entregaService.currentEntrega;

    if (currentEntrega == null || currentEntrega.itens.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.fechamentoTitle)),
        body: Center(child: Text(l10n.fechamentoNoItems)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fechamentoTitle),
      ),
      body: Column(
        children: [
          // 1. Price Input
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.fechamentoPriceRequired),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _precoController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.fechamentoBasePrice,
                      prefixText: '${l10n.currencySymbol} ',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _precoPorKg =
                            double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // 2. Summary List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentEntrega.itens.length,
              itemBuilder: (context, index) {
                final item = currentEntrega.itens[index];
                final parceiro = parceiroService.getParceiro(item.parceiroId);

                final valorTotalBruto = FinanceiroHelper.calcularValorTotal(
                    item.pesoTotal, _precoPorKg);
                final valorRepasse = FinanceiroHelper.calcularParteParceiro(
                    valorTotalBruto, parceiro?.percentualPadrao ?? 0);

                return Card(
                  child: ListTile(
                    title: Text(parceiro?.nome ?? l10n.unknownPartner),
                    subtitle: Text(
                        '${item.pesoTotal.toStringAsFixed(1)} kg (${parceiro?.percentualPadrao.toStringAsFixed(0)}%)'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${l10n.currencySymbol} ${valorRepasse.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green),
                        ),
                        Text(
                          '${l10n.totalLabel}: ${l10n.currencySymbol} ${valorTotalBruto.toStringAsFixed(2)}',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Actions
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    label: Text(l10n.fechamentoGeneratePdf),
                    icon: const Icon(Icons.share),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _precoPorKg > 0
                        ? () async {
                            await PdfService.generateAndShareReceipt(
                                currentEntrega,
                                parceiroService.parceiros,
                                _precoPorKg);
                          }
                        : null, // Disable if price is 0
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
