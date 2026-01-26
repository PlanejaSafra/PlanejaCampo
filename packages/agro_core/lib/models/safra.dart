import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'safra.g.dart';

/// Global Crop Season (Safra) model — Agricultural Year.
///
/// Represents an agricultural year spanning September → August.
/// All apps in the RuraCamp ecosystem share this concept:
/// - RuraRubber: Rubber weighings per season
/// - RuraRain: Rainfall per season
/// - RuraCrop: Crop cycles within a season
/// - RuraCash: Financial reports per season
///
/// ## Key Principles
///
/// - Safra is a TIME WINDOW, not a data container
/// - Totals are CALCULATED via query, NEVER stored
/// - Each farm has its own set of safras
/// - Only ONE safra can be active per farm at a time
///
/// ## Example
/// ```
/// Safra 2025/2026
/// ├── dataInicio: 2025-09-01
/// ├── dataFim: 2026-08-31 (or null if active)
/// ├── ativa: true
/// └── nome: "Safra 2025/2026"
/// ```
///
/// See CORE-76 for architecture details.
@HiveType(typeId: 21)
class Safra extends HiveObject {
  /// Unique identifier (UUID-based: "safra-{uuid}")
  @HiveField(0)
  final String id;

  /// Farm that owns this safra (references Farm.id)
  @HiveField(1)
  final String farmId;

  /// Display name (e.g., "Safra 2025/2026")
  @HiveField(2)
  final String nome;

  /// Start date of the agricultural year (typically September 1st)
  @HiveField(3)
  final DateTime dataInicio;

  /// End date (null = active/open, typically August 31st when closed)
  @HiveField(4)
  DateTime? dataFim;

  /// Whether this is the current active safra for the farm.
  /// Only one safra per farm should be active at a time.
  @HiveField(5)
  bool ativa;

  /// When this safra record was created
  @HiveField(6)
  final DateTime createdAt;

  Safra({
    required this.id,
    required this.farmId,
    required this.nome,
    required this.dataInicio,
    this.dataFim,
    this.ativa = false,
    required this.createdAt,
  });

  /// Factory for creating a new safra with auto-generated UUID.
  ///
  /// Usage:
  /// ```dart
  /// final safra = Safra.create(
  ///   farmId: currentFarmId,
  ///   nome: 'Safra 2025/2026',
  ///   dataInicio: DateTime(2025, 9, 1),
  /// );
  /// ```
  factory Safra.create({
    required String farmId,
    required String nome,
    required DateTime dataInicio,
    DateTime? dataFim,
    bool ativa = true,
  }) {
    final uuid = const Uuid().v4();
    return Safra(
      id: 'safra-$uuid',
      farmId: farmId,
      nome: nome,
      dataInicio: dataInicio,
      dataFim: dataFim,
      ativa: ativa,
      createdAt: DateTime.now(),
    );
  }

  /// Short label for chips and headers (e.g., "25/26").
  ///
  /// Uses the last two digits of start and end years.
  String get shortLabel {
    final y1 = dataInicio.year % 100;
    final y2 = (dataInicio.year + 1) % 100;
    return '${y1.toString().padLeft(2, '0')}/${y2.toString().padLeft(2, '0')}';
  }

  /// Start year of this agricultural season
  int get startYear => dataInicio.year;

  /// End year of this agricultural season (start year + 1)
  int get endYear => dataInicio.year + 1;

  /// Check if a given date falls within this safra's time period.
  ///
  /// For active safras (dataFim == null), any date after dataInicio is valid.
  bool containsDate(DateTime date) {
    if (date.isBefore(dataInicio)) return false;
    if (dataFim != null && date.isAfter(dataFim!)) return false;
    return true;
  }

  /// Close this safra by setting dataFim and deactivating.
  ///
  /// [dataEncerramento] defaults to August 31st 23:59:59 of the end year.
  void encerrar({DateTime? dataEncerramento}) {
    dataFim = dataEncerramento ??
        DateTime(dataInicio.year + 1, 8, 31, 23, 59, 59);
    ativa = false;
  }

  /// Convert to JSON Map for backup/export.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'nome': nome,
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim?.toIso8601String(),
      'ativa': ativa,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON Map (backup/import).
  factory Safra.fromJson(Map<String, dynamic> json) {
    return Safra(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      nome: json['nome'] as String,
      dataInicio: DateTime.parse(json['dataInicio'] as String),
      dataFim: json['dataFim'] != null
          ? DateTime.parse(json['dataFim'] as String)
          : null,
      ativa: json['ativa'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Determine the agricultural start year for a given date.
  ///
  /// The agricultural year starts in September:
  /// - Sep-Dec → current year is the start year
  /// - Jan-Aug → previous year is the start year
  ///
  /// Example:
  /// - October 2025 → 2025 (season 2025/2026)
  /// - March 2026 → 2025 (season 2025/2026)
  static int agriculturalStartYear([DateTime? date]) {
    final d = date ?? DateTime.now();
    return d.month >= 9 ? d.year : d.year - 1;
  }

  /// Generate the default safra name for a given start year.
  ///
  /// Example: `generateName(2025)` → `"Safra 2025/2026"`
  static String generateName(int startYear) {
    return 'Safra $startYear/${startYear + 1}';
  }

  @override
  String toString() => 'Safra($id, $nome, ativa: $ativa)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Safra && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
