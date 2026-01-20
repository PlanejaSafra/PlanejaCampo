import 'package:hive/hive.dart';
import '../models/talhao.dart';
import '../models/property.dart';

/// Service for managing Talhão (Field Plot) operations
///
/// Provides CRUD operations and business logic for field plots,
/// including validation and property-talhão relationship management
class TalhaoService {
  static const String _boxName = 'talhoes';
  Box<Talhao>? _box;

  // Singleton pattern
  static final TalhaoService _instance = TalhaoService._internal();
  factory TalhaoService() => _instance;
  TalhaoService._internal();

  /// Initialize Hive box for talhões
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Talhao>(_boxName);
    } else {
      _box = Hive.box<Talhao>(_boxName);
    }
  }

  /// Get the box (ensures it's open)
  Box<Talhao> get _getBox {
    if (_box == null || !_box!.isOpen) {
      throw Exception('TalhaoService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Create a new talhão
  ///
  /// Validates:
  /// - Name is not empty and within length limits
  /// - Area is positive
  /// - Name is unique within the property
  /// - Total area doesn't exceed property area
  ///
  /// Throws [ArgumentError] if validation fails
  Future<Talhao> create({
    required String userId,
    required String propertyId,
    required String nome,
    required double area,
    String? cultura,
    List<Map<String, double>>? coordenadas,
    Property? property,
  }) async {
    // Validate name
    if (nome.trim().isEmpty) {
      throw ArgumentError('Nome do talhão não pode ser vazio');
    }
    if (nome.trim().length < 2) {
      throw ArgumentError('Nome muito curto (mínimo 2 caracteres)');
    }
    if (nome.trim().length > 50) {
      throw ArgumentError('Nome muito longo (máximo 50 caracteres)');
    }

    // Validate area
    if (area <= 0) {
      throw ArgumentError('Área deve ser maior que zero');
    }

    // Check for duplicate names in the same property
    final existingWithSameName = listByProperty(propertyId)
        .where((t) => t.nome.trim().toLowerCase() == nome.trim().toLowerCase())
        .toList();
    if (existingWithSameName.isNotEmpty) {
      throw ArgumentError(
          'Já existe um talhão com este nome nesta propriedade');
    }

    // Validate total area doesn't exceed property area
    if (property != null && property.totalArea != null) {
      final currentTotalArea = getTotalAreaByProperty(propertyId);
      final newTotalArea = currentTotalArea + area;
      if (newTotalArea > property.totalArea!) {
        throw ArgumentError(
          'A soma das áreas dos talhões (${newTotalArea.toStringAsFixed(1)} ha) '
          'excede a área total da propriedade (${property.totalArea!.toStringAsFixed(1)} ha)',
        );
      }
    }

    final talhao = Talhao.create(
      userId: userId,
      propertyId: propertyId,
      nome: nome.trim(),
      area: area,
      cultura: cultura?.trim(),
      coordenadas: coordenadas,
    );

    await _getBox.put(talhao.id, talhao);
    return talhao;
  }

  /// Update an existing talhão
  ///
  /// Validates same rules as create
  /// Throws [ArgumentError] if validation fails or talhão not found
  Future<void> update({
    required String id,
    String? nome,
    double? area,
    String? cultura,
    List<Map<String, double>>? coordenadas,
    Property? property,
  }) async {
    final talhao = getById(id);
    if (talhao == null) {
      throw ArgumentError('Talhão não encontrado');
    }

    // Validate name if provided
    if (nome != null) {
      if (nome.trim().isEmpty) {
        throw ArgumentError('Nome do talhão não pode ser vazio');
      }
      if (nome.trim().length < 2) {
        throw ArgumentError('Nome muito curto (mínimo 2 caracteres)');
      }
      if (nome.trim().length > 50) {
        throw ArgumentError('Nome muito longo (máximo 50 caracteres)');
      }

      // Check for duplicate names (excluding current talhão)
      final existingWithSameName = listByProperty(talhao.propertyId)
          .where((t) =>
              t.id != id &&
              t.nome.trim().toLowerCase() == nome.trim().toLowerCase())
          .toList();
      if (existingWithSameName.isNotEmpty) {
        throw ArgumentError(
            'Já existe um talhão com este nome nesta propriedade');
      }
    }

    // Validate area if provided
    if (area != null) {
      if (area <= 0) {
        throw ArgumentError('Área deve ser maior que zero');
      }

      // Validate total area doesn't exceed property area
      if (property != null && property.totalArea != null) {
        final currentTotalArea = getTotalAreaByProperty(talhao.propertyId);
        final newTotalArea = currentTotalArea - talhao.area + area;
        if (newTotalArea > property.totalArea!) {
          throw ArgumentError(
            'A soma das áreas dos talhões (${newTotalArea.toStringAsFixed(1)} ha) '
            'excede a área total da propriedade (${property.totalArea!.toStringAsFixed(1)} ha)',
          );
        }
      }
    }

    talhao.update(
      nome: nome?.trim(),
      area: area,
      cultura: cultura?.trim(),
      coordenadas: coordenadas,
    );

    await talhao.save();
  }

  /// Delete a talhão
  ///
  /// Note: Caller should handle reassigning records linked to this talhão
  /// Returns true if deleted, false if not found
  Future<bool> delete(String id) async {
    final talhao = getById(id);
    if (talhao == null) return false;

    await talhao.delete();
    return true;
  }

  /// Get a talhão by ID
  Talhao? getById(String id) {
    return _getBox.get(id);
  }

  /// List all talhões for a specific property
  List<Talhao> listByProperty(String propertyId) {
    return _getBox.values.where((t) => t.propertyId == propertyId).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  /// List all talhões for a specific user
  List<Talhao> listByUser(String userId) {
    return _getBox.values.where((t) => t.userId == userId).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  /// Get total area of all talhões in a property
  double getTotalAreaByProperty(String propertyId) {
    return listByProperty(propertyId).fold(0.0, (sum, t) => sum + t.area);
  }

  /// Get count of talhões in a property
  int countByProperty(String propertyId) {
    return listByProperty(propertyId).length;
  }

  /// Check if a property has any talhões
  bool propertyHasTalhoes(String propertyId) {
    return countByProperty(propertyId) > 0;
  }

  /// Delete all talhões for a property
  ///
  /// Used when deleting a property
  /// Returns count of deleted talhões
  Future<int> deleteByProperty(String propertyId) async {
    final talhoes = listByProperty(propertyId);
    for (final talhao in talhoes) {
      await talhao.delete();
    }
    return talhoes.length;
  }

  /// Get talhões with a specific cultura
  List<Talhao> getByCultura(String propertyId, String cultura) {
    return listByProperty(propertyId)
        .where((t) =>
            t.cultura != null &&
            t.cultura!.trim().toLowerCase() == cultura.trim().toLowerCase())
        .toList();
  }

  /// Clear cultura for a talhão
  Future<void> clearCultura(String id) async {
    final talhao = getById(id);
    if (talhao != null) {
      talhao.clearCultura();
      await talhao.save();
    }
  }

  /// Clear coordenadas for a talhão
  Future<void> clearCoordenadas(String id) async {
    final talhao = getById(id);
    if (talhao != null) {
      talhao.clearCoordenadas();
      await talhao.save();
    }
  }

  /// Get all unique culturas in a property
  List<String> getUniqueCulturas(String propertyId) {
    final culturas = <String>{};
    for (final talhao in listByProperty(propertyId)) {
      if (talhao.cultura != null && talhao.cultura!.trim().isNotEmpty) {
        culturas.add(talhao.cultura!.trim());
      }
    }
    return culturas.toList()..sort();
  }

  /// Close the box
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
