import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:agro_core/agro_core.dart';

part 'centro_custo.g.dart';

/// A cost center for expense allocation.
@HiveType(typeId: 72)
class CentroCusto extends HiveObject implements FarmOwnedEntity {
  @HiveField(0)
  @override
  String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  String? icone;

  @HiveField(3)
  int corValue;

  @HiveField(4)
  String? appVinculado;

  // FarmOwnedEntity fields
  @HiveField(5)
  @override
  String farmId;

  @HiveField(6)
  @override
  String createdBy;

  @HiveField(7)
  @override
  DateTime createdAt;

  @HiveField(8)
  @override
  String sourceApp;

  CentroCusto({
    required this.id,
    required this.nome,
    this.icone,
    this.corValue = 0xFF607D8B,
    this.appVinculado,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    this.sourceApp = 'ruracash',
  });

  /// Color accessor.
  Color get cor => Color(corValue);

  /// Factory constructor with auto-populated metadata.
  factory CentroCusto.create({
    required String nome,
    String? icone,
    int corValue = 0xFF607D8B,
    String? appVinculado,
  }) {
    return CentroCusto(
      id: const Uuid().v4(),
      nome: nome,
      icone: icone,
      corValue: corValue,
      appVinculado: appVinculado,
      farmId: FarmService.instance.defaultFarmId ?? '',
      createdBy: AuthService.currentUser?.uid ?? '',
      createdAt: DateTime.now(),
      sourceApp: 'ruracash',
    );
  }

  /// Serialization for backup.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'icone': icone,
        'corValue': corValue,
        'appVinculado': appVinculado,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'sourceApp': sourceApp,
      };

  /// Deserialization from backup.
  factory CentroCusto.fromJson(Map<String, dynamic> json) => CentroCusto(
        id: json['id'] as String,
        nome: json['nome'] as String,
        icone: json['icone'] as String?,
        corValue: json['corValue'] as int? ?? 0xFF607D8B,
        appVinculado: json['appVinculado'] as String?,
        farmId: json['farmId'] as String? ?? '',
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        sourceApp: json['sourceApp'] as String? ?? 'ruracash',
      );
}
