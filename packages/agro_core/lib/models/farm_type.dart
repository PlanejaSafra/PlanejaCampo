import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'farm_type.g.dart';

/// Farm type: agro (rural/business) or personal (household finance).
///
/// Used by CASH-09 to separate farm expenses from personal expenses.
@HiveType(typeId: 22)
enum FarmType {
  @HiveField(0)
  agro,

  @HiveField(1)
  personal;

  /// Icon for the farm type.
  IconData get icon {
    switch (this) {
      case FarmType.agro:
        return Icons.agriculture;
      case FarmType.personal:
        return Icons.person;
    }
  }

  /// Localized display name via AgroLocalizations.
  String localizedName(dynamic l10n) {
    switch (this) {
      case FarmType.agro:
        return l10n.farmTypeAgro;
      case FarmType.personal:
        return l10n.farmTypePersonal;
    }
  }
}
