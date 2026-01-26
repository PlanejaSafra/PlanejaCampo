import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/property_service.dart';

/// Shows a dialog prompting the user to name their property.
/// Returns true if user confirmed (with or without changes), false if skipped.
Future<bool> showPropertyNamePromptDialog(
  BuildContext context, {
  String? currentName,
  String? suggestionOverride,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PropertyNamePromptDialog(
      currentName: currentName,
      suggestionOverride: suggestionOverride,
    ),
  );
  return result ?? false;
}

/// Dialog widget for property naming onboarding.
class PropertyNamePromptDialog extends StatefulWidget {
  final String? currentName;
  final String? suggestionOverride;

  const PropertyNamePromptDialog({
    super.key,
    this.currentName,
    this.suggestionOverride,
  });

  @override
  State<PropertyNamePromptDialog> createState() =>
      _PropertyNamePromptDialogState();
}

class _PropertyNamePromptDialogState extends State<PropertyNamePromptDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentName ?? widget.suggestionOverride ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final propertyService = PropertyService();
      final defaultProperty = propertyService.getDefaultProperty();

      if (defaultProperty != null) {
        defaultProperty.updateName(_controller.text.trim());
        await propertyService.updateProperty(defaultProperty);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error saving property name: $e');
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.home_work, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(l10n.propertyNamePromptTitle),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.propertyNamePromptMessage,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: l10n.propertyNamePromptHint,
                prefixIcon: const Icon(Icons.edit),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.propertyNamePromptSkip),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.propertyNamePromptConfirm),
        ),
      ],
    );
  }
}

/// Checks if the default property has a generic name and should prompt.
bool shouldPromptForPropertyName() {
  final propertyService = PropertyService();
  final defaultProperty = propertyService.getDefaultProperty();

  if (defaultProperty == null) return false;

  final genericNames = [
    'Minha Propriedade',
    'My Property',
    'Property',
    'Propriedade',
  ];

  return genericNames.contains(defaultProperty.name);
}
