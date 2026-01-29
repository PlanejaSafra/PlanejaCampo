import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'farm_owned_mixin.dart';
import '../services/sync/sync_models.dart';

part 'categoria.g.dart';

/// Modelo de Categoria unificado para o ecossistema RuraCamp.
/// Substitui os enums hardcoded (CashCategoria) dos apps.
@HiveType(typeId: 78)
class Categoria extends HiveObject with FarmOwnedMixin implements SyncableEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  final String nome;

  @HiveField(2)
  final String icone; // Nome do ícone Material

  @HiveField(3)
  final int corValue; // Color.value

  @HiveField(4)
  final bool isReceita;

  /// Se é uma categoria do sistema (protegida)
  @HiveField(5)
  final bool isCore;

  /// Chave identificadora para categorias do sistema (ex: 'combustivel')
  /// Imutável e único por farm. Null para categorias custom.
  @HiveField(6)
  final String? coreKey;

  @HiveField(7)
  final bool isAgro;

  @HiveField(8)
  final bool isPersonal;

  /// Soft-delete: se false, não aparece nas listas de seleção
  @HiveField(9)
  final bool isAtiva;

  @HiveField(10)
  final int ordem;

  /// Para subcategorias (Premium layout)
  @HiveField(11)
  final String? parentId;

  // FarmOwnedEntity fields
  @HiveField(12)
  @override
  final String farmId;

  // SyncableEntity fields
  @HiveField(13)
  @override
  final String createdBy;

  @HiveField(14)
  @override
  final DateTime createdAt;

  @HiveField(15)
  @override
  DateTime updatedAt;

  @HiveField(16)
  @override
  final String sourceApp;

  @HiveField(17)
  @override
  bool? deleted; // For SyncableEntity generic logic

  Categoria({
    required this.id,
    required this.nome,
    required this.icone,
    required this.corValue,
    required this.isReceita,
    required this.isCore,
    this.coreKey,
    required this.isAgro,
    required this.isPersonal,
    required this.isAtiva,
    required this.ordem,
    this.parentId,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceApp,
    this.deleted = false,
  });

  /// Helper para obter a cor
  Color get cor => Color(corValue);

  /// Helper para obter ícone (mapeamento deve ser feito na UI ou via IconMap helper)
  /// Aqui retornamos o IconData via reflection simples seria ideal, mas no Flutter
  /// geralmente usamos um Map<String, IconData>.
  /// O Service/Utils deve prover esse mapa.

  // Factory para categorias custom
  factory Categoria.custom({
    required String nome,
    required String icone,
    required int corValue,
    required bool isReceita,
    required bool isAgro,
    required bool isPersonal,
    required String farmId,
    required String userId,
    String? parentId,
  }) {
    final now = DateTime.now();
    return Categoria(
      id: const Uuid().v4(),
      nome: nome,
      icone: icone,
      corValue: corValue,
      isReceita: isReceita,
      isCore: false,
      coreKey: null,
      isAgro: isAgro,
      isPersonal: isPersonal,
      isAtiva: true,
      ordem: 99, // Fim da lista por default
      parentId: parentId,
      farmId: farmId,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
      sourceApp: 'agro_core', // ou passar app específico
    );
  }

  // Factory para categorias core (sistema)
  factory Categoria.core({
    required String coreKey,
    required String nome,
    required String icone,
    required int corValue,
    required bool isReceita,
    required bool isAgro,
    required bool isPersonal,
    required String farmId,
    required String userId, // Geralmente 'system' ou o owner da farm
  }) {
    final now = DateTime.now();
    return Categoria(
      id: const Uuid().v4(),
      nome: nome,
      icone: icone,
      corValue: corValue,
      isReceita: isReceita,
      isCore: true,
      coreKey: coreKey,
      isAgro: isAgro,
      isPersonal: isPersonal,
      isAtiva: true,
      ordem: 0, // Início da lista
      farmId: farmId,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
      sourceApp: 'agro_core',
    );
  }

  @override
  Map<String, dynamic> toMap() => toJson();

  /// Serialization for GenericSyncService / backup.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'icone': icone,
        'corValue': corValue,
        'isReceita': isReceita,
        'isCore': isCore,
        'coreKey': coreKey,
        'isAgro': isAgro,
        'isPersonal': isPersonal,
        'isAtiva': isAtiva,
        'ordem': ordem,
        'parentId': parentId,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'sourceApp': sourceApp,
        'deleted': deleted,
      };

  /// Deserialization from GenericSyncService / backup.
  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'] as String,
        nome: json['nome'] as String,
        icone: json['icone'] as String,
        corValue: json['corValue'] as int,
        isReceita: json['isReceita'] as bool? ?? false,
        isCore: json['isCore'] as bool? ?? false,
        coreKey: json['coreKey'] as String?,
        isAgro: json['isAgro'] as bool? ?? true,
        isPersonal: json['isPersonal'] as bool? ?? false,
        isAtiva: json['isAtiva'] as bool? ?? true,
        ordem: json['ordem'] as int? ?? 99,
        parentId: json['parentId'] as String?,
        farmId: json['farmId'] as String? ?? '',
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        sourceApp: json['sourceApp'] as String? ?? 'agro_core',
        deleted: json['deleted'] as bool? ?? false,
      );

  Categoria copyWith({
    String? nome,
    String? icone,
    int? corValue,
    bool? isAgro,
    bool? isPersonal,
    bool? isAtiva,
    int? ordem,
    String? parentId,
    DateTime? updatedAt,
  }) {
    return Categoria(
      id: id,
      nome: nome ?? this.nome,
      icone: icone ?? this.icone,
      corValue: corValue ?? this.corValue,
      isReceita: isReceita, // Imutável em updates simples
      isCore: isCore,       // Imutável
      coreKey: coreKey,     // Imutável
      isAgro: isAgro ?? this.isAgro,
      isPersonal: isPersonal ?? this.isPersonal,
      isAtiva: isAtiva ?? this.isAtiva,
      ordem: ordem ?? this.ordem,
      parentId: parentId ?? this.parentId,
      farmId: farmId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sourceApp: sourceApp,
      deleted: deleted,
    );
  }
}
