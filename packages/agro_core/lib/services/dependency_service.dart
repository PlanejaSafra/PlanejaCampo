import 'package:hive_flutter/hive_flutter.dart';

import '../models/dependency_check_result.dart';
import '../models/dependency_manifest.dart';

/// Callback for counting references to a target entity.
typedef CountReferencesCallback = Future<int> Function(String targetId);

/// Callback for counting references to multiple target entities (batch).
typedef CountReferencesBatchCallback = Future<Map<String, int>> Function(
  List<String> targetIds,
);

/// A dependency checker registered by an app to track its references
/// to shared structures (Talhão, Property, Parceiro).
///
/// Each app registers checkers during initialization so that
/// the DependencyService can verify cross-app dependencies
/// before allowing deletion of shared entities.
///
/// Example:
/// ```dart
/// DependencyService.instance.registerChecker(
///   DependencyChecker(
///     sourceApp: 'rurarubber',
///     sourceType: 'pesagem',
///     targetType: 'talhao',
///     referenceDescription: 'pesagens registradas',
///     countReferences: (talhaoId) async {
///       return pesagemBox.values
///           .where((p) => p.talhaoId == talhaoId)
///           .length;
///     },
///   ),
/// );
/// ```
class DependencyChecker {
  /// The app that owns these references (e.g., "rurarubber")
  final String sourceApp;

  /// The type of entity that holds the reference (e.g., "pesagem")
  final String sourceType;

  /// The type of entity being referenced (e.g., "talhao")
  final String targetType;

  /// Human-readable description of the reference (e.g., "pesagens registradas")
  final String referenceDescription;

  /// Count references from a single entity
  final CountReferencesCallback countReferences;

  /// Count references from multiple entities (batch, for performance).
  /// If null, falls back to calling [countReferences] in a loop.
  final CountReferencesBatchCallback? countReferencesBatch;

  DependencyChecker({
    required this.sourceApp,
    required this.sourceType,
    required this.targetType,
    required this.referenceDescription,
    required this.countReferences,
    this.countReferencesBatch,
  });
}

/// Service that tracks cross-app dependencies on shared structures.
///
/// Combines two data sources:
/// 1. **Live checkers**: Registered by running apps (real-time counts)
/// 2. **Persisted manifests**: Stored in Hive (survives app uninstall)
///
/// This solves the "blind spot" problem where an uninstalled app's
/// references would be invisible to other apps.
///
/// See CORE-77 Sections 4 and 15.1 for full architecture.
class DependencyService {
  static const String _manifestBoxName = 'dependency_manifests';

  // Singleton
  static final DependencyService _instance = DependencyService._();
  static DependencyService get instance => _instance;
  DependencyService._();

  /// Live checkers registered by running apps
  final _checkers = <String, List<DependencyChecker>>{};

  late Box<DependencyManifest> _manifestBox;
  bool _initialized = false;

  /// Initialize the service (opens Hive box for manifests).
  /// Must be called during app startup.
  Future<void> init() async {
    if (_initialized) return;
    _manifestBox = await Hive.openBox<DependencyManifest>(_manifestBoxName);
    _initialized = true;
  }

  /// Whether the service has been initialized
  bool get isInitialized => _initialized;

  /// List of app IDs that have persisted manifests.
  /// Used by DataExportService for LGPD cross-app reference export.
  List<String> get registeredApps {
    if (!_initialized) return [];
    return _manifestBox.keys.cast<String>().toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Live Checker Registration
  // ═══════════════════════════════════════════════════════════════════════════

  /// Register a dependency checker for an app.
  /// Call this during app initialization (main.dart).
  void registerChecker(DependencyChecker checker) {
    _checkers
        .putIfAbsent(checker.targetType, () => [])
        .add(checker);
  }

  /// Remove all checkers for a specific app.
  /// Call this when cleaning up (e.g., during testing).
  void unregisterApp(String appId) {
    for (final checkers in _checkers.values) {
      checkers.removeWhere((c) => c.sourceApp == appId);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dependency Checking
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if an entity can be safely deleted.
  ///
  /// Checks both live checkers (running apps) and persisted manifests
  /// (offline apps) to ensure no cross-app dependencies are broken.
  ///
  /// [entityType]: Type of entity to check (e.g., "talhao", "property")
  /// [entityId]: ID of the specific entity
  /// [requestingApp]: The app requesting deletion (won't block itself)
  Future<DependencyCheckResult> canDelete({
    required String entityType,
    required String entityId,
    required String requestingApp,
  }) async {
    final blockers = <String, List<String>>{};
    String? warning;

    // 1. Check live checkers (apps currently running)
    final checkedApps = <String>{requestingApp};
    for (final checker in _checkers[entityType] ?? []) {
      if (checker.sourceApp == requestingApp) continue;
      checkedApps.add(checker.sourceApp);

      final count = await checker.countReferences(entityId);
      if (count > 0) {
        blockers.putIfAbsent(checker.sourceApp, () => []).add(
          '$count ${checker.referenceDescription}',
        );
      }
    }

    // 2. Check persisted manifests (apps that may not be running)
    if (_initialized) {
      for (final manifest in _manifestBox.values) {
        if (manifest.appId == requestingApp) continue;
        if (checkedApps.contains(manifest.appId)) continue;

        // This app has a manifest but no live checker — it may be uninstalled
        if (manifest.hasReference(entityType, entityId)) {
          blockers.putIfAbsent(manifest.appId, () => []).add(
            'has references (app not running)',
          );
          warning ??=
              'Some apps with references are not currently running. '
              'Dependency check may be incomplete.';
        }
      }
    }

    return DependencyCheckResult(
      canDelete: blockers.isEmpty,
      blockers: blockers,
      warning: warning,
    );
  }

  /// Batch check: can multiple entities of the same type be deleted?
  ///
  /// More efficient than calling [canDelete] in a loop because it
  /// uses batch APIs when available.
  Future<Map<String, DependencyCheckResult>> canDeleteBatch({
    required String entityType,
    required List<String> entityIds,
    required String requestingApp,
  }) async {
    final results = <String, DependencyCheckResult>{};

    // For each checker, try batch first, then fallback to individual
    final allBlockers = <String, Map<String, List<String>>>{};
    final checkedApps = <String>{requestingApp};

    for (final id in entityIds) {
      allBlockers[id] = {};
    }

    // 1. Live checkers
    for (final checker in _checkers[entityType] ?? []) {
      if (checker.sourceApp == requestingApp) continue;
      checkedApps.add(checker.sourceApp);

      Map<String, int> counts;
      if (checker.countReferencesBatch != null) {
        counts = await checker.countReferencesBatch!(entityIds);
      } else {
        counts = {};
        for (final id in entityIds) {
          counts[id] = await checker.countReferences(id);
        }
      }

      for (final entry in counts.entries) {
        if (entry.value > 0) {
          allBlockers[entry.key]!
              .putIfAbsent(checker.sourceApp, () => [])
              .add('${entry.value} ${checker.referenceDescription}');
        }
      }
    }

    // 2. Persisted manifests
    String? warning;
    if (_initialized) {
      for (final manifest in _manifestBox.values) {
        if (manifest.appId == requestingApp) continue;
        if (checkedApps.contains(manifest.appId)) continue;

        for (final id in entityIds) {
          if (manifest.hasReference(entityType, id)) {
            allBlockers[id]!
                .putIfAbsent(manifest.appId, () => [])
                .add('has references (app not running)');
            warning ??=
                'Some apps with references are not currently running.';
          }
        }
      }
    }

    // Build results
    for (final id in entityIds) {
      final blockers = allBlockers[id]!;
      results[id] = DependencyCheckResult(
        canDelete: blockers.isEmpty,
        blockers: blockers,
        warning: warning,
      );
    }

    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Manifest Persistence
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record that an app references a shared entity.
  ///
  /// Call this whenever an app creates a record that references a shared
  /// structure (e.g., when saving a Chuva that references a Talhão).
  Future<void> addReference({
    required String appId,
    required String targetType,
    required String targetId,
  }) async {
    if (!_initialized) return;

    var manifest = _manifestBox.get(appId);
    if (manifest == null) {
      manifest = DependencyManifest.empty(appId);
      manifest.addReference(targetType, targetId);
      await _manifestBox.put(appId, manifest);
    } else {
      manifest.addReference(targetType, targetId);
      await manifest.save();
    }
  }

  /// Remove a reference from an app to a shared entity.
  ///
  /// Call this whenever an app deletes a record that referenced a shared
  /// structure.
  Future<void> removeReference({
    required String appId,
    required String targetType,
    required String targetId,
  }) async {
    if (!_initialized) return;

    final manifest = _manifestBox.get(appId);
    if (manifest != null) {
      manifest.removeReference(targetType, targetId);
      await manifest.save();
    }
  }

  /// Get the manifest for a specific app (for debugging/testing)
  DependencyManifest? getManifest(String appId) {
    if (!_initialized) return null;
    return _manifestBox.get(appId);
  }

  /// Remove all references for a specific app.
  ///
  /// Used during LGPD deletion to clean up the manifest
  /// after an app's data has been deleted.
  Future<void> removeAllReferencesForApp(String appId) async {
    if (!_initialized) return;

    final manifest = _manifestBox.get(appId);
    if (manifest != null) {
      await _manifestBox.delete(appId);
    }
  }

  /// Clear all manifests (for testing only)
  Future<void> clearAllManifests() async {
    if (!_initialized) return;
    await _manifestBox.clear();
  }
}
