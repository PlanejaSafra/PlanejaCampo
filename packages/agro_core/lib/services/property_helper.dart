import '../models/property.dart';
import 'property_service.dart';

/// Helper class for property-related UI operations.
/// Provides cached property lookups and utility methods.
class PropertyHelper {
  static final PropertyHelper _instance = PropertyHelper._internal();
  factory PropertyHelper() => _instance;
  PropertyHelper._internal();

  final _propertyService = PropertyService();
  final Map<String, String> _nameCache = {};

  /// Get property name by ID (with caching).
  /// Returns "Propriedade Desconhecida" if property not found.
  String getPropertyName(String propertyId, {String fallback = 'Propriedade Desconhecida'}) {
    // Check cache first
    if (_nameCache.containsKey(propertyId)) {
      return _nameCache[propertyId]!;
    }

    // Fetch from service
    final property = _propertyService.getPropertyById(propertyId);
    if (property != null) {
      _nameCache[propertyId] = property.name;
      return property.name;
    }

    return fallback;
  }

  /// Get property by ID
  Property? getProperty(String propertyId) {
    return _propertyService.getPropertyById(propertyId);
  }

  /// Clear name cache (call when properties are modified)
  void clearCache() {
    _nameCache.clear();
  }

  /// Prefetch all property names into cache
  void prefetchNames() {
    final properties = _propertyService.getAllProperties();
    for (final property in properties) {
      _nameCache[property.id] = property.name;
    }
  }
}
