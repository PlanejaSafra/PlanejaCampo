import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'talhao.g.dart';

/// Talhão (Field Plot/Subdivision)
///
/// Represents a subdivision within a Property, allowing more granular
/// tracking of agricultural data (rainfall, fertilization, etc.)
@HiveType(typeId: 14)
class Talhao extends HiveObject {
  /// Unique identifier (UUID)
  @HiveField(0)
  final String id;

  /// Owner user ID (for multi-user sync)
  @HiveField(1)
  final String userId;

  /// Foreign key to Property
  @HiveField(2)
  final String propertyId;

  /// Talhão name (e.g., "Talhão A - Soja", "Lote 3")
  @HiveField(3)
  String nome;

  /// Area in hectares
  @HiveField(4)
  double area;

  /// Optional: current crop/culture (e.g., "Soja", "Milho", "Café")
  @HiveField(5)
  String? cultura;

  /// Optional: polygon coordinates for map display
  /// Format: List of maps with 'lat' and 'lng' keys
  /// Example: [{'lat': -23.5, 'lng': -46.6}, {'lat': -23.6, 'lng': -46.7}]
  @HiveField(6)
  List<Map<String, double>>? coordenadas;

  /// Creation timestamp
  @HiveField(7)
  final DateTime createdAt;

  /// Last update timestamp
  @HiveField(8)
  DateTime updatedAt;

  Talhao({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.nome,
    required this.area,
    this.cultura,
    this.coordenadas,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor for creating new Talhão
  factory Talhao.create({
    required String userId,
    required String propertyId,
    required String nome,
    required double area,
    String? cultura,
    List<Map<String, double>>? coordenadas,
  }) {
    final now = DateTime.now();
    return Talhao(
      id: const Uuid().v4(),
      userId: userId,
      propertyId: propertyId,
      nome: nome,
      area: area,
      cultura: cultura,
      coordenadas: coordenadas,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update talhão details
  void update({
    String? nome,
    double? area,
    String? cultura,
    List<Map<String, double>>? coordenadas,
  }) {
    if (nome != null) this.nome = nome;
    if (area != null) this.area = area;
    if (cultura != null) this.cultura = cultura;
    if (coordenadas != null) this.coordenadas = coordenadas;
    updatedAt = DateTime.now();
  }

  /// Clear cultura (set to null)
  void clearCultura() {
    cultura = null;
    updatedAt = DateTime.now();
  }

  /// Clear coordinates
  void clearCoordenadas() {
    coordenadas = null;
    updatedAt = DateTime.now();
  }

  /// Display name with area
  /// Example: "Talhão A - Soja (50.0 ha)"
  String get displayName {
    return '$nome (${area.toStringAsFixed(1)} ha)';
  }

  /// Display name with cultura if available
  /// Example: "Talhão A - Soja" or just "Talhão A" if no cultura
  String get displayNameWithCultura {
    if (cultura != null && cultura!.isNotEmpty) {
      return nome;
    }
    return nome;
  }

  @override
  String toString() {
    return 'Talhao(id: $id, nome: $nome, area: $area ha, propertyId: $propertyId)';
  }

  /// Create a copy with updated fields
  Talhao copyWith({
    String? id,
    String? userId,
    String? propertyId,
    String? nome,
    double? area,
    String? cultura,
    List<Map<String, double>>? coordenadas,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Talhao(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      propertyId: propertyId ?? this.propertyId,
      nome: nome ?? this.nome,
      area: area ?? this.area,
      cultura: cultura ?? this.cultura,
      coordenadas: coordenadas ?? this.coordenadas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
