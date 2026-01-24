// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'talhao.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TalhaoAdapter extends TypeAdapter<Talhao> {
  @override
  final int typeId = 14;

  @override
  Talhao read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Talhao(
      id: fields[0] as String,
      userId: fields[1] as String,
      propertyId: fields[2] as String,
      nome: fields[3] as String,
      area: fields[4] as double,
      cultura: fields[5] as String?,
      coordenadas: (fields[6] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, double>())
          ?.toList(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Talhao obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.propertyId)
      ..writeByte(3)
      ..write(obj.nome)
      ..writeByte(4)
      ..write(obj.area)
      ..writeByte(5)
      ..write(obj.cultura)
      ..writeByte(6)
      ..write(obj.coordenadas)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TalhaoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
