import 'package:hive/hive.dart';

part 'dependency_manifest.g.dart';

/// Persistent record of which entities are referenced by which apps.
///
/// Solves the "blind spot" problem (CORE-77 Section 15.1):
/// When an app is not installed, its DependencyCheckers aren't registered,
/// so the DependencyService wouldn't know about its references.
///
/// Each app updates its manifest when creating/deleting references to
/// shared structures (Talhão, Property, Parceiro). The manifest persists
/// in a shared Hive box, so even if the app is uninstalled, other apps
/// can still see that it has references.
///
/// Example:
/// ```dart
/// // RuraRain saves a chuva referencing talhao "tal-001"
/// await DependencyService.instance.addReference(
///   appId: 'rurarain',
///   targetType: 'talhao',
///   targetId: 'tal-001',
/// );
///
/// // Later, RuraRubber tries to delete talhao "tal-001"
/// // Even if RuraRain is not installed, the manifest shows the reference
/// final result = await DependencyService.instance.canDelete(
///   entityType: 'talhao',
///   entityId: 'tal-001',
///   requestingApp: 'rurarubber',
/// );
/// // result.canDelete == false (rurarain has references)
/// ```
@HiveType(typeId: 30)
class DependencyManifest extends HiveObject {
  /// The app that owns these references (e.g., "rurarain")
  @HiveField(0)
  final String appId;

  /// Map of entity type to list of referenced entity IDs.
  ///
  /// Example: { "talhao": ["tal-001", "tal-002"], "property": ["prop-001"] }
  ///
  /// Uses `List<String>` (not `Set`) because Hive doesn't natively serialize Sets.
  @HiveField(1)
  Map<String, List<String>> references;

  /// When this manifest was last updated
  @HiveField(2)
  DateTime updatedAt;

  DependencyManifest({
    required this.appId,
    required this.references,
    required this.updatedAt,
  });

  /// Create an empty manifest for an app
  factory DependencyManifest.empty(String appId) {
    return DependencyManifest(
      appId: appId,
      references: {},
      updatedAt: DateTime.now(),
    );
  }

  /// Add a reference from this app to a target entity
  void addReference(String targetType, String targetId) {
    references.putIfAbsent(targetType, () => []);
    if (!references[targetType]!.contains(targetId)) {
      references[targetType]!.add(targetId);
      updatedAt = DateTime.now();
    }
  }

  /// Remove a reference from this app to a target entity
  void removeReference(String targetType, String targetId) {
    if (references.containsKey(targetType)) {
      references[targetType]!.remove(targetId);
      if (references[targetType]!.isEmpty) {
        references.remove(targetType);
      }
      updatedAt = DateTime.now();
    }
  }

  /// Check if this app references a specific entity
  bool hasReference(String targetType, String targetId) {
    return references[targetType]?.contains(targetId) ?? false;
  }

  /// Get all entity IDs of a given type that this app references
  List<String> getReferences(String targetType) {
    return references[targetType] ?? [];
  }

  /// Get total count of references for a given type
  int getReferenceCount(String targetType) {
    return references[targetType]?.length ?? 0;
  }

  /// Get total count of all references across all types
  int get totalReferenceCount {
    return references.values.fold(0, (total, ids) => total + ids.length);
  }

  @override
  String toString() =>
      'DependencyManifest($appId, refs: ${references.length} types)';
}
