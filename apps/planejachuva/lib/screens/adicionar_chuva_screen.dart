import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/registro_chuva.dart';
import '../services/chuva_service.dart';
import '../services/validation_service.dart';

/// Screen for adding a new rainfall record.
class AdicionarChuvaScreen extends StatefulWidget {
  const AdicionarChuvaScreen({super.key});

  @override
  State<AdicionarChuvaScreen> createState() => _AdicionarChuvaScreenState();
}

class _AdicionarChuvaScreenState extends State<AdicionarChuvaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _milimetrosController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _milimetrosFocus = FocusNode();

  DateTime _dataSelecionada = DateTime.now();
  bool _salvando = false;
  Property? _propriedadeSelecionada;
  String? _talhaoSelecionado;  // null = whole property
  final _talhaoService = TalhaoService();

  @override
  void initState() {
    super.initState();
    _carregarPropriedadePadrao();
    // Auto-focus on millimeters field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _milimetrosFocus.requestFocus();
    });
  }

  Future<void> _carregarPropriedadePadrao() async {
    final propertyService = PropertyService();
    final defaultProperty = await propertyService.ensureDefaultProperty(
      l10n: AgroLocalizations.of(context),
    );
    setState(() {
      _propriedadeSelecionada = defaultProperty;
    });
  }

  @override
  void dispose() {
    _milimetrosController.dispose();
    _observacaoController.dispose();
    _milimetrosFocus.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<bool?> _showConfirmationDialog(String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              Localizations.localeOf(context).toString().startsWith('pt')
                  ? 'Cancelar'
                  : 'Cancel',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              Localizations.localeOf(context).toString().startsWith('pt')
                  ? 'Confirmar'
                  : 'Confirm',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String? _validarMilimetros(String? valor) {
    final l10n = AgroLocalizations.of(context)!;
    if (valor == null || valor.isEmpty) {
      return l10n.chuvaErroValorInvalido;
    }
    final mm = double.tryParse(valor.replaceAll(',', '.'));
    if (mm == null || mm < 0.1 || mm > 500) {
      return l10n.chuvaErroValorInvalido;
    }
    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final l10n = AgroLocalizations.of(context)!;
      final locale = Localizations.localeOf(context).toString();
      final mm = double.parse(
        _milimetrosController.text.replaceAll(',', '.'),
      );

      final validator = ValidationService();

      // Check for extreme rainfall
      if (validator.isExtremeRainfall(mm)) {
        final confirmed = await _showConfirmationDialog(
          validator.getExtremeRainfallMessage(mm, locale),
        );
        if (confirmed != true) {
          setState(() => _salvando = false);
          return;
        }
      }

      // Check for duplicate date
      if (validator.isDuplicateDate(_dataSelecionada)) {
        final existing = validator.findRecordOnDate(_dataSelecionada);
        if (existing != null) {
          final confirmed = await _showConfirmationDialog(
            validator.getDuplicateDateMessage(existing, locale),
          );
          if (confirmed != true) {
            setState(() => _salvando = false);
            return;
          }
        }
      }

      // Ensure property is selected (should never be null after init)
      if (_propriedadeSelecionada == null) {
        await _carregarPropriedadePadrao();
      }

      final registro = RegistroChuva.novo(
        data: _dataSelecionada,
        milimetros: mm,
        observacao: _observacaoController.text.isEmpty
            ? null
            : _observacaoController.text,
        propertyId: _propriedadeSelecionada!.id,
        talhaoId: _talhaoSelecionado,  // null = whole property
      );

      await ChuvaService().adicionar(registro);

      if (mounted) {
        // Haptic feedback for tactile confirmation
        HapticFeedback.mediumImpact();

        final locale = Localizations.localeOf(context).toString();
        final mmFormatado = NumberFormat('#0.0', locale).format(mm);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chuvaRegistrada(mmFormatado)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chuvaAdicionarTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Millimeters field (large and prominent)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chuvaCampoMilimetros,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _milimetrosController,
                      focusNode: _milimetrosFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[,.]?\d*'),
                        ),
                      ],
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: l10n.chuvaCampoMilimetrosHint,
                        suffixText: l10n.chuvaMm,
                        suffixStyle: theme.textTheme.headlineSmall,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: _validarMilimetros,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Date field
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l10n.chuvaCampoData),
                subtitle: Text(
                  DateFormat.yMMMd(locale).format(_dataSelecionada),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selecionarData,
              ),
            ),
            const SizedBox(height: 16),
            // Talhão selector (optional, only show if property is selected)
            if (_propriedadeSelecionada != null)
              TalhaoSelector(
                propertyId: _propriedadeSelecionada!.id,
                selectedTalhaoId: _talhaoSelecionado,
                onChanged: (talhaoId) {
                  setState(() => _talhaoSelecionado = talhaoId);
                },
                talhaoService: _talhaoService,
                enabled: !_salvando,
              ),
            if (_propriedadeSelecionada != null) const SizedBox(height: 16),
            // Observation field (optional)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chuvaCampoObservacao,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _observacaoController,
                      maxLines: 2,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: l10n.chuvaCampoObservacaoHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _salvando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.chuvaBotaoSalvar,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
