/// Result of checking whether an entity can be safely deleted.
///
/// Used by [DependencyService] to verify cross-app dependencies
/// before allowing deletion of shared structures (Layer 1 entities
/// like Talhão, Property, Parceiro).
///
/// See CORE-77 Section 4 for full architecture.
class DependencyCheckResult {
  /// Whether the entity can be deleted (no blockers from other apps)
  final bool canDelete;

  /// Map of apps that block deletion: {appId: [reasons]}
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'rurarain': ['12 registros de chuva'],
  ///   'ruracash': ['5 despesas vinculadas'],
  /// }
  /// ```
  final Map<String, List<String>> blockers;

  /// Optional warning about apps not currently installed
  /// (dependency check may be incomplete)
  final String? warning;

  const DependencyCheckResult({
    required this.canDelete,
    required this.blockers,
    this.warning,
  });

  /// Whether there are any blockers
  bool get hasBlockers => blockers.isNotEmpty;

  /// Whether there is a warning about incomplete checks
  bool get hasWarning => warning != null;

  /// Human-readable summary of blockers
  String get summary {
    if (blockers.isEmpty) return 'No dependencies found.';
    return blockers.entries
        .map((e) => '${e.key}: ${e.value.join(", ")}')
        .join('\n');
  }

  /// Total count of blocking references across all apps
  int get totalBlockingReferences {
    return blockers.values.fold(0, (sum, reasons) => sum + reasons.length);
  }

  /// Factory for a result with no blockers
  factory DependencyCheckResult.clear() {
    return const DependencyCheckResult(canDelete: true, blockers: {});
  }
}
