import 'package:agro_core/agro_core.dart';
import 'package:hive/hive.dart';

part 'recebivel.g.dart';

/// Receivable model for RuraRubber.
///
/// Tracks amounts to be received from buyers (usinas/bancas) after deliveries.
/// Implements [FarmOwnedEntity] for multi-app/multi-user support.
///
/// See RUBBER-18 for architecture.
@HiveType(typeId: 60)
class Recebivel extends HiveObject implements FarmOwnedEntity {
  @override
  @HiveField(0)
  final String id;

  /// The delivery (entrega) this receivable is linked to.
  @HiveField(1)
  final String entregaId;

  /// Amount to be received (R$).
  @HiveField(2)
  final double valor;

  /// Expected payment date.
  @HiveField(3)
  final DateTime dataPrevista;

  /// Actual date the payment was received (null if still pending).
  @HiveField(4)
  DateTime? dataRecebimento;

  /// Optional buyer name.
  @HiveField(5)
  String? compradorNome;

  /// Whether this receivable has been marked as received.
  @HiveField(6)
  bool recebido;

  // ═══════════════════════════════════════════════════════════════════════════
  // FarmOwnedEntity fields (CORE-77 / RUBBER-18)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  @HiveField(7)
  final String farmId;

  @override
  @HiveField(8)
  final String createdBy;

  @override
  @HiveField(9)
  final DateTime createdAt;

  @override
  @HiveField(10)
  final String sourceApp;

  Recebivel({
    required this.id,
    required this.entregaId,
    required this.valor,
    required this.dataPrevista,
    this.dataRecebimento,
    this.compradorNome,
    this.recebido = false,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    this.sourceApp = 'rurarubber',
  });

  /// Factory for creating a new Recebivel with auto-filled metadata.
  factory Recebivel.create({
    required String id,
    required String entregaId,
    required double valor,
    required DateTime dataPrevista,
    String? compradorNome,
  }) {
    return Recebivel(
      id: id,
      entregaId: entregaId,
      valor: valor,
      dataPrevista: dataPrevista,
      compradorNome: compradorNome,
      farmId: FarmService.instance.defaultFarmId ?? '',
      createdBy: AuthService.currentUser?.uid ?? '',
      createdAt: DateTime.now(),
    );
  }

  /// Convert to JSON for backup/export.
  Map<String, dynamic> toJson() => {
        'id': id,
        'entregaId': entregaId,
        'valor': valor,
        'dataPrevista': dataPrevista.toIso8601String(),
        'dataRecebimento': dataRecebimento?.toIso8601String(),
        'compradorNome': compradorNome,
        'recebido': recebido,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'sourceApp': sourceApp,
      };

  /// Create from JSON (backup/import).
  factory Recebivel.fromJson(Map<String, dynamic> json) => Recebivel(
        id: json['id'] as String,
        entregaId: json['entregaId'] as String,
        valor: (json['valor'] as num).toDouble(),
        dataPrevista: DateTime.parse(json['dataPrevista'] as String),
        dataRecebimento: json['dataRecebimento'] != null
            ? DateTime.parse(json['dataRecebimento'] as String)
            : null,
        compradorNome: json['compradorNome'] as String?,
        recebido: json['recebido'] as bool? ?? false,
        farmId: json['farmId'] as String? ?? '',
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        sourceApp: json['sourceApp'] as String? ?? 'rurarubber',
      );
}
