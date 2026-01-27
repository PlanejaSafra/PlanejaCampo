import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/cash_categoria.dart';
import '../services/lancamento_service.dart';
import '../services/centro_custo_service.dart';
import '../widgets/cash_drawer.dart';

/// Calculator-style expense entry screen.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _currentInput = '0';
  CashCategoria? _selectedCategory;
  String? _selectedCentroCustoId;

  @override
  void initState() {
    super.initState();
    final farm = FarmService.instance.getDefaultFarm();
    final isPersonal = farm?.type == FarmType.personal;

    // Smart default: pre-select most used category from CURRENT context
    final mostUsed = LancamentoService.instance.categoriaMaisUsada;

    if (mostUsed != null &&
        ((isPersonal && mostUsed.isPersonal) ||
            (!isPersonal && mostUsed.isAgro))) {
      _selectedCategory = mostUsed;
    } else {
      _selectedCategory =
          isPersonal ? CashCategoria.alimentacao : CashCategoria.outros;
    }

    _selectedCentroCustoId = CentroCustoService.instance.defaultCentroCusto?.id;
  }

  void _onDigit(String digit) {
    setState(() {
      if (_currentInput == '0' && digit != ',') {
        _currentInput = digit;
      } else if (digit == ',' && _currentInput.contains(',')) {
        return;
      } else if (_currentInput.contains(',') &&
          _currentInput.split(',').last.length >= 2) {
        return; // Max 2 decimal places
      } else if (_currentInput.length < 10) {
        _currentInput += digit;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_currentInput.length > 1) {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      } else {
        _currentInput = '0';
      }
    });
  }

  void _onClear() {
    setState(() {
      _currentInput = '0';
    });
  }

  double? _parseValue() {
    final normalized = _currentInput.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _formatDisplay() {
    return _currentInput.replaceAll('.', ',');
  }

  Future<void> _onSave() async {
    final l10n = CashLocalizations.of(context)!;
    final value = _parseValue();

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.calculatorValueRequired)),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.calculatorCategoryRequired)),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    await LancamentoService.instance.quickAdd(
      valor: value,
      categoria: _selectedCategory!,
      centroCustoId: _selectedCentroCustoId,
    );

    if (mounted) {
      final categoryName = _selectedCategory!.localizedName(l10n);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.currencySymbol} ${_formatDisplay()} - $categoryName ✓',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _currentInput = '0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    final centroService = context.watch<CentroCustoService>();
    final centros = centroService.centros;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calculatorTitle),
      ),
      drawer: buildCashDrawer(context: context, l10n: l10n),
      body: Column(
        children: [
          // Value Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.currencySymbol,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _formatDisplay(),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Monospace',
                  ),
                ),
              ],
            ),
          ),

          // Category Chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CashCategoria.values.where((c) {
                final farm = FarmService.instance.getDefaultFarm();
                final isPersonal = farm?.type == FarmType.personal;
                return isPersonal ? c.isPersonal : c.isAgro;
              }).map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon,
                          size: 16,
                          color: isSelected ? Colors.white : cat.color),
                      const SizedBox(width: 4),
                      Text(cat.localizedName(l10n)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: cat.color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          // Cost Center selector (if more than 1)
          if (centros.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedCentroCustoId,
                decoration: InputDecoration(
                  labelText: l10n.centroCustoSelectorLabel,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: centros
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nome),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCentroCustoId = value;
                  });
                },
              ),
            ),

          const SizedBox(height: 8),

          // Numeric Keypad
          Expanded(
            child: _buildKeypad(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(CashLocalizations l10n) {
    return Column(
      children: [
        _buildKeypadRow(['7', '8', '9']),
        _buildKeypadRow(['4', '5', '6']),
        _buildKeypadRow(['1', '2', '3']),
        _buildKeypadRow([',', '0', '⌫']),
        // Save Button
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(l10n.calculatorSave),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Material(
                color: key == '⌫' ? Colors.red.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (key == '⌫') {
                      _onBackspace();
                    } else {
                      _onDigit(key);
                    }
                  },
                  onLongPress: key == '⌫' ? _onClear : null,
                  child: Center(
                    child: Text(
                      key,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color:
                            key == '⌫' ? Colors.red.shade700 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
