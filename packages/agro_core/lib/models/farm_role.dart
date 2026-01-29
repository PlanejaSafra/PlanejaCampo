import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'farm_role.g.dart';

/// Role of a user within a farm.
///
/// Determines permissions and UI affordances for multi-farm collaboration.
///
/// - [owner]: Full control. Can invite/remove members, toggle sharing, delete farm.
/// - [manager]: Can manage records and invite workers. Cannot delete farm or remove owner.
/// - [worker]: Read/write own records. Cannot manage members or farm settings.
///
/// See CORE-90 for architecture.
@HiveType(typeId: 23)
enum FarmRole {
  @HiveField(0)
  owner,

  @HiveField(1)
  manager,

  @HiveField(2)
  worker;

  /// Icon representing this role.
  IconData get icon {
    switch (this) {
      case FarmRole.owner:
        return Icons.star;
      case FarmRole.manager:
        return Icons.manage_accounts;
      case FarmRole.worker:
        return Icons.person;
    }
  }

  /// Localized display name via AgroLocalizations.
  String localizedName(dynamic l10n) {
    switch (this) {
      case FarmRole.owner:
        return l10n.farmRoleOwner;
      case FarmRole.manager:
        return l10n.farmRoleManager;
      case FarmRole.worker:
        return l10n.farmRoleWorker;
    }
  }

  /// Localized description via AgroLocalizations.
  String localizedDescription(dynamic l10n) {
    switch (this) {
      case FarmRole.owner:
        return l10n.farmRoleOwnerDesc;
      case FarmRole.manager:
        return l10n.farmRoleManagerDesc;
      case FarmRole.worker:
        return l10n.farmRoleWorkerDesc;
    }
  }

  /// Color associated with this role for UI badges.
  Color get color {
    switch (this) {
      case FarmRole.owner:
        return const Color(0xFFF9A825); // Amber
      case FarmRole.manager:
        return const Color(0xFF1565C0); // Blue
      case FarmRole.worker:
        return const Color(0xFF2E7D32); // Green
    }
  }
}
