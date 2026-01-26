import 'package:agro_core/agro_core.dart';
import 'package:hive/hive.dart';

part 'tabela_sangria.g.dart';

/// Tapping table (Tabela de Sangria) model for RuraRubber D3/D4 system.
///
/// Represents one table in the rubber tapping rotation. Producers divide
/// their trees into 3-5 tables and tap a different table each day.
///
/// Implements [FarmOwnedEntity] for multi-app/multi-user support:
/// - [farmId]: Which farm this table belongs to
/// - [createdBy]: Who created this record (audit trail)
/// - [createdAt]: When it was created
/// - [sourceApp]: Always "rurarubber" (immutable)
///
/// See RUBBER-23 for architecture.
@HiveType(typeId: 65)
class TabelaSangria extends HiveObject implements FarmOwnedEntity {
  @override
  @HiveField(0)
  final String id;

  /// The partner (sangrador) who owns this table set.
  @HiveField(1)
  final String parceiroId;

  /// Table number within the rotation (1, 2, 3, 4, or 5).
  @HiveField(2)
  int numero;

  /// Estimated tree count for this table (nullable - user may not know).
  @HiveField(3)
  int? arvoresEstimadas;

  /// Last date this table was tapped (for enforcada detection and suggestion).
  @HiveField(4)
  DateTime? lastTappedDate;

  // ═══════════════════════════════════════════════════════════════════════════
  // FarmOwnedEntity fields (CORE-77 / RUBBER-23)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Farm this table belongs to (required for multi-farm support).
  @override
  @HiveField(5)
  final String farmId;

  /// User who created this record (Firebase Auth UID).
  @override
  @HiveField(6)
  final String createdBy;

  /// When this record was created.
  @override
  @HiveField(7)
  final DateTime createdAt;

  /// App that created this record (always "rurarubber", immutable).
  @override
  @HiveField(8)
  final String sourceApp;

  TabelaSangria({
    required this.id,
    required this.parceiroId,
    required this.numero,
    this.arvoresEstimadas,
    this.lastTappedDate,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    this.sourceApp = 'rurarubber',
  });

  /// Factory for creating a new TabelaSangria with auto-filled metadata.
  ///
  /// Usage:
  /// ```dart
  /// final tabela = TabelaSangria.create(
  ///   id: uuid.v4(),
  ///   parceiroId: parceiro.id,
  ///   numero: 1,
  ///   arvoresEstimadas: 500,
  /// );
  /// ```
  factory TabelaSangria.create({
    required String id,
    required String parceiroId,
    required int numero,
    int? arvoresEstimadas,
  }) {
    return TabelaSangria(
      id: id,
      parceiroId: parceiroId,
      numero: numero,
      arvoresEstimadas: arvoresEstimadas,
      lastTappedDate: null,
      farmId: FarmService.instance.defaultFarmId ?? '',
      createdBy: AuthService.currentUser?.uid ?? '',
      createdAt: DateTime.now(),
      sourceApp: 'rurarubber',
    );
  }

  /// Convert to JSON for backup/export.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parceiroId': parceiroId,
      'numero': numero,
      'arvoresEstimadas': arvoresEstimadas,
      'lastTappedDate': lastTappedDate?.toIso8601String(),
      'farmId': farmId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'sourceApp': sourceApp,
    };
  }

  /// Create from JSON (backup/import).
  factory TabelaSangria.fromJson(Map<String, dynamic> json) {
    return TabelaSangria(
      id: json['id'] as String,
      parceiroId: json['parceiroId'] as String,
      numero: json['numero'] as int,
      arvoresEstimadas: json['arvoresEstimadas'] as int?,
      lastTappedDate: json['lastTappedDate'] != null
          ? DateTime.parse(json['lastTappedDate'] as String)
          : null,
      farmId: json['farmId'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      sourceApp: json['sourceApp'] as String? ?? 'rurarubber',
    );
  }

  /// Copy with new values (preserves immutable fields).
  TabelaSangria copyWith({
    int? numero,
    int? arvoresEstimadas,
    DateTime? lastTappedDate,
  }) {
    return TabelaSangria(
      id: id,
      parceiroId: parceiroId,
      numero: numero ?? this.numero,
      arvoresEstimadas: arvoresEstimadas ?? this.arvoresEstimadas,
      lastTappedDate: lastTappedDate ?? this.lastTappedDate,
      // Immutable fields preserved
      farmId: farmId,
      createdBy: createdBy,
      createdAt: createdAt,
      sourceApp: sourceApp,
    );
  }
}
