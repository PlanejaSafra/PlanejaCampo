import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fluxo_caixa.dart';
import '../services/relatorio_service.dart';

class FluxoCaixaScreen extends StatefulWidget {
  const FluxoCaixaScreen({super.key});

  @override
  State<FluxoCaixaScreen> createState() => _FluxoCaixaScreenState();
}

class _FluxoCaixaScreenState extends State<FluxoCaixaScreen> {
  final RelatorioService _service = RelatorioService();
  FluxoCaixa? _fluxo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Load current month by default
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, 1);
    final fim = DateTime(now.year, now.month + 1, 0);

    final data = await _service.gerarFluxoCaixa(inicio, fim);
    setState(() {
      _fluxo = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fluxo de Caixa')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final f = _fluxo!;
    final currency = NumberFormat.currency(symbol: 'R\$');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'RESULTADO DO PERÍODO',
                  style: TextStyle(color: Colors.white70, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  currency.format(f.saldoPeriodo),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  f.saldoPeriodo >= 0 ? 'Lucro no período' : 'Prejuízo no período',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Row(
          children: [
             Expanded(child: _buildSummaryCard('Entradas', f.totalEntradas, Colors.green)),
             const SizedBox(width: 16),
             Expanded(child: _buildSummaryCard('Saídas', f.totalSaidas, Colors.red)),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'EVOLUÇÃO DO SALDO',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow('Saldo Inicial', f.saldoInicial),
                const Divider(),
                _buildRow('Entradas', f.totalEntradas, color: Colors.green),
                _buildRow('Saídas', -f.totalSaidas, color: Colors.red),
                const Divider(),
                _buildRow('Saldo Final', f.saldoFinal, isBold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color)),
            const SizedBox(height: 4),
            Text(
              NumberFormat.compactCurrency(symbol: 'R\$').format(value),
              style: TextStyle(
                color: color, 
                fontWeight: FontWeight.bold, 
                fontSize: 18
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, double value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : null)),
          Text(
            NumberFormat.currency(symbol: 'R\$').format(value),
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
