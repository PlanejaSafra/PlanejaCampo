import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/conta_pagar.dart';
import '../services/conta_pagamento_service.dart';

class ContaPagarScreen extends StatefulWidget {
  const ContaPagarScreen({super.key});

  @override
  State<ContaPagarScreen> createState() => _ContaPagarScreenState();
}

class _ContaPagarScreenState extends State<ContaPagarScreen> {
  final ContaPagamentoService _service = ContaPagamentoService.instance;
  late List<ContaPagar> _vencidas;
  late List<ContaPagar> _venceEstaSemana;
  late List<ContaPagar> _proximas;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Simulating async fetch or just getting from Hive
    await Future.delayed(const Duration(milliseconds: 200)); 
    
    final allPendentes = _service.getPendentes();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfWeek = startOfToday.add(const Duration(days: 7));

    setState(() {
      _vencidas = allPendentes.where((c) => c.vencimento.isBefore(startOfToday)).toList();
      
      _venceEstaSemana = allPendentes.where((c) => 
          (c.vencimento.isAtSameMomentAs(startOfToday) || c.vencimento.isAfter(startOfToday)) && 
          c.vencimento.isBefore(endOfWeek)).toList();
      
      _proximas = allPendentes.where((c) => c.vencimento.isAfter(endOfWeek)).toList();
      
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashContasPagarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to Add Form
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              context: context,
              title: l10n.cashContasVencidas,
              contas: _vencidas,
              color: Colors.red,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: l10n.cashContasVenceEstaSemana,
              contas: _venceEstaSemana,
              color: Colors.orange,
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: l10n.cashContasProximas,
              contas: _proximas,
              color: Colors.green,
              icon: Icons.event_available,
            ),

            const SizedBox(height: 32),
            _buildTotalCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<ContaPagar> contas,
    required Color color,
    required IconData icon,
  }) {
    if (contas.isEmpty) return const SizedBox.shrink();

    final total = contas.fold(0.0, (sum, c) => sum + c.valor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              '$title (${contas.length})',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              NumberFormat.currency(symbol: 'R\$').format(total),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: contas.map((conta) => _buildContaTile(context, conta, color)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContaTile(BuildContext context, ContaPagar conta, Color color) {
    final l10n = CashLocalizations.of(context)!;
    final dateFormatter = DateFormat('dd/MM');
    final parcelaText = conta.parcelaLabel.isNotEmpty
        ? l10n.cashContaParcela(conta.parcelaLabel)
        : '';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(Icons.receipt_long, color: color, size: 20),
      ),
      title: Text(
        conta.descricao,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        l10n.cashContaVence(dateFormatter.format(conta.vencimento)) + parcelaText,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            NumberFormat.currency(symbol: 'R\$').format(conta.valor),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            color: Colors.green,
            onPressed: () => _confirmarPagamento(conta),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTotalCard(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    final totalGeral = (_vencidas + _venceEstaSemana + _proximas).fold(0.0, (sum, c) => sum + c.valor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.cashContasTotalPendente,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            NumberFormat.currency(symbol: 'R\$').format(totalGeral),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarPagamento(ContaPagar conta) async {
    final l10n = CashLocalizations.of(context)!;
    // Show Dialog to confirm and pick Account
    // Placeholder implementation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cashContasConfirmarPagamento),
        content: Text(l10n.cashContasDesejaPagar(conta.descricao, conta.valor.toStringAsFixed(2))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancelarButton)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.cashContasPagar)),
        ],
      ),
    );

    if (confirm == true) {
      // In a real app, we would ask for date and source account ID
      await _service.pagar(conta.id, 'conta-placeholder-id', DateTime.now());
      _loadData();
    }
  }
}
