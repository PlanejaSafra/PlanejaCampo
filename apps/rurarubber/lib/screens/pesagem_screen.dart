import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'fechamento_entrega_screen.dart';
import 'lista_entregas_screen.dart';
import 'parceiro_form_screen.dart';
import '../services/parceiro_service.dart';
import '../services/entrega_service.dart';
import '../widgets/big_calculator_keypad.dart';
import '../widgets/rubber_drawer.dart';
import '../widgets/tape_view_widget.dart';
import '../widgets/weight_card_widget.dart';

class PesagemScreen extends StatefulWidget {
  const PesagemScreen({super.key});

  @override
  State<PesagemScreen> createState() => _PesagemScreenState();
}

class _PesagemScreenState extends State<PesagemScreen> {
  String? _selectedParceiroId;
  String _currentInput = '';
  bool _nightMode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pesagemTitle),
        actions: [
          // 16.4 Night Mode Toggle
          IconButton(
            icon: Icon(_nightMode ? Icons.wb_sunny : Icons.nightlight_round),
            tooltip: _nightMode
                ? l10n.pesagemNightModeOff
                : l10n.pesagemNightModeOn,
            onPressed: () {
              setState(() {
                _nightMode = !_nightMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const ListaEntregasScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: l10n.fechamentoTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const FechamentoEntregaScreen()),
              );
            },
          )
        ],
      ),
      drawer: buildRubberDrawer(context: context, l10n: l10n),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(BorrachaLocalizations l10n) {
    final content = Consumer2<ParceiroService, EntregaService>(
      builder: (context, parceiroService, entregaService, child) {
        final parceiros = parceiroService.parceiros;

        if (parceiros.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  l10n.pesagemNoPartnersError,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ParceiroFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.parceiroAddButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        // Auto-select first if none selected
        _selectedParceiroId ??= parceiros.first.id;

        final currentWeighings =
            entregaService.getPesagensForParceiro(_selectedParceiroId!);

        return Column(
          children: [
            // 1. Partner Select Header
            Container(
              color: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: parceiros.length,
                  itemBuilder: (context, index) {
                    final p = parceiros[index];
                    final isSelected = p.id == _selectedParceiroId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedParceiroId = p.id;
                          _currentInput = ''; // Clear input on switch
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: Colors.orange, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  isSelected ? Colors.orange : Colors.grey,
                              child: Text(p.nome[0],
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.nome,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Tape View / Accumulator
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: TapeViewWidget(
                        entries: currentWeighings,
                        onDeleteLast: () => entregaService
                            .undoLastPesagem(_selectedParceiroId!),
                        onShare: currentWeighings.isEmpty
                            ? null
                            : () {
                                final parceiro = parceiros.firstWhere(
                                  (p) => p.id == _selectedParceiroId,
                                );
                                final total = currentWeighings.fold(
                                    0.0, (sum, e) => sum + e);
                                // Get property name from PropertyService
                                final propertyName =
                                    PropertyService().getDefaultProperty()?.name ??
                                        l10n.unknownPartner;

                                showShareWeightDialog(
                                  context,
                                  partnerName: parceiro.nome,
                                  totalWeight: total,
                                  propertyName: propertyName,
                                  date: DateTime.now(),
                                  weighings: currentWeighings,
                                );
                              },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Current Input Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _currentInput.isEmpty ? '0' : _currentInput,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 32,
                              fontFamily: 'Monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            ' kg',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    // 16.1 Quick-Add Buttons
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final value in [50, 100, 150])
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: OutlinedButton(
                                onPressed: () {
                                  // 16.2 Haptic Feedback
                                  HapticFeedback.mediumImpact();
                                  entregaService.addPesagem(
                                    _selectedParceiroId!,
                                    value.toDouble(),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                ),
                                child: Text(
                                  l10n.pesagemQuickAdd(value),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. Keypad
            Expanded(
              flex: 5,
              child: BigCalculatorKeypad(
                onDigitPress: (digit) {
                  setState(() {
                    if (_currentInput.length < 6) {
                      // Max 6 digits
                      if (digit == '.' && _currentInput.contains('.')) {
                        return;
                      }
                      _currentInput += digit;
                    }
                  });
                },
                onClear: () {
                  setState(() {
                    if (_currentInput.isNotEmpty) {
                      _currentInput = '';
                    }
                  });
                },
                onAdd: () {
                  if (_currentInput.isEmpty) {
                    return;
                  }
                  final weight = double.tryParse(_currentInput);
                  if (weight != null && weight > 0) {
                    // 16.2 Haptic Feedback
                    HapticFeedback.mediumImpact();
                    entregaService.addPesagem(_selectedParceiroId!, weight);
                    setState(() {
                      _currentInput = '';
                    });
                  }
                },
              ),
            ),
          ],
        );
      },
    );

    // 16.4 Night Mode: wrap body in dark theme override
    if (!_nightMode) return content;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.greenAccent,
        ),
      ),
      child: content,
    );
  }
}
