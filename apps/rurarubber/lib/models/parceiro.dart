import 'package:agro_core/agro_core.dart';
import 'package:hive/hive.dart';

part 'parceiro.g.dart';

/// Parceiro (sangrador/fornecedor) model for RuraRubber.
///
/// Implements [FarmOwnedEntity] for multi-app/multi-user support:
/// - [farmId]: Which farm this parceiro belongs to
/// - [createdBy]: Who created this record (audit trail)
/// - [createdAt]: When it was created
/// - [sourceApp]: Always "rurarubber" (immutable)
///
/// See CORE-77 and RUBBER-24 for architecture.
@HiveType(typeId: 0)
class Parceiro extends HiveObject implements FarmOwnedEntity {
  @override
  @HiveField(0)
  final String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  double percentualPadrao;

  @HiveField(3)
  String? telefone;

  @HiveField(4)
  List<String> tarefasIds;

  @HiveField(5)
  String? fotoPath;

  // ═══════════════════════════════════════════════════════════════════════════
  // FarmOwnedEntity fields (CORE-77 / RUBBER-24)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Farm this parceiro belongs to (required for multi-farm support)
  @override
  @HiveField(6)
  final String farmId;

  /// User who created this record (Firebase Auth UID)
  @override
  @HiveField(7)
  final String createdBy;

  /// When this record was created
  @override
  @HiveField(8)
  final DateTime createdAt;

  /// App that created this record (always "rurarubber", immutable)
  @override
  @HiveField(9)
  final String sourceApp;

  Parceiro({
    required this.id,
    required this.nome,
    required this.percentualPadrao,
    this.telefone,
    this.tarefasIds = const [],
    this.fotoPath,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    this.sourceApp = 'rurarubber',
  });

  /// Factory for creating a new Parceiro with auto-filled metadata.
  ///
  /// Usage:
  /// ```dart
  /// final parceiro = Parceiro.create(
  ///   id: uuid.v4(),
  ///   nome: 'João Silva',
  ///   percentualPadrao: 50.0,
  /// );
  /// ```
  factory Parceiro.create({
    required String id,
    required String nome,
    required double percentualPadrao,
    String? telefone,
    List<String> tarefasIds = const [],
    String? fotoPath,
  }) {
    return Parceiro(
      id: id,
      nome: nome,
      percentualPadrao: percentualPadrao,
      telefone: telefone,
      tarefasIds: tarefasIds,
      fotoPath: fotoPath,
      farmId: FarmService.instance.defaultFarmId ?? '',
      createdBy: AuthService.currentUser?.uid ?? '',
      createdAt: DateTime.now(),
      sourceApp: 'rurarubber',
    );
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'percentualPadrao': percentualPadrao,
      'telefone': telefone,
      'tarefasIds': tarefasIds,
      'fotoPath': fotoPath,
      'farmId': farmId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'sourceApp': sourceApp,
    };
  }

  /// Create from JSON (backup/import)
  factory Parceiro.fromJson(Map<String, dynamic> json) {
    return Parceiro(
      id: json['id'] as String,
      nome: json['nome'] as String,
      percentualPadrao: (json['percentualPadrao'] as num).toDouble(),
      telefone: json['telefone'] as String?,
      tarefasIds: (json['tarefasIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      fotoPath: json['fotoPath'] as String?,
      farmId: json['farmId'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      sourceApp: json['sourceApp'] as String? ?? 'rurarubber',
    );
  }

  /// Copy with new values (preserves immutable fields)
  Parceiro copyWith({
    String? nome,
    double? percentualPadrao,
    String? telefone,
    List<String>? tarefasIds,
    String? fotoPath,
  }) {
    return Parceiro(
      id: id,
      nome: nome ?? this.nome,
      percentualPadrao: percentualPadrao ?? this.percentualPadrao,
      telefone: telefone ?? this.telefone,
      tarefasIds: tarefasIds ?? this.tarefasIds,
      fotoPath: fotoPath ?? this.fotoPath,
      // Immutable fields preserved
      farmId: farmId,
      createdBy: createdBy,
      createdAt: createdAt,
      sourceApp: sourceApp,
    );
  }
}
