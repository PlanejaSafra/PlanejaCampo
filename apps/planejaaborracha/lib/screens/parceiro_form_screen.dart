import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
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
      // Create
      final newParceiro = Parceiro(
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Parceiro?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await context.read<ParceiroService>().deleteParceiro(widget.parceiroId!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.parceiroId == null ? 'Novo Parceiro' : 'Editar Parceiro'),
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
          padding: const EdgeInsets.all(16),
          children: [
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Parceiro',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _percentualController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Porcentagem Padrão (%)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Insira a porcentagem';
                        }
                        final number = double.tryParse(value);
                        if (number == null || number < 0 || number > 100) {
                          return 'Valor inválido (0-100)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Salvar',
              onPressed: _isLoading ? null : _save,
              loading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
