import 'package:agro_core/agro_core.dart';
import 'package:hive/hive.dart';

part 'registro_chuva.g.dart';

/// Rainfall record model for RuraRain.
///
/// Uses [FarmOwnedMixin] for multi-app/multi-user support:
/// - [farmId]: Maps to propertyId (which farm/property this record belongs to)
/// - [createdBy]: Who created this record (audit trail)
/// - [createdAt]: When it was created (maps to criadoEm)
/// - [sourceApp]: Always "rurarain" (immutable)
///
/// NOTE: Uses mixin instead of FarmOwnedEntity because id is int, not String.
///
/// See CORE-77 and RAIN-03 for architecture.
@HiveType(typeId: 1)
class RegistroChuva extends HiveObject with FarmOwnedMixin {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime data;

  @HiveField(2)
  final double milimetros;

  @HiveField(3)
  final String? observacao;

  @HiveField(4)
  final DateTime criadoEm;

  /// Property ID (foreign key to Property model in agro_core)
  /// Links this rainfall record to a specific farm/property
  /// NOTE: This also serves as farmId for FarmOwnedEntity
  @HiveField(5)
  final String propertyId;

  /// Talhão ID (foreign key to Talhao model in agro_core)
  /// Optional: Links to a specific field plot/subdivision within the property
  /// If null, the rainfall is registered at property level (whole property)
  @HiveField(6)
  final String? talhaoId;

  // ═══════════════════════════════════════════════════════════════════════════
  // FarmOwnedMixin fields (CORE-77 / RAIN-03)
  // ═══════════════════════════════════════════════════════════════════════════

  /// User who created this record (Firebase Auth UID)
  @override
  @HiveField(7)
  final String createdBy;

  /// App that created this record (always "rurarain", immutable)
  @override
  @HiveField(8)
  final String sourceApp;

  RegistroChuva({
    required this.id,
    required this.data,
    required this.milimetros,
    this.observacao,
    required this.criadoEm,
    required this.propertyId,
    this.talhaoId,
    required this.createdBy,
    this.sourceApp = 'rurarain',
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FarmOwnedMixin implementation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maps propertyId to farmId for FarmOwnedMixin compatibility
  @override
  String get farmId => propertyId;

  /// Maps criadoEm to createdAt for FarmOwnedMixin compatibility
  @override
  DateTime get createdAt => criadoEm;

  /// Factory for creating a new record with auto-filled metadata.
  ///
  /// Usage:
  /// ```dart
  /// final registro = RegistroChuva.create(
  ///   data: DateTime.now(),
  ///   milimetros: 25.5,
  ///   propertyId: propertyService.defaultProperty!.id,
  /// );
  /// ```
  factory RegistroChuva.create({
    required DateTime data,
    required double milimetros,
    String? observacao,
    required String propertyId,
    String? talhaoId,
  }) {
    final agora = DateTime.now();
    return RegistroChuva(
      id: agora.millisecondsSinceEpoch,
      data: data,
      milimetros: milimetros,
      observacao: observacao,
      criadoEm: agora,
      propertyId: propertyId,
      talhaoId: talhaoId,
      createdBy: AuthService.currentUser?.uid ?? '',
      sourceApp: 'rurarain',
    );
  }

  /// Legacy factory for backward compatibility.
  /// @deprecated Use [RegistroChuva.create] instead.
  factory RegistroChuva.novo({
    required DateTime data,
    required double milimetros,
    String? observacao,
    required String propertyId,
    String? talhaoId,
  }) {
    return RegistroChuva.create(
      data: data,
      milimetros: milimetros,
      observacao: observacao,
      propertyId: propertyId,
      talhaoId: talhaoId,
    );
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'milimetros': milimetros,
      'observacao': observacao,
      'criadoEm': criadoEm.toIso8601String(),
      'propertyId': propertyId,
      'talhaoId': talhaoId,
      'createdBy': createdBy,
      'sourceApp': sourceApp,
    };
  }

  /// Create from JSON (backup/import)
  factory RegistroChuva.fromJson(Map<String, dynamic> json) {
    return RegistroChuva(
      id: json['id'] as int,
      data: DateTime.parse(json['data'] as String),
      milimetros: (json['milimetros'] as num).toDouble(),
      observacao: json['observacao'] as String?,
      criadoEm: json['criadoEm'] != null
          ? DateTime.parse(json['criadoEm'] as String)
          : DateTime.now(),
      propertyId: json['propertyId'] as String,
      talhaoId: json['talhaoId'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      sourceApp: json['sourceApp'] as String? ?? 'rurarain',
    );
  }

  /// Legacy method for backward compatibility
  Map<String, dynamic> toMap() => toJson();

  /// Copy with new values (preserves immutable fields)
  RegistroChuva copyWith({
    DateTime? data,
    double? milimetros,
    String? observacao,
    String? talhaoId,
  }) {
    return RegistroChuva(
      id: id,
      data: data ?? this.data,
      milimetros: milimetros ?? this.milimetros,
      observacao: observacao ?? this.observacao,
      criadoEm: criadoEm,
      propertyId: propertyId,
      talhaoId: talhaoId ?? this.talhaoId,
      // Immutable fields preserved
      createdBy: createdBy,
      sourceApp: sourceApp,
    );
  }
}
