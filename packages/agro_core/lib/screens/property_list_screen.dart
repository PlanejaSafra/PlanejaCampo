import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/property.dart';
import '../services/property_service.dart';
import 'property_form_screen.dart';

/// Screen to list and manage user's properties (farms/rural properties).
/// Allows creating, editing, deleting, and setting default property.
class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final _propertyService = PropertyService();
  List<Property> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final properties = _propertyService.getAllProperties();
      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar propriedades: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _navigateToForm({Property? property}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyFormScreen(property: property),
      ),
    );

    // Reload list if form returned true (saved)
    if (result == true && mounted) {
      await _loadProperties();
    }
  }

  Future<void> _setAsDefault(Property property) async {
    try {
      await _propertyService.setAsDefault(property.id);
      await _loadProperties();
      if (mounted) {
        final l10n = AgroLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${property.name} definida como padrão'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
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

  Future<void> _deleteProperty(Property property) async {
    final l10n = AgroLocalizations.of(context)!;

    // Check if this is the only property
    if (_properties.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.propertyCannotDeleteLast),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    // Check if this is the default property
    if (property.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.propertyCannotDeleteDefault),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.propertyDelete),
        content: Text(l10n.propertyDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.chuvaBotaoCancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.chuvaBotaoExcluir),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _propertyService.deleteProperty(property.id);
        await _loadProperties();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.propertyDeleted),
              backgroundColor: Colors.green[700],
            ),
          );
        }
      } catch (e) {
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
  }

  void _showPropertyOptions(Property property) {
    final l10n = AgroLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit Property
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.propertyEdit),
              onTap: () {
                Navigator.pop(context);
                _navigateToForm(property: property);
              },
            ),
            // Manage Talhões (NEW)
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('Gerenciar Talhões'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/talhoes',
                  arguments: property.id,
                );
              },
            ),
            if (!property.isDefault)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(l10n.propertySetAsDefault),
                onTap: () {
                  Navigator.pop(context);
                  _setAsDefault(property);
                },
              ),
            if (_properties.length > 1 && !property.isDefault)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  l10n.propertyDelete,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProperty(property);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.propertyTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? _buildEmptyState(l10n)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final property = _properties[index];
                    return _buildPropertyCard(property, theme, l10n);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(AgroLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.agriculture_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.propertyNoProperties,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.propertyNoPropertiesDesc,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(
    Property property,
    ThemeData theme,
    AgroLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        // UX Change: Tap now goes directly to Talhões (drill down)
        onTap: () {
          Navigator.pushNamed(
            context,
            '/talhoes',
            arguments: property.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Property Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: property.isDefault
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.agriculture,
                  size: 32,
                  color: property.isDefault
                      ? theme.colorScheme.primary
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),

              // Property Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            property.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (property.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.propertyDefaultBadge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.totalArea != null
                          ? '${property.totalArea!.toStringAsFixed(1)} ha'
                          : 'Área não definida',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Call to Action for Talhões
                    Row(
                      children: [
                        Icon(Icons.grid_view,
                            size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Gerenciar Talhões',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions Menu (Edit, Delete, etc)
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showPropertyOptions(property),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
