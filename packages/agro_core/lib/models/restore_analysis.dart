import 'backup_meta.dart';
import 'dependency_check_result.dart';

/// Represents a single planned action during restore.
///
/// Used to build the restore report shown to the user before execution.
class RestoreAction {
  /// Type of entity (e.g., "pesagem", "entrega", "talhao")
  final String entityType;

  /// Unique ID of the entity
  final String entityId;

  /// Human-readable description (e.g., "Pesagem 45.5kg - 20/01/2026")
  final String description;

  const RestoreAction({
    required this.entityType,
    required this.entityId,
    required this.description,
  });

  @override
  String toString() => 'RestoreAction($entityType: $description)';
}

/// Ownership level of the user relative to the backup farm.
///
/// Determines what data can be restored:
/// - [owner]: Full restore — all farm data
/// - [member]: Only personal data (future multi-user)
/// - [noAccess]: Restore blocked — user has no right to this farm's data
///
/// See CORE-77 Section 16 for ownership rules.
enum RestoreFarmAccess {
  /// User is the farm owner — full restore allowed
  owner,

  /// User is a member (gerente/sangrador) — personal data only (future)
  member,

  /// User has no access to this farm — restore blocked
  noAccess,
}

/// Result of analyzing a backup before executing the restore.
///
/// Generated during Phase 1 (Analysis) of the 3-phase restore process.
/// Presented to the user during Phase 2 (Confirmation) via
/// [RestoreConfirmationDialog].
///
/// ## Ownership Check (CORE-77 Section 16)
///
/// The [farmAccess] field controls what can be restored:
/// - **owner**: Full restore of all farm data
/// - **member**: Only personal data (future multi-user)
/// - **noAccess**: Restore blocked entirely (e.g., left the farm)
///
/// Example: A sangrador who left a farm reinstalls the app.
/// Their cloud backup contains the previous owner's farm data.
/// The restore must be blocked — they no longer have access.
///
/// See CORE-77 Section 5 for full architecture.
class RestoreAnalysis {
  /// Metadata from the backup being restored
  final BackupMeta meta;

  /// User's access level to the backup farm.
  /// Determines whether restore can proceed and what data is included.
  final RestoreFarmAccess farmAccess;

  /// Entities in the backup that don't exist locally — will be added
  final List<RestoreAction> toAdd;

  /// Local entities not in the backup — will be deleted
  /// (only for sourceApp-matching data)
  final List<RestoreAction> toDelete;

  /// Entities that cannot be deleted due to cross-app dependencies.
  /// Key: entity ID, Value: the dependency check result explaining why
  final Map<String, DependencyCheckResult> blocked;

  /// Entities that exist in both backup and local with different data.
  /// User may need to choose which version to keep.
  final List<RestoreAction> conflicts;

  /// Non-blocking informational messages for the user
  final List<String> warnings;

  /// Derived data that needs recalculation after restore
  /// (e.g., "Saldo com parceiros", "Total de produção por safra")
  final List<String> recalculations;

  RestoreAnalysis({
    required this.meta,
    this.farmAccess = RestoreFarmAccess.owner,
    this.toAdd = const [],
    this.toDelete = const [],
    this.blocked = const {},
    this.conflicts = const [],
    this.warnings = const [],
    this.recalculations = const [],
  });

  /// Whether the restore can proceed.
  ///
  /// Returns false if the user has no access to the backup farm.
  /// Blocked items are simply skipped (not blockers).
  bool get canProceed => farmAccess != RestoreFarmAccess.noAccess;

  /// Whether the user is the farm owner (full restore rights)
  bool get isOwnerRestore => farmAccess == RestoreFarmAccess.owner;

  /// Count of entities that will be added
  int get addCount => toAdd.length;

  /// Count of entities that will be deleted
  int get deleteCount => toDelete.length;

  /// Count of entities blocked from deletion
  int get blockedCount => blocked.length;

  /// Count of conflicts requiring resolution
  int get conflictCount => conflicts.length;

  /// Whether this restore has any blocked deletions
  bool get hasBlocked => blocked.isNotEmpty;

  /// Whether this restore has any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Whether this restore requires recalculations
  bool get hasRecalculations => recalculations.isNotEmpty;

  /// Whether the backup farm differs from the current farm
  bool isFarmDifferent(String currentFarmId) =>
      meta.farmId.isNotEmpty && meta.farmId != currentFarmId;

  /// Summary for logging/debugging
  @override
  String toString() =>
      'RestoreAnalysis(access: $farmAccess, add: $addCount, '
      'delete: $deleteCount, blocked: $blockedCount, '
      'conflicts: $conflictCount)';
}

/// Result of post-restore recalculation.
///
/// Each app implements its own recalculation logic
/// (e.g., recalculating partner balances, production totals).
class RecalculationResult {
  /// Whether all recalculations succeeded
  final bool success;

  /// Human-readable details of what was recalculated
  final List<String> details;

  const RecalculationResult({
    required this.success,
    required this.details,
  });

  /// Factory for a successful no-op result
  factory RecalculationResult.empty() {
    return const RecalculationResult(success: true, details: []);
  }

  @override
  String toString() =>
      'RecalculationResult(success: $success, details: ${details.length})';
}
