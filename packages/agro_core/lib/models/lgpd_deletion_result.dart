/// Result of an LGPD data deletion operation.
///
/// Used by [DataDeletionService] to report what was deleted,
/// what was skipped (due to cross-app dependencies), and any errors.
///
/// See CORE-77 Section 9 for multi-app LGPD architecture.
class LgpdDeletionResult {
  /// Whether the deletion operation completed without errors
  final bool success;

  /// Number of entities deleted
  final int deletedCount;

  /// Number of entities skipped (protected by cross-app dependencies)
  final int skippedCount;

  /// Details of what was deleted (for audit log / user display)
  final List<String> deletedDetails;

  /// Details of what was skipped and why
  final List<String> skippedDetails;

  /// Errors encountered during deletion
  final List<String> errors;

  const LgpdDeletionResult({
    required this.success,
    this.deletedCount = 0,
    this.skippedCount = 0,
    this.deletedDetails = const [],
    this.skippedDetails = const [],
    this.errors = const [],
  });

  /// Factory for a fully successful deletion with no items
  factory LgpdDeletionResult.empty() {
    return const LgpdDeletionResult(success: true);
  }

  /// Merge multiple results into one (for multi-provider deletion)
  factory LgpdDeletionResult.merge(List<LgpdDeletionResult> results) {
    if (results.isEmpty) return LgpdDeletionResult.empty();

    return LgpdDeletionResult(
      success: results.every((r) => r.success),
      deletedCount: results.fold(0, (total, r) => total + r.deletedCount),
      skippedCount: results.fold(0, (total, r) => total + r.skippedCount),
      deletedDetails:
          results.expand((r) => r.deletedDetails).toList(),
      skippedDetails:
          results.expand((r) => r.skippedDetails).toList(),
      errors: results.expand((r) => r.errors).toList(),
    );
  }

  /// Whether any entities were skipped
  bool get hasSkipped => skippedCount > 0;

  /// Whether any errors occurred
  bool get hasErrors => errors.isNotEmpty;

  /// Total entities processed (deleted + skipped)
  int get totalProcessed => deletedCount + skippedCount;

  @override
  String toString() =>
      'LgpdDeletionResult(success: $success, deleted: $deletedCount, '
      'skipped: $skippedCount, errors: ${errors.length})';
}
