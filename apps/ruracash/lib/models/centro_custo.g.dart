// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'centro_custo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CentroCustoAdapter extends TypeAdapter<CentroCusto> {
  @override
  final int typeId = 72;

  @override
  CentroCusto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CentroCusto(
      id: fields[0] as String,
      nome: fields[1] as String,
      icone: fields[2] as String?,
      corValue: fields[3] as int,
      appVinculado: fields[4] as String?,
      farmId: fields[5] as String,
      createdBy: fields[6] as String,
      createdAt: fields[7] as DateTime,
      sourceApp: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CentroCusto obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.icone)
      ..writeByte(3)
      ..write(obj.corValue)
      ..writeByte(4)
      ..write(obj.appVinculado)
      ..writeByte(5)
      ..write(obj.farmId)
      ..writeByte(6)
      ..write(obj.createdBy)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.sourceApp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CentroCustoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
