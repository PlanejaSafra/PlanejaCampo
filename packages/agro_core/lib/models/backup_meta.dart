/// Metadata about a backup, embedded in the backup JSON as '_meta'.
///
/// Every backup file starts with a _meta section that identifies:
/// - Which app created it (appId)
/// - Which farm it belongs to (farmId)
/// - Who created it (userId)
/// - What scope it covers (personal vs full)
///
/// Used by the 3-phase restore process (CORE-77) to determine
/// how to handle the restore safely.
class BackupMeta {
  /// App identifier (e.g., "rurarubber", "rurarain", "ruracash")
  final String appId;

  /// App version when backup was created (e.g., "1.2.0")
  final String appVersion;

  /// Type of backup: "app" (single app) or "full" (all apps)
  final String backupType;

  /// Scope of backup:
  /// - "personal": Only data created by the user (createdBy = userId)
  /// - "full": All data from the app (owner only)
  final String backupScope;

  /// Farm ID this backup belongs to
  final String farmId;

  /// User who created the backup (Firebase Auth UID)
  final String userId;

  /// When the backup was created
  final DateTime createdAt;

  /// Schema version for migration compatibility.
  /// Increment when the backup format changes.
  final int schemaVersion;

  BackupMeta({
    required this.appId,
    required this.appVersion,
    required this.backupType,
    required this.backupScope,
    required this.farmId,
    required this.userId,
    required this.createdAt,
    required this.schemaVersion,
  });

  /// Convert to JSON Map for inclusion in backup file
  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'appVersion': appVersion,
      'backupType': backupType,
      'backupScope': backupScope,
      'farmId': farmId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'schemaVersion': schemaVersion,
    };
  }

  /// Create from JSON Map (from backup file)
  factory BackupMeta.fromJson(Map<String, dynamic> json) {
    return BackupMeta(
      appId: json['appId'] as String? ?? 'unknown',
      appVersion: json['appVersion'] as String? ?? '0.0.0',
      backupType: json['backupType'] as String? ?? 'app',
      backupScope: json['backupScope'] as String? ?? 'personal',
      farmId: json['farmId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }

  /// Validate that this backup is compatible with the current app.
  ///
  /// Returns true if:
  /// - The appId matches the current app
  /// - The schemaVersion is not newer than what we support
  bool isCompatible({
    required String currentAppId,
    required int currentSchemaVersion,
  }) {
    if (appId != currentAppId) return false;
    if (schemaVersion > currentSchemaVersion) return false;
    return true;
  }

  /// Check if this is a full-scope backup (owner only)
  bool get isFullScope => backupScope == 'full';

  /// Check if this is a personal-scope backup
  bool get isPersonalScope => backupScope == 'personal';

  @override
  String toString() =>
      'BackupMeta($appId v$appVersion, scope: $backupScope, farm: $farmId)';
}
