import 'package:flutter/material.dart';
import '../models/talhao.dart';
import '../models/property.dart';
import '../services/talhao_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'talhao_form_screen.dart';

/// Screen to list and manage Talhões (Field Plots) of a property
class TalhaoListScreen extends StatefulWidget {
  final Property property;
  final TalhaoService talhaoService;
  final String userId;
  final Future<int> Function(String talhaoId)? getRecordCount;

  const TalhaoListScreen({
    super.key,
    required this.property,
    required this.talhaoService,
    required this.userId,
    this.getRecordCount,
  });

  @override
  State<TalhaoListScreen> createState() => _TalhaoListScreenState();
}

class _TalhaoListScreenState extends State<TalhaoListScreen> {
  List<Talhao> _talhoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTalhoes();
  }

  Future<void> _loadTalhoes() async {
    setState(() => _isLoading = true);
    try {
      final talhoes = widget.talhaoService.listByProperty(widget.property.id);
      setState(() {
        _talhoes = talhoes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToForm({Talhao? talhao}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TalhaoFormScreen(
          property: widget.property,
          talhao: talhao,
          talhaoService: widget.talhaoService,
          userId: widget.userId,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadTalhoes();
    }
  }

  Future<void> _deleteTalhao(Talhao talhao) async {
    final l10n = AgroLocalizations.of(context)!;

    // Check if talhão has records
    int recordCount = 0;
    if (widget.getRecordCount != null) {
      recordCount = await widget.getRecordCount!(talhao.id);
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.talhaoDeleteConfirm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.talhaoDeleteConfirmMsg),
            if (recordCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.talhaoDeleteWithRecords(recordCount),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.chuvaBotaoCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.talhaoDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.talhaoService.delete(talhao.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.talhaoDeleted)),
        );
        await _loadTalhoes();
      }
    } catch (e) {
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
        title: Text('${l10n.talhaoTitle} - ${widget.property.name}'),
      ),
      body: Column(
        children: [
          // Summary header
          if (widget.property.totalArea != null)
            Card(
              margin: const EdgeInsets.all(16),
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
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
                              Text(
                                '${widget.property.totalArea!.toStringAsFixed(1)} ha total',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_talhoes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildSummary(theme, l10n),
                    ],
                  ],
                ),
              ),
            ),

          // List of talhões
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _talhoes.isEmpty
                    ? _buildEmptyState(theme, l10n)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _talhoes.length,
                        itemBuilder: (context, index) {
                          final talhao = _talhoes[index];
                          return _buildTalhaoCard(talhao, theme, l10n);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.add),
        label: Text(l10n.talhaoAdd),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme, AgroLocalizations l10n) {
    final totalDividedArea =
        widget.talhaoService.getTotalAreaByProperty(widget.property.id);
    final propertyArea = widget.property.totalArea!;
    final percentage = (totalDividedArea / propertyArea * 100).clamp(0, 100);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.talhaoSummaryDivided(
                  totalDividedArea.toStringAsFixed(1),
                  propertyArea.toStringAsFixed(1),
                  percentage.toStringAsFixed(1),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: theme.colorScheme.primaryContainer,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, AgroLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.crop_free,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.talhaoListEmpty,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.talhaoListEmptyDesc,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalhaoCard(
      Talhao talhao, ThemeData theme, AgroLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToForm(talhao: talhao),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.crop_square,
                      color: theme.colorScheme.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          talhao.nome,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (talhao.cultura != null &&
                            talhao.cultura!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.grass,
                                size: 14,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                talhao.cultura!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Area badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${talhao.area.toStringAsFixed(1)} ha',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Actions row
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Record count (if available)
                  if (widget.getRecordCount != null)
                    FutureBuilder<int>(
                      future: widget.getRecordCount!(talhao.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data! > 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.talhaoWithRecords(snapshot.data!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                  // Edit button
                  TextButton.icon(
                    onPressed: () => _navigateToForm(talhao: talhao),
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(l10n.talhaoEdit),
                  ),

                  const SizedBox(width: 8),

                  // Delete button
                  TextButton.icon(
                    onPressed: () => _deleteTalhao(talhao),
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text(l10n.talhaoDelete),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
