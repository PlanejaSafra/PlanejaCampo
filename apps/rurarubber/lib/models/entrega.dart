import 'package:agro_core/agro_core.dart';
import 'package:hive/hive.dart';

import 'item_entrega.dart';

part 'entrega.g.dart';

/// Entrega (delivery) model for RuraRubber.
///
/// Implements [FarmOwnedEntity] for multi-app/multi-user support:
/// - [farmId]: Which farm this entrega belongs to
/// - [createdBy]: Who created this record (audit trail)
/// - [createdAt]: When it was created
/// - [sourceApp]: Always "rurarubber" (immutable)
///
/// See CORE-77 and RUBBER-24 for architecture.
@HiveType(typeId: 2)
class Entrega extends HiveObject implements FarmOwnedEntity {
  @override
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime data;

  @HiveField(2)
  String status; // 'Aberto', 'Fechado', 'Pago'

  @HiveField(3)
  double? precoDrc;

  @HiveField(4)
  double? precoUmido;

  @HiveField(5)
  String? compradorId;

  @HiveField(6)
  List<ItemEntrega> itens;

  // ═══════════════════════════════════════════════════════════════════════════
  // FarmOwnedEntity fields (CORE-77 / RUBBER-24)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Farm this entrega belongs to (required for multi-farm support)
  @override
  @HiveField(7)
  final String farmId;

  /// User who created this record (Firebase Auth UID)
  @override
  @HiveField(8)
  final String createdBy;

  /// When this record was created
  @override
  @HiveField(9)
  final DateTime createdAt;

  /// App that created this record (always "rurarubber", immutable)
  @override
  @HiveField(10)
  final String sourceApp;

  Entrega({
    required this.id,
    required this.data,
    this.status = 'Aberto',
    this.precoDrc,
    this.precoUmido,
    this.compradorId,
    this.itens = const [],
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    this.sourceApp = 'rurarubber',
  });

  /// Factory for creating a new Entrega with auto-filled metadata.
  ///
  /// Usage:
  /// ```dart
  /// final entrega = Entrega.create(
  ///   id: uuid.v4(),
  ///   data: DateTime.now(),
  /// );
  /// ```
  factory Entrega.create({
    required String id,
    required DateTime data,
    String status = 'Aberto',
    double? precoDrc,
    double? precoUmido,
    String? compradorId,
    List<ItemEntrega> itens = const [],
  }) {
    return Entrega(
      id: id,
      data: data,
      status: status,
      precoDrc: precoDrc,
      precoUmido: precoUmido,
      compradorId: compradorId,
      itens: itens,
      farmId: FarmService.instance.defaultFarmId ?? '',
      createdBy: AuthService.currentUser?.uid ?? '',
      createdAt: DateTime.now(),
      sourceApp: 'rurarubber',
    );
  }

  double get pesoTotalGeral {
    return itens.fold(0, (sum, item) => sum + item.pesoTotal);
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'status': status,
      'precoDrc': precoDrc,
      'precoUmido': precoUmido,
      'compradorId': compradorId,
      'itens': itens.map((i) => i.toJson()).toList(),
      'farmId': farmId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'sourceApp': sourceApp,
    };
  }

  /// Create from JSON (backup/import)
  factory Entrega.fromJson(Map<String, dynamic> json) {
    return Entrega(
      id: json['id'] as String,
      data: DateTime.parse(json['data'] as String),
      status: json['status'] as String? ?? 'Aberto',
      precoDrc: (json['precoDrc'] as num?)?.toDouble(),
      precoUmido: (json['precoUmido'] as num?)?.toDouble(),
      compradorId: json['compradorId'] as String?,
      itens: (json['itens'] as List<dynamic>?)
              ?.map((e) => ItemEntrega.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      farmId: json['farmId'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      sourceApp: json['sourceApp'] as String? ?? 'rurarubber',
    );
  }

  /// Copy with new values (preserves immutable fields)
  Entrega copyWith({
    DateTime? data,
    String? status,
    double? precoDrc,
    double? precoUmido,
    String? compradorId,
    List<ItemEntrega>? itens,
  }) {
    return Entrega(
      id: id,
      data: data ?? this.data,
      status: status ?? this.status,
      precoDrc: precoDrc ?? this.precoDrc,
      precoUmido: precoUmido ?? this.precoUmido,
      compradorId: compradorId ?? this.compradorId,
      itens: itens ?? this.itens,
      // Immutable fields preserved
      farmId: farmId,
      createdBy: createdBy,
      createdAt: createdAt,
      sourceApp: sourceApp,
    );
  }
}
