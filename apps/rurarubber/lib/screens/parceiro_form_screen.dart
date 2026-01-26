import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../models/parceiro.dart';
import '../services/parceiro_service.dart';

class ParceiroFormScreen extends StatefulWidget {
  final String? parceiroId;

  const ParceiroFormScreen({super.key, this.parceiroId});

  @override
  State<ParceiroFormScreen> createState() => _ParceiroFormScreenState();
}

class _ParceiroFormScreenState extends State<ParceiroFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _percentualController = TextEditingController(text: '50');
  final _telefoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.parceiroId != null) {
      _loadParceiro();
    }
  }

  void _loadParceiro() {
    final service = context.read<ParceiroService>();
    final parceiro = service.getParceiro(widget.parceiroId!);
    if (parceiro != null) {
      _nomeController.text = parceiro.nome;
      _percentualController.text = parceiro.percentualPadrao.toStringAsFixed(0);
      _telefoneController.text = parceiro.telefone ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _percentualController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final service = context.read<ParceiroService>();
    final nome = _nomeController.text.trim();
    final percentual = double.tryParse(_percentualController.text) ?? 50.0;
    final telefone = _telefoneController.text.trim();

    if (widget.parceiroId != null) {
      // Update
      final parceiro = service.getParceiro(widget.parceiroId!);
      if (parceiro != null) {
        parceiro.nome = nome;
        parceiro.percentualPadrao = percentual;
        parceiro.telefone = telefone.isEmpty ? null : telefone;
        await service.updateParceiro(parceiro);
      }
    } else {
      // Create (uses Parceiro.create with auto-filled farmId/createdBy/createdAt)
      final newParceiro = Parceiro.create(
        id: const Uuid().v4(),
        nome: nome,
        percentualPadrao: percentual,
        telefone: telefone.isEmpty ? null : telefone,
      );
      await service.addParceiro(newParceiro);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    if (widget.parceiroId == null) return;

    final l10n = BorrachaLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.parceiroDeleteTitle),
        content: Text(l10n.parceiroDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.parceiroDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.parceiroDeleteConfirm,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final service = context.read<ParceiroService>();
      setState(() => _isLoading = true);
      await service.deleteParceiro(widget.parceiroId!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parceiroId == null
            ? l10n.parceiroAddButton
            : l10n.parceiroEditButton),
        actions: [
          if (widget.parceiroId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          // Add bottom padding to avoid FAB overlap
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: l10n.parceiroNome,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.parceiroNomeRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _percentualController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.parceiroPercentual,
                        border: const OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.parceiroPercentualInvalid;
                        }
                        final number = double.tryParse(value);
                        if (number == null || number < 0 || number > 100) {
                          return l10n.parceiroPercentualInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.parceiroTelefone,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating save button - always visible
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 32,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _save,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          label: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l10n.parceiroSaveButton,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: AgroBannerWidget(),
        ),
      ),
    );
  }
}
