import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/property.dart';
import '../services/property_service.dart';

/// Screen for creating or editing a property.
class PropertyFormScreen extends StatefulWidget {
  final Property? property;

  const PropertyFormScreen({super.key, this.property});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final _propertyService = PropertyService();
  bool _isLoading = false;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _nameController.text = widget.property!.name;
      _areaController.text = widget.property!.totalArea?.toString() ?? '';
      _latController.text = widget.property!.latitude?.toString() ?? '';
      _lngController.text = widget.property!.longitude?.toString() ?? '';
      _isDefault = widget.property!.isDefault;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permissão de localização negada';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permissão de localização negada permanentemente. Habilite nas configurações.';
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao obter GPS: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _openGoogleMaps() async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    final Uri url;
    if (lat != null && lng != null) {
      // Open at specific location
      url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      // Search by name logic or just open maps
      // If name is typed, search 'name property'
      final query =
          _nameController.text.isNotEmpty ? _nameController.text : 'Brasil';
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o mapa.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final area = _areaController.text.isEmpty
          ? null
          : double.tryParse(_areaController.text);
      final lat = _latController.text.isEmpty
          ? null
          : double.tryParse(_latController.text);
      final lng = _lngController.text.isEmpty
          ? null
          : double.tryParse(_lngController.text);

      if (widget.property == null) {
        // Create new property
        await _propertyService.createProperty(
          name: name,
          totalArea: area,
          latitude: lat,
          longitude: lng,
          isDefault: _isDefault,
        );
      } else {
        // Update existing property
        widget.property!.updateName(name);
        widget.property!.updateTotalArea(area);
        widget.property!.updateLocation(lat, lng);

        if (_isDefault != widget.property!.isDefault) {
          if (_isDefault) {
            await _propertyService.setAsDefault(widget.property!.id);
          }
          widget.property!.isDefault = _isDefault;
        }

        await _propertyService.updateProperty(widget.property!);
      }

      if (mounted) {
        final l10n = AgroLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.property == null
                  ? l10n.propertySaved
                  : l10n.propertyUpdated,
            ),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEditing = widget.property != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.propertyEdit : l10n.propertyAdd),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.propertyName,
                hintText: l10n.propertyNameHint,
                prefixIcon: const Icon(Icons.agriculture),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.propertyNameRequired;
                }
                if (value.trim().length < 2) {
                  return l10n.propertyNameTooShort;
                }
                // Check for duplicate name
                if (_propertyService.propertyNameExists(
                  value.trim(),
                  excludeId: widget.property?.id,
                )) {
                  return l10n.propertyNameExists;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Total area field
            TextFormField(
              controller: _areaController,
              decoration: InputDecoration(
                labelText: l10n.propertyTotalArea,
                hintText: l10n.propertyTotalAreaHint,
                prefixIcon: const Icon(Icons.straighten),
                border: const OutlineInputBorder(),
                suffixText: 'ha',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final area = double.tryParse(value);
                  if (area == null || area <= 0) {
                    return l10n.propertyAreaInvalid;
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Location section
            Text(
              l10n.propertyLocation,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.propertyLocationDesc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),

            // Location Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Usar GPS Atual'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openGoogleMaps,
                    icon: const Icon(Icons.map),
                    label: const Text('Abrir Mapa'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Latitude field
            TextFormField(
              controller: _latController,
              decoration: InputDecoration(
                labelText: 'Latitude',
                hintText: 'Ex: -23.5505',
                prefixIcon: const Icon(Icons.location_on),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d{0,6}')),
              ],
            ),
            const SizedBox(height: 12),

            // Longitude field
            TextFormField(
              controller: _lngController,
              decoration: InputDecoration(
                labelText: 'Longitude',
                hintText: 'Ex: -46.6333',
                prefixIcon: const Icon(Icons.location_on),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d{0,6}')),
              ],
            ),
            const SizedBox(height: 16),

            // Default property checkbox
            CheckboxListTile(
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value ?? false),
              title: Text(l10n.propertySetAsDefault),
              subtitle: Text(l10n.propertyIsDefault),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: _isLoading ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.chuvaBotaoSalvar),
            ),
          ],
        ),
      ),
    );
  }
}
