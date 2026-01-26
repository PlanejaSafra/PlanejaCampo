/// Mixin for entities that belong to a farm in the RuraCamp ecosystem.
///
/// All data entities (Pesagem, Entrega, Chuva, etc.) should implement this
/// mixin to enable multi-user support and dependency-aware backup/restore.
///
/// ## Key Concepts
///
/// - `farmId`: The farm that owns this data (UUID: "farm-{uuid}")
/// - `createdBy`: The user who created this record (audit trail for owner)
/// - `createdAt`: When the record was created
/// - `sourceApp`: The app that created this record (for backup isolation)
///
/// ## Ownership Rules (CORE-77 Section 16)
///
/// Data belongs to the FARM (via `farmId`), not to the individual who
/// created it. The farm owner (`farm.ownerId`) is the data controller:
///
/// - **Owner (Produtor)**: Full LGPD rights (delete, export) on farm data
/// - **Gerente**: NEVER an owner. Can only manage personal data
/// - **Sangrador (vinculado)**: NOT owner of the farm they work on
/// - **Sangrador (own farm)**: IS owner when managing their own farm
///
/// The `createdBy` field is an audit trail for the farm owner, NOT
/// personal data of the employee. The owner needs to know who created
/// each record in their farm.
///
/// ## Why sourceApp Matters (CORE-77)
///
/// In a multi-app ecosystem (RuraRubber, RuraRain, RuraCrop, RuraCash),
/// data can be created by different apps:
///
/// ```dart
/// // Despesa criada manualmente no RuraCash
/// Despesa(sourceApp: "ruracash", ...)
///
/// // Despesa criada automaticamente pelo RuraRubber (ao fechar entrega)
/// Despesa(sourceApp: "rurarubber", ...)
///
/// // RESTORE do RuraRubber:
/// // DELETE WHERE sourceApp = "rurarubber"
/// // ✅ Deleta despesas geradas pelo RuraRubber
/// // ✅ Mantém despesas manuais do RuraCash (sourceApp diferente)
/// ```
///
/// ## sourceApp Immutability (CORE-77 Section 15.5)
///
/// `sourceApp` is IMMUTABLE after creation. It defines permanent ownership
/// for backup/restore isolation. If another app edits a record, `sourceApp`
/// does NOT change. An optional `lastModifiedByApp` field can track edits.
///
/// ## Example Usage
///
/// ```dart
/// @HiveType(typeId: 5)
/// class Pesagem extends HiveObject with FarmOwnedMixin {
///   @HiveField(0)
///   final String id;
///
///   @override
///   @HiveField(1)
///   final String farmId;
///
///   @override
///   @HiveField(2)
///   final String createdBy;
///
///   @override
///   @HiveField(3)
///   final DateTime createdAt;
///
///   @override
///   @HiveField(4)
///   final String sourceApp;  // "rurarubber"
///
///   // ... other fields
/// }
/// ```
///
/// ## Migration Strategy
///
/// When adding FarmOwnedMixin to existing models:
/// 1. Add new HiveFields for farmId, createdBy, createdAt, sourceApp
/// 2. Make them nullable initially for backwards compatibility
/// 3. Run migration to populate existing records:
///    - farmId = defaultFarm.id (from FarmService)
///    - createdBy = currentUserId
///    - createdAt = existing timestamp or DateTime.now()
///    - sourceApp = current app identifier (e.g., "rurarubber")
/// 4. After migration, make fields required
///
/// ## See Also
///
/// - CORE-75: Farm-Centric Model (farmId, createdBy)
/// - CORE-77: Dependency-Aware Backup (sourceApp, restore isolation)
/// - CORE-77 Section 15: Critical fixes (DependencyManifest, batch API, etc.)
/// - CORE-77 Section 16: Ownership rules and LGPD multi-user
mixin FarmOwnedMixin {
  /// The farm that owns this data.
  /// This is the primary key for multi-user data isolation.
  ///
  /// Format: "farm-{uuid}" (e.g., "farm-a1b2c3d4-e5f6-7890-abcd-ef1234567890")
  String get farmId;

  /// The user who created this record.
  /// This is an AUDIT TRAIL for the farm owner, not personal data
  /// of the employee. The owner needs to know who registered each record.
  ///
  /// In multi-user scenarios:
  /// - Owner sees who created each record in their farm
  /// - Employee cannot delete this field (it belongs to the farm owner)
  /// - Employee can request to leave the farm, but records remain
  ///
  /// Format: Firebase Auth UID (e.g., "abc123xyz...")
  String get createdBy;

  /// When this record was created.
  DateTime get createdAt;

  // ═══════════════════════════════════════════════════════════════════════════
  // PLANNED: sourceApp (CORE-77)
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // The app that created this record. IMMUTABLE after creation.
  // Essential for:
  // - Backup isolation: Each app only touches its own data
  // - Cross-app data: Despesas geradas pelo RuraRubber vs manuais do RuraCash
  // - Restore safety: DELETE WHERE sourceApp = thisApp (não afeta outros apps)
  // - LGPD delete: Each app deletes only its own movements
  //
  // Values: "rurarubber", "rurarain", "ruracrop", "ruracash", etc.
  //
  // IMMUTABILITY RULE: sourceApp NEVER changes after creation.
  // If another app edits a record, sourceApp stays the same.
  // Use optional lastModifiedByApp for edit tracking.
  //
  // UNCOMMENT when implementing CORE-77:
  // String get sourceApp;
  // ═══════════════════════════════════════════════════════════════════════════
}

/// Abstract class for entities that belong to a farm.
///
/// Use this instead of the mixin when you need a common base type
/// for polymorphism (e.g., List<FarmOwnedEntity>).
///
/// Example:
/// ```dart
/// class Pesagem extends HiveObject implements FarmOwnedEntity {
///   // ... implementation
/// }
///
/// // Then you can do:
/// List<FarmOwnedEntity> allData = [...pesagens, ...entregas];
/// final farmData = allData.where((e) => e.farmId == currentFarmId);
/// ```
abstract class FarmOwnedEntity {
  /// Unique identifier for this entity
  String get id;

  /// The farm that owns this data
  String get farmId;

  /// The user who created this record (audit trail for farm owner)
  String get createdBy;

  /// When this record was created
  DateTime get createdAt;

  // PLANNED: sourceApp (CORE-77) - IMMUTABLE after creation
  // String get sourceApp;
}

/// Helper extension for FarmOwnedMixin
extension FarmOwnedExtension on FarmOwnedMixin {
  /// Check if this entity belongs to a specific farm
  bool belongsToFarm(String targetFarmId) => farmId == targetFarmId;

  /// Check if this entity was created by a specific user
  bool wasCreatedBy(String userId) => createdBy == userId;

  // PLANNED: sourceApp methods (CORE-77)
  //
  // /// Check if this entity was created by a specific app
  // bool wasCreatedByApp(String appId) => sourceApp == appId;
  //
  // /// Check if this entity can be deleted by a specific app
  // /// Only the app that created the entity can delete it
  // bool canBeDeletedBy(String appId) => sourceApp == appId;
}

/// Helper class for creating farm-owned entities.
///
/// Provides common logic for setting farmId and createdBy.
///
/// Usage:
/// ```dart
/// final helper = FarmOwnedHelper();
/// final farmId = helper.getCurrentFarmId();
/// final createdBy = helper.getCurrentUserId();
///
/// final pesagem = Pesagem(
///   farmId: farmId,
///   createdBy: createdBy,
///   createdAt: DateTime.now(),
///   // ... other fields
/// );
/// ```
class FarmOwnedHelper {
  /// Get the current user's default farm ID.
  /// Returns null if no default farm exists.
  ///
  /// Note: This requires FarmService to be initialized.
  /// Import FarmService and use: FarmService.instance.defaultFarmId
  static String? getCurrentFarmId() {
    // This is a placeholder - actual implementation imports FarmService
    // We avoid circular dependency by not importing FarmService here
    // Apps should use: FarmService.instance.defaultFarmId
    throw UnimplementedError(
      'Use FarmService.instance.defaultFarmId instead',
    );
  }

  /// Get the current user ID from Firebase Auth.
  /// Returns null if not authenticated.
  ///
  /// Note: This requires Firebase Auth to be initialized.
  /// Import firebase_auth and use: FirebaseAuth.instance.currentUser?.uid
  static String? getCurrentUserId() {
    // This is a placeholder - actual implementation imports firebase_auth
    // We avoid unnecessary dependency by not importing here
    // Apps should use: FirebaseAuth.instance.currentUser?.uid
    throw UnimplementedError(
      'Use FirebaseAuth.instance.currentUser?.uid instead',
    );
  }
}
