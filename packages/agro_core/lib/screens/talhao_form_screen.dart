import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/talhao.dart';
import '../models/property.dart';
import '../services/talhao_service.dart';
import '../l10n/generated/app_localizations.dart';

/// Screen for adding or editing a Talhão (Field Plot)
class TalhaoFormScreen extends StatefulWidget {
  final Property property;
  final Talhao? talhao; // null = create new, not null = edit existing
  final TalhaoService talhaoService;
  final String userId;

  const TalhaoFormScreen({
    super.key,
    required this.property,
    this.talhao,
    required this.talhaoService,
    required this.userId,
  });

  @override
  State<TalhaoFormScreen> createState() => _TalhaoFormScreenState();
}

class _TalhaoFormScreenState extends State<TalhaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _areaController = TextEditingController();
  final _culturaController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditing => widget.talhao != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nomeController.text = widget.talhao!.nome;
      _areaController.text = widget.talhao!.area.toStringAsFixed(1);
      _culturaController.text = widget.talhao!.cultura ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _areaController.dispose();
    _culturaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nome = _nomeController.text.trim();
      final area = double.parse(_areaController.text.replaceAll(',', '.'));
      final cultura = _culturaController.text.trim().isEmpty
          ? null
          : _culturaController.text.trim();

      if (_isEditing) {
        // Update existing talhão
        await widget.talhaoService.update(
          id: widget.talhao!.id,
          nome: nome,
          area: area,
          cultura: cultura,
          property: widget.property,
        );

        if (mounted) {
          final l10n = AgroLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.talhaoUpdated)),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Create new talhão
        await widget.talhaoService.create(
          userId: widget.userId,
          propertyId: widget.property.id,
          nome: nome,
          area: area,
          cultura: cultura,
          property: widget.property,
        );

        if (mounted) {
          final l10n = AgroLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.talhaoSaved)),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.talhaoEdit : l10n.talhaoAdd),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Property context card
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.landscape,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.property.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.property.totalArea != null)
                            Text(
                              '${widget.property.totalArea!.toStringAsFixed(1)} ha',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Name field
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: l10n.talhaoName,
                hintText: l10n.talhaoNameHint,
                prefixIcon: const Icon(Icons.crop_square),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.talhaoNameRequired;
                }
                if (value.trim().length < 2) {
                  return l10n.talhaoNameTooShort;
                }
                if (value.trim().length > 50) {
                  return l10n.talhaoNameTooLong;
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Area field
            TextFormField(
              controller: _areaController,
              decoration: InputDecoration(
                labelText: l10n.talhaoArea,
                hintText: l10n.talhaoAreaHint,
                prefixIcon: const Icon(Icons.straighten),
                border: const OutlineInputBorder(),
                suffixText: 'ha',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.talhaoAreaInvalid;
                }
                final area = double.tryParse(value.replaceAll(',', '.'));
                if (area == null || area <= 0) {
                  return l10n.talhaoAreaInvalid;
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Cultura field (optional)
            TextFormField(
              controller: _culturaController,
              decoration: InputDecoration(
                labelText: l10n.talhaoCultura,
                hintText: l10n.talhaoCulturaHint,
                prefixIcon: const Icon(Icons.grass),
                border: const OutlineInputBorder(),
                suffixIcon: _culturaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _isLoading
                            ? null
                            : () {
                                _culturaController.clear();
                                setState(() {});
                              },
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !_isLoading,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // Area summary (if property has total area)
            if (widget.property.totalArea != null)
              Card(
                color: theme.colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Resumo de Áreas',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildAreaSummary(theme),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(
                _isEditing ? l10n.talhaoEdit : l10n.talhaoAdd,
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaSummary(ThemeData theme) {
    final currentTotalArea = widget.talhaoService.getTotalAreaByProperty(widget.property.id);
    final inputArea = double.tryParse(_areaController.text.replaceAll(',', '.')) ?? 0;
    final existingArea = _isEditing ? widget.talhao!.area : 0;
    final newTotalArea = currentTotalArea - existingArea + inputArea;
    final propertyArea = widget.property.totalArea!;
    final remainingArea = propertyArea - newTotalArea;
    final percentage = (newTotalArea / propertyArea * 100).clamp(0, 100);

    final isOverLimit = newTotalArea > propertyArea;

    return Column(
      children: [
        _buildAreaRow(
          theme,
          'Área da propriedade',
          propertyArea,
          Icons.landscape,
        ),
        const Divider(height: 16),
        _buildAreaRow(
          theme,
          'Total dividido',
          newTotalArea,
          Icons.grid_view,
          color: isOverLimit ? theme.colorScheme.error : null,
        ),
        _buildAreaRow(
          theme,
          'Área restante',
          remainingArea,
          Icons.crop_free,
          color: isOverLimit ? theme.colorScheme.error : theme.colorScheme.tertiary,
        ),
        const Divider(height: 16),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: theme.colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOverLimit ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}% da propriedade dividida',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isOverLimit
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isOverLimit ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaRow(
    ThemeData theme,
    String label,
    double area,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color ?? theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '${area.toStringAsFixed(1)} ha',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color ?? theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
