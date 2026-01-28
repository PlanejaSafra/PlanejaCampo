import 'package:flutter/material.dart';
import 'package:agro_core/agro_core.dart';
import 'package:intl/intl.dart';

import '../models/orcamento.dart';
import '../services/orcamento_service.dart';
import '../widgets/safra_selector.dart'; // hypothetical, we will use a simple dropdown for now

class OrcamentoScreen extends StatefulWidget {
  const OrcamentoScreen({super.key});

  @override
  State<OrcamentoScreen> createState() => _OrcamentoScreenState();
}

class _OrcamentoScreenState extends State<OrcamentoScreen> {
  final OrcamentoService _service = OrcamentoService.instance;
  
  TipoPeriodoOrcamento _currentTipo = TipoPeriodoOrcamento.safra;
  int _currentAno = DateTime.now().year; // For Safra, it's the start year (e.g. 2025 for 2025/26)
  
  List<Orcamento> _orcamentos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Simulate query
    await Future.delayed(const Duration(milliseconds: 200));
    final fetched = _service.getPorPeriodoTipo(_currentTipo, _currentAno);
    
    setState(() {
      _orcamentos = fetched;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFilterBar(),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _orcamentos.isEmpty
              ? _buildEmptyState()
              : _buildBudgetList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open Add/Edit Budget Modal
        },
        label: const Text('Definir Orçamento'),
        icon: const Icon(Icons.edit_outlined),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          DropdownButton<TipoPeriodoOrcamento>(
            value: _currentTipo,
            underline: const SizedBox.shrink(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _currentTipo = val);
                _loadData();
              }
            },
            items: const [
              DropdownMenuItem(value: TipoPeriodoOrcamento.safra, child: Text('Por Safra')),
              DropdownMenuItem(value: TipoPeriodoOrcamento.mes, child: Text('Por Mês')),
              DropdownMenuItem(value: TipoPeriodoOrcamento.ano, child: Text('Por Ano')),
            ],
          ),
          const SizedBox(width: 16),
          // Simple Year Selector
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
               setState(() => _currentAno--);
               _loadData();
            },
          ),
          Text(
            _currentTipo == TipoPeriodoOrcamento.safra 
                ? '$_currentAno/${(_currentAno+1).toString().substring(2)}'
                : '$_currentAno',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
               setState(() => _currentAno++);
               _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhum orçamento definido para este período.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orcamentos.length,
      itemBuilder: (context, index) {
        final orcamento = _orcamentos[index];
        return _buildBudgetCard(orcamento);
      },
    );
  }

  Widget _buildBudgetCard(Orcamento orcamento) {
    // Mock consumption data for now
    final consumido = orcamento.valorLimite * 0.75; // Mock 75%
    final percentual = 0.75;
    final restante = orcamento.valorLimite - consumido;
    final color = percentual > 1 ? Colors.red : (percentual > 0.8 ? Colors.orange : Colors.blue);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categoria ${orcamento.categoriaId}', // Should resolve name
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Icon(
                  percentual > 1 ? Icons.warning : Icons.check_circle, 
                  color: color, 
                  size: 20
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentual > 1 ? 1 : percentual,
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$ ${consumido.toStringAsFixed(0)} de ${orcamento.valorLimite.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                Text(
                  '${(percentual * 100).toInt()}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              restante > 0 
                  ? 'Restam R\$ ${restante.toStringAsFixed(2)}' 
                  : 'Estourou R\$ ${(consumido - orcamento.valorLimite).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12, 
                color: restante > 0 ? Colors.green : Colors.red
              ),
            ),
          ],
        ),
      ),
    );
  }
}
