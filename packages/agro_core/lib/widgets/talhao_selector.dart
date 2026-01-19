import 'package:flutter/material.dart';
import '../models/talhao.dart';
import '../services/talhao_service.dart';
import '../l10n/generated/app_localizations.dart';

/// Widget for selecting a Talhão (Field Plot) from a property
///
/// Displays a dropdown with:
/// - "Propriedade toda" (whole property) as default option (null value)
/// - List of existing talhões in the property
/// - "+ Criar novo talhão" option to create a new talhão
class TalhaoSelector extends StatefulWidget {
  final String propertyId;
  final String? selectedTalhaoId;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onCreateNew;
  final TalhaoService talhaoService;
  final bool enabled;

  const TalhaoSelector({
    super.key,
    required this.propertyId,
    this.selectedTalhaoId,
    required this.onChanged,
    this.onCreateNew,
    required this.talhaoService,
    this.enabled = true,
  });

  @override
  State<TalhaoSelector> createState() => _TalhaoSelectorState();
}

class _TalhaoSelectorState extends State<TalhaoSelector> {
  List<Talhao> _talhoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTalhoes();
  }

  @override
  void didUpdateWidget(TalhaoSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.propertyId != widget.propertyId) {
      _loadTalhoes();
    }
  }

  Future<void> _loadTalhoes() async {
    setState(() => _isLoading = true);
    try {
      final talhoes = widget.talhaoService.listByProperty(widget.propertyId);
      setState(() {
        _talhoes = talhoes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Refresh talhões list (call after creating/editing)
  Future<void> refresh() async {
    await _loadTalhoes();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.talhaoSelectOptional,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.talhaoSelectOptional,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: widget.selectedTalhaoId,
              isExpanded: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: widget.selectedTalhaoId != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: widget.enabled
                            ? () => widget.onChanged(null)
                            : null,
                        tooltip: l10n.talhaoWholeProperty,
                      )
                    : null,
              ),
              items: [
                // Option 1: Whole property (null value)
                DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.talhaoWholeProperty,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                if (_talhoes.isNotEmpty)
                  const DropdownMenuItem<String?>(
                    enabled: false,
                    value: '__divider__',
                    child: Divider(height: 1),
                  ),

                // Option 2-N: Existing talhões
                ..._talhoes.map((talhao) => DropdownMenuItem<String?>(
                      value: talhao.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.crop_square,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              talhao.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),

                // Divider before create option
                if (widget.onCreateNew != null)
                  const DropdownMenuItem<String?>(
                    enabled: false,
                    value: '__divider2__',
                    child: Divider(height: 1),
                  ),

                // Option N+1: Create new talhão
                if (widget.onCreateNew != null)
                  DropdownMenuItem<String?>(
                    value: '__create_new__',
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.talhaoCreateNew,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: widget.enabled
                  ? (value) {
                      if (value == '__create_new__') {
                        widget.onCreateNew?.call();
                      } else if (value != '__divider__' && value != '__divider2__') {
                        widget.onChanged(value);
                      }
                    }
                  : null,
            ),

            // Show empty state hint if no talhões
            if (_talhoes.isEmpty && widget.onCreateNew != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.talhaoListEmptyDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
