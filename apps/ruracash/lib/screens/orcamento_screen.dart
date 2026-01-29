import 'package:flutter/material.dart';
import 'package:agro_core/agro_core.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/orcamento.dart';
import '../services/orcamento_service.dart';
import '../services/lancamento_service.dart';
import '../helpers/categoria_icon_helper.dart';

/// CASH-27: Budget management screen.
/// CASH-21: Updated to use Categoria model instead of CashCategoria enum.
class OrcamentoScreen extends StatefulWidget {
  const OrcamentoScreen({super.key});

  @override
  State<OrcamentoScreen> createState() => _OrcamentoScreenState();
}

class _OrcamentoScreenState extends State<OrcamentoScreen> {
  List<Orcamento> _orcamentos = [];
  final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadOrcamentos();
  }

  void _loadOrcamentos() {
    setState(() {
      _orcamentos = OrcamentoService.instance.getOrcamentosAtivos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashOrcamentosTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOrcamentoDialog(context),
            tooltip: l10n.cashOrcamentoDefinir,
          ),
        ],
      ),
      body: _orcamentos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.cashOrcamentoEmpty,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddOrcamentoDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.cashOrcamentoDefinir),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orcamentos.length,
              itemBuilder: (context, index) {
                final orcamento = _orcamentos[index];
                return _buildBudgetCard(context, orcamento);
              },
            ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Orcamento orcamento) {
    final l10n = CashLocalizations.of(context)!;

    // Get Categoria from CategoriaService
    final categoria = CategoriaService().getById(orcamento.categoriaId);
    final catName = categoria?.nome ?? 'Categoria';
    final catColor = categoria?.cor ?? Colors.grey;
    final catIcon = CategoriaIconHelper.getIcon(categoria?.icone);

    // Calcular consumo real via LancamentoService
    final periodo = orcamento.periodo;
    final lancamentos = LancamentoService.instance.getLancamentosPorPeriodo(periodo.start, periodo.end);

    // Filtrar lançamentos pela categoria e somar valores
    final consumido = lancamentos
        .where((l) => l.categoriaId == orcamento.categoriaId)
        .fold(0.0, (sum, l) => sum + l.valor);

    final percentual = orcamento.valorLimite > 0 ? consumido / orcamento.valorLimite : 0.0;
    final restante = orcamento.valorLimite - consumido;
    final color = percentual > 1 ? Colors.red : (percentual > 0.8 ? Colors.orange : Colors.blue);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: catColor.withValues(alpha: 0.15),
                  child: Icon(catIcon, color: catColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    catName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteOrcamento(orcamento.id),
                  tooltip: 'Remover',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentual.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),

            // Progress text
            Text(
              l10n.cashOrcamentoProgresso(
                _currencyFormat.format(consumido),
                _currencyFormat.format(orcamento.valorLimite),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),

            // Remaining/exceeded text
            Text(
              restante > 0
                  ? l10n.cashOrcamentoRestam(_currencyFormat.format(restante))
                  : l10n.cashOrcamentoEstourou(_currencyFormat.format(-restante)),
              style: TextStyle(
                fontSize: 12,
                color: restante > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddOrcamentoDialog(BuildContext context) async {
    final l10n = CashLocalizations.of(context)!;

    // Get expense categories for current context
    final farm = FarmService.instance.getDefaultFarm();
    final isPersonal = farm?.type == FarmType.personal;
    final categorias = isPersonal
        ? CategoriaService().getCategoriasPersonal().where((c) => !c.isReceita).toList()
        : CategoriaService().getCategoriasAgro().where((c) => !c.isReceita).toList();

    if (categorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma categoria disponível')),
      );
      return;
    }

    String? selectedCategoriaId = categorias.first.id;
    double valorLimite = 0;
    final valorController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cashOrcamentoDefinir),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategoriaId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: categorias.map((c) {
                final icon = CategoriaIconHelper.getIcon(c.icone);
                return DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: c.cor),
                      const SizedBox(width: 8),
                      Text(c.nome),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => selectedCategoriaId = v,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(
                labelText: 'Valor Limite',
                prefixText: 'R\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                valorLimite = double.tryParse(v.replaceAll(',', '.')) ?? 0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelarButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.salvarButton),
          ),
        ],
      ),
    );

    if (result == true && selectedCategoriaId != null && valorLimite > 0) {
      final now = DateTime.now();
      final orcamento = Orcamento.create(
        categoriaId: selectedCategoriaId!,
        valorLimite: valorLimite,
        tipo: TipoPeriodoOrcamento.mes,
        ano: now.year,
        mes: now.month,
      );
      await OrcamentoService.instance.add(orcamento);
      _loadOrcamentos();
    }
  }

  Future<void> _deleteOrcamento(String id) async {
    await OrcamentoService.instance.delete(id);
    _loadOrcamentos();
  }
}
