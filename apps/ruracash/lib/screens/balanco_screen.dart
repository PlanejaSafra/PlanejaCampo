import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/balanco_patrimonial.dart';
import '../services/relatorio_service.dart';

class BalancoScreen extends StatefulWidget {
  const BalancoScreen({super.key});

  @override
  State<BalancoScreen> createState() => _BalancoScreenState();
}

class _BalancoScreenState extends State<BalancoScreen> {
  final RelatorioService _service = RelatorioService();
  BalancoPatrimonial? _balanco;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _service.gerarBalanco(DateTime.now());
    setState(() {
      _balanco = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashBalancoTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              // TODO: Export PDF
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    final b = _balanco!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(context, b.data),
        const SizedBox(height: 24),

        _buildGroup(
          context: context,
          title: l10n.cashBalancoAtivos,
          items: b.ativos,
          total: b.totalAtivos,
          color: Colors.green,
        ),

        const SizedBox(height: 24),

        _buildGroup(
          context: context,
          title: l10n.cashBalancoPassivos,
          items: b.passivos,
          total: b.totalPassivos,
          color: Colors.red,
        ),

        const SizedBox(height: 32),
        const Divider(thickness: 2),
        const SizedBox(height: 16),

        _buildResultRow(
          l10n.cashBalancoPatrimonio,
          b.patrimonioLiquido,
          Colors.blue,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DateTime data) {
    final l10n = CashLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.cashBalancoResumo,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd MMMM yyyy', 'pt_BR').format(data),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildGroup({
    required BuildContext context,
    required String title,
    required List<ItemBalanco> items,
    required double total,
    required Color color,
  }) {
    final l10n = CashLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(l10n.cashBalancoEmpty),
                  ),
                ...items.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(i.nome),
                      Text(NumberFormat.currency(symbol: 'R\$').format(i.valor)),
                    ],
                  ),
                )),
                const Divider(height: 24),
                _buildResultRow(l10n.cashBalancoTotal, total, color),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, double value, Color color, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isLarge ? 16 : 14,
            color: isLarge ? color : null,
          ),
        ),
        Text(
          NumberFormat.currency(symbol: 'R\$').format(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isLarge ? 20 : 16,
            color: color,
          ),
        ),
      ],
    );
  }
}
