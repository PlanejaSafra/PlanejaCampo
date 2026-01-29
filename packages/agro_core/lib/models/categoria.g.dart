// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categoria.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoriaAdapter extends TypeAdapter<Categoria> {
  @override
  final int typeId = 78;

  @override
  Categoria read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Categoria(
      id: fields[0] as String,
      nome: fields[1] as String,
      icone: fields[2] as String,
      corValue: fields[3] as int,
      isReceita: fields[4] as bool,
      isCore: fields[5] as bool,
      coreKey: fields[6] as String?,
      isAgro: fields[7] as bool,
      isPersonal: fields[8] as bool,
      isAtiva: fields[9] as bool,
      ordem: fields[10] as int,
      parentId: fields[11] as String?,
      farmId: fields[12] as String,
      createdBy: fields[13] as String,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
      sourceApp: fields[16] as String,
      deleted: fields[17] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Categoria obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.icone)
      ..writeByte(3)
      ..write(obj.corValue)
      ..writeByte(4)
      ..write(obj.isReceita)
      ..writeByte(5)
      ..write(obj.isCore)
      ..writeByte(6)
      ..write(obj.coreKey)
      ..writeByte(7)
      ..write(obj.isAgro)
      ..writeByte(8)
      ..write(obj.isPersonal)
      ..writeByte(9)
      ..write(obj.isAtiva)
      ..writeByte(10)
      ..write(obj.ordem)
      ..writeByte(11)
      ..write(obj.parentId)
      ..writeByte(12)
      ..write(obj.farmId)
      ..writeByte(13)
      ..write(obj.createdBy)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.sourceApp)
      ..writeByte(17)
      ..write(obj.deleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoriaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
