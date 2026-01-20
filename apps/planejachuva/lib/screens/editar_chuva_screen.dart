import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/registro_chuva.dart';
import '../services/chuva_service.dart';
import '../services/share_service.dart';

/// Screen for editing an existing rainfall record.
class EditarChuvaScreen extends StatefulWidget {
  final RegistroChuva registro;

  const EditarChuvaScreen({
    super.key,
    required this.registro,
  });

  @override
  State<EditarChuvaScreen> createState() => _EditarChuvaScreenState();
}

class _EditarChuvaScreenState extends State<EditarChuvaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _milimetrosController;
  late TextEditingController _observacaoController;

  late DateTime _dataSelecionada;
  bool _salvando = false;
  String? _talhaoSelecionado;
  final _talhaoService = TalhaoService();

  @override
  void initState() {
    super.initState();
    _dataSelecionada = widget.registro.data;
    _talhaoSelecionado = widget.registro.talhaoId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize controllers here to have access to context for locale
    if (!_controllersInitialized) {
      final locale = Localizations.localeOf(context).toString();
      final mmFormatado =
          NumberFormat('#0.0', locale).format(widget.registro.milimetros);
      _milimetrosController = TextEditingController(text: mmFormatado);
      _observacaoController = TextEditingController(
        text: widget.registro.observacao ?? '',
      );
      _controllersInitialized = true;
    }
  }

  bool _controllersInitialized = false;

  @override
  void dispose() {
    _milimetrosController.dispose();
    _observacaoController.dispose();
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
      final mm = double.parse(
        _milimetrosController.text.replaceAll(',', '.'),
      );

      final registroAtualizado = RegistroChuva(
        id: widget.registro.id,
        data: _dataSelecionada,
        milimetros: mm,
        observacao: _observacaoController.text.isEmpty
            ? null
            : _observacaoController.text,
        criadoEm: widget.registro.criadoEm,
        propertyId: widget.registro.propertyId,
        talhaoId: _talhaoSelecionado,
      );

      await ChuvaService().atualizar(registroAtualizado);

      if (mounted) {
        // Haptic feedback for tactile confirmation
        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chuvaAtualizada),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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

  Future<void> _confirmarExclusao() async {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chuvaConfirmarExclusaoTitle),
        content: Text(l10n.chuvaConfirmarExclusaoMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.chuvaBotaoCancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.chuvaBotaoExcluir),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await ChuvaService().excluir(widget.registro.id);
      if (mounted) {
        // Heavy haptic feedback for deletion (stronger tactile warning)
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chuvaExcluida),
            action: SnackBarAction(
              label: l10n.chuvaDesfazer,
              onPressed: () async {
                // Re-add the deleted record
                await ChuvaService().adicionar(widget.registro);
              },
            ),
          ),
        );
        Navigator.pop(context, true);
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
        title: Text(l10n.chuvaEditarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar',
            onPressed: () async {
              final property =
                  PropertyService().getPropertyById(widget.registro.propertyId);
              if (property != null && context.mounted) {
                await ShareService().shareRainRecord(
                  context,
                  registro: widget.registro,
                  propertyName: property.nome,
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              color: theme.colorScheme.error,
            ),
            onPressed: _confirmarExclusao,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Millimeters field
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
            // Talhão selector
            TalhaoSelector(
              propertyId: widget.registro.propertyId,
              selectedTalhaoId: _talhaoSelecionado,
              onChanged: (id) => setState(() => _talhaoSelecionado = id),
              talhaoService: _talhaoService,
            ),
            const SizedBox(height: 16),
            // Observation field
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
