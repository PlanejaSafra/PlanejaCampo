import 'package:flutter/material.dart';

/// Helper to convert icon name strings to IconData.
/// CASH-21: Maps Categoria.icone (String) to Material Icons.
class CategoriaIconHelper {
  static const Map<String, IconData> _iconMap = {
    // Agro categories
    'engineering': Icons.engineering,
    'eco': Icons.eco,
    'science': Icons.science,
    'local_gas_station': Icons.local_gas_station,
    'build': Icons.build,
    'bolt': Icons.bolt,
    'category': Icons.category,

    // Personal categories
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'beach_access': Icons.beach_access,
    'home': Icons.home,
    'more_horiz': Icons.more_horiz,

    // Revenue categories
    'attach_money': Icons.attach_money,
    'agriculture': Icons.agriculture,
    'pets': Icons.pets,
    'shopping_cart': Icons.shopping_cart,
    'account_balance': Icons.account_balance,
    'work': Icons.work,
    'trending_up': Icons.trending_up,

    // Additional common icons
    'water_drop': Icons.water_drop,
    'grass': Icons.grass,
    'inventory': Icons.inventory,
    'handyman': Icons.handyman,
    'local_shipping': Icons.local_shipping,
    'receipt': Icons.receipt,
    'savings': Icons.savings,
    'credit_card': Icons.credit_card,
    'account_balance_wallet': Icons.account_balance_wallet,
  };

  /// Gets IconData from icon name string.
  /// Returns Icons.category as fallback.
  static IconData getIcon(String? iconName) {
    if (iconName == null) return Icons.category;
    return _iconMap[iconName] ?? Icons.category;
  }

  /// Gets all available icon names for category selection UI.
  static List<String> get availableIcons => _iconMap.keys.toList();

  /// Gets icon name from IconData (reverse lookup).
  static String? getIconName(IconData icon) {
    for (final entry in _iconMap.entries) {
      if (entry.value == icon) return entry.key;
    }
    return null;
  }
}
