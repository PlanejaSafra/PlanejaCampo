import 'package:agro_core/agro_core.dart';
import 'package:hive/hive.dart';

part 'despesa.g.dart';

/// Expense category enum for break-even cost analysis.
///
/// Covers the main cost drivers in rubber production:
/// - Labor (sangradores, diaristas)
/// - Fertilizers
/// - Pesticides
/// - Fuel/Diesel
/// - Equipment maintenance
/// - Other
///
/// See RUBBER-20 for architecture.
@HiveType(typeId: 63)
enum CategoriaDespesa {
  @HiveField(0)
  maoDeObra,
  @HiveField(1)
  adubo,
  @HiveField(2)
  defensivos,
  @HiveField(3)
  combustivel,
  @HiveField(4)
  manutencao,
  @HiveField(5)
  outros,
}

/// Expense (Despesa) model for RuraRubber break-even analysis.
///
/// Implements [FarmOwnedEntity] for multi-app/multi-user support:
/// - [farmId]: Which farm this expense belongs to
/// - [createdBy]: Who created this record (audit trail)
/// - [createdAt]: When it was created
/// - [sourceApp]: Always "rurarubber" (immutable)
///
/// See RUBBER-20 for architecture.
@HiveType(typeId: 64)
class Despesa extends HiveObject implements FarmOwnedEntity {
  @override
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double valor;

  @HiveField(2)
  final CategoriaDespesa categoria;

  @HiveField(3)
  final DateTime data;

  @HiveField(4)
  String? descricao;

  @override
  @HiveField(5)
  final String farmId;

  @override
  @HiveField(6)
  final String createdBy;

  @override
  @HiveField(7)
  final DateTime createdAt;

  @override
  @HiveField(8)
  final String sourceApp;

  Despesa({
    required this.id,
    required this.valor,
    required this.categoria,
    required this.data,
    this.descricao,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    this.sourceApp = 'rurarubber',
  });

  /// Factory for creating a new Despesa with auto-filled metadata.
  ///
  /// Usage:
  /// ```dart
  /// final despesa = Despesa.create(
  ///   id: uuid.v4(),
  ///   valor: 1500.00,
  ///   categoria: CategoriaDespesa.maoDeObra,
  ///   data: DateTime.now(),
  /// );
  /// ```
  factory Despesa.create({
    required String id,
    required double valor,
    required CategoriaDespesa categoria,
    required DateTime data,
    String? descricao,
  }) {
    return Despesa(
      id: id,
      valor: valor,
      categoria: categoria,
      data: data,
      descricao: descricao,
      farmId: FarmService.instance.defaultFarmId ?? '',
      createdBy: AuthService.currentUser?.uid ?? '',
      createdAt: DateTime.now(),
    );
  }

  /// Convert to JSON for backup/export.
  Map<String, dynamic> toJson() => {
        'id': id,
        'valor': valor,
        'categoria': categoria.index,
        'data': data.toIso8601String(),
        'descricao': descricao,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'sourceApp': sourceApp,
      };

  /// Create from JSON (backup/import).
  factory Despesa.fromJson(Map<String, dynamic> json) => Despesa(
        id: json['id'] as String,
        valor: (json['valor'] as num).toDouble(),
        categoria: CategoriaDespesa.values[json['categoria'] as int],
        data: DateTime.parse(json['data'] as String),
        descricao: json['descricao'] as String?,
        farmId: json['farmId'] as String? ?? '',
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        sourceApp: json['sourceApp'] as String? ?? 'rurarubber',
      );
}
